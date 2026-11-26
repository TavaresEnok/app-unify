'use strict';
// Canonical IXC Provedor gateway. Copies are checked by scripts/check-contracts.mjs.
//
// O app e o backend falam o "contrato SGP" (URA/Central/FTTX). Este gateway
// traduz cada rota SGP usada em chamadas ao webservice IXC (`/webservice/v1/<tabela>`)
// e devolve exatamente o formato que o código SGP já consome. Assim login,
// faturas, consumo, ONU, desbloqueio e sincronização funcionam para IXC sem
// alterar o app Flutter.
//
// `call(table, body, action)` é injetado pelo consumidor (transporte com SSRF
// guard + cabeçalhos Authorization/ixcsoft) e devolve o JSON já decodificado.

const MAX_PAGES = 5;
const ID_CHUNK = 100;
// PIX copia e cola: o IXC não grava o EMV em fn_areceber; vem de /get_pix.
// Limitado às próximas faturas em aberto para não multiplicar chamadas.
const MAX_PIX_LOOKUPS = 6;
// Consultas de PIX em paralelo (o IXC aceita; sequencial deixava a tela lenta).
const PIX_CONCURRENCY = 3;
// Janela de faturas usada para descobrir o dia de vencimento na sincronização.
const DUE_WINDOW_DAYS = 40;
// O SGP exige senha da central; no IXC o acesso é pelo token do provedor.
// Marcador não secreto só para o código SGP considerar o contrato "consultável".
const CENTRAL_MARKER = 'ixc';
// Boleto em PDF (get_boleto, base64): teto do arquivo decodificado.
const MAX_BOLETO_BYTES = 5 * 1024 * 1024;
const MAX_BOLETO_BASE64 = Math.ceil(MAX_BOLETO_BYTES / 3) * 4 + 4096;

const CONTRACT_STATUS = { A: 'Ativo', P: 'Pré-contrato', I: 'Inativo', N: 'Negativado', D: 'Cancelado' };
const INTERNET_STATUS = {
    AA: 'Aguardando assinatura',
    CM: 'Bloqueio manual',
    CA: 'Bloqueio automático',
    FA: 'Suspenso por atraso financeiro',
    D: 'Desativado',
};

function digits(value) { return String(value ?? '').replace(/\D/g, ''); }

function formatCpfCnpj(value) {
    const d = digits(value);
    if (d.length === 11) return `${d.slice(0, 3)}.${d.slice(3, 6)}.${d.slice(6, 9)}-${d.slice(9)}`;
    if (d.length === 14) return `${d.slice(0, 2)}.${d.slice(2, 5)}.${d.slice(5, 8)}/${d.slice(8, 12)}-${d.slice(12)}`;
    return d;
}

/** IXC mistura `YYYY-MM-DD[ HH:mm:ss]` e `DD/MM/YYYY[ HH:mm:ss]`; zero-dates viram null. */
function ixcDate(value) {
    const text = String(value ?? '').trim();
    if (!text || text.startsWith('0000') || text.startsWith('00/00')) return null;
    let match = text.match(/^(\d{2})\/(\d{2})\/(\d{4})(?:[ T](\d{2}:\d{2}:\d{2}))?$/);
    if (match) return `${match[3]}-${match[2]}-${match[1]}${match[4] ? `T${match[4]}` : ''}`;
    match = text.match(/^(\d{4}-\d{2}-\d{2})(?:[ T](\d{2}:\d{2}:\d{2}))?$/);
    if (match) return `${match[1]}${match[2] ? `T${match[2]}` : ''}`;
    return null;
}

function number(value) {
    if (value === null || value === undefined || value === '') return null;
    const parsed = Number(String(value).replace(',', '.'));
    return Number.isFinite(parsed) ? parsed : null;
}

function contractStatusLabel(contract) {
    const status = String(contract.status || '').toUpperCase();
    const internet = String(contract.status_internet || '').toUpperCase();
    if (status === 'I') return CONTRACT_STATUS.I;
    if (status === 'D') return CONTRACT_STATUS.D;
    if (internet && internet !== 'A' && INTERNET_STATUS[internet]) return INTERNET_STATUS[internet];
    return CONTRACT_STATUS[status] || CONTRACT_STATUS.A;
}

function unsupported(message) { return Object.assign(new Error(message), { status: 501 }); }
function ixcError(message) { return Object.assign(new Error(`IXC: ${String(message || 'erro desconhecido').slice(0, 200)}`), { status: 502 }); }
function boletoUnavailable(message = 'Boleto não disponível para esta fatura.', code = 'boleto-unavailable') {
    return Object.assign(new Error(message), { status: 404, code, publicMessage: message });
}
/** Mensagem de erro do IXC (JSON puro ou JSON/texto dentro de uma página HTML). */
function ixcErrorText(data) {
    if (data && typeof data === 'object') return data.type === 'error' ? String(data.message || '') : '';
    const text = String(data || '');
    const json = text.match(/\{"type"\s*:\s*"error"\s*,\s*"message"\s*:\s*"((?:[^"\\]|\\.)*)"/);
    if (json) { try { return JSON.parse(`"${json[1]}"`); } catch { return json[1]; } }
    if (/^\s*</.test(text)) return text.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim() || 'resposta HTML';
    return '';
}
/** Decodifica o base64 do get_boleto e só aceita um PDF de verdade. */
function decodeBoletoPdf(data) {
    let text = typeof data === 'string' ? data : typeof data?.base64 === 'string' ? data.base64 : typeof data?.arquivo === 'string' ? data.arquivo : null;
    if (text === null) throw ixcError('get_boleto sem arquivo');
    text = text.trim().replace(/^data:application\/pdf;base64,/i, '').replace(/\s+/g, '');
    if (text.length > MAX_BOLETO_BASE64) throw Object.assign(new Error('Boleto maior que o permitido.'), { status: 502 });
    if (!text || !/^[A-Za-z0-9+/]+={0,2}$/.test(text)) throw ixcError('get_boleto não retornou PDF');
    const pdf = Buffer.from(text, 'base64');
    if (pdf.length > MAX_BOLETO_BYTES) throw Object.assign(new Error('Boleto maior que o permitido.'), { status: 502 });
    if (pdf.length < 8 || pdf.subarray(0, 5).toString('latin1') !== '%PDF-') throw ixcError('get_boleto não retornou PDF');
    return pdf;
}

function chunks(items, size) {
    const out = [];
    for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
    return out;
}
const unique = items => [...new Set(items.filter(item => item !== undefined && item !== null && item !== '').map(String))];
// IXC grava "0" (ou vazio) quando o campo de referência não foi preenchido.
const present = value => value !== undefined && value !== null && String(value).trim() !== '' && String(value).trim() !== '0';
const firstPresent = (...values) => values.find(present);
// Slot/PON 0 são posições válidas: aqui só vazio conta como ausente.
const filled = value => value !== undefined && value !== null && String(value).trim() !== '';
/** Título avulso/renegociação: sem contrato (id_contrato '0' ou vazio). */
const isLooseInvoice = invoice => !present(invoice?.id_contrato);
/** Dia de cobrança do contrato, se o IXC expõe o campo (varia por versão). */
function billingDay(contract) {
    for (const key of ['dia_vencimento', 'dia_fixo_vencimento', 'vencimento_dia', 'dia_venc']) {
        const day = Number(contract?.[key]);
        if (Number.isInteger(day) && day >= 1 && day <= 31) return day;
    }
    return null;
}
/**
 * Contrato que recebe os títulos avulsos do cliente (para valores somados por
 * contrato): o único contrato, ou o primeiro ativo, ou o primeiro.
 */
function looseInvoiceOwners(contracts) {
    const byClient = new Map();
    for (const contract of [...contracts].sort((a, b) => Number(a.id) - Number(b.id))) {
        const key = String(contract.id_cliente);
        const current = byClient.get(key);
        if (!current || (String(current.status).toUpperCase() !== 'A' && String(contract.status).toUpperCase() === 'A')) byClient.set(key, contract);
    }
    return new Map([...byClient].map(([client, contract]) => [client, String(contract.id)]));
}
async function mapBounded(items, limit, fn) {
    let next = 0;
    const run = async () => { while (next < items.length) { const index = next++; await fn(items[index], index); } };
    await Promise.all(Array.from({ length: Math.min(limit, items.length) }, run));
}

function createIxcGateway({ call, allowWrites = true, pixLookup = true, now = () => new Date() }) {
    const cityCache = new Map();

    async function list(table, qtype, query, options = {}) {
        const body = {
            qtype: `${table}.${qtype}`,
            query: String(query),
            oper: options.oper || '=',
            page: String(options.page || 1),
            rp: String(options.rp || 100),
            sortname: options.sort || `${table}.id`,
            sortorder: options.order || 'desc',
        };
        if (options.grid) body.grid_param = JSON.stringify(options.grid);
        const data = await call(table, body, 'listar');
        if (data && data.type === 'error') throw ixcError(data.message);
        return { total: Number(data?.total || 0), registros: Array.isArray(data?.registros) ? data.registros : [] };
    }

    async function listAll(table, qtype, query, options = {}) {
        const rp = options.rp || 200;
        const rows = [];
        for (let page = 1; page <= (options.maxPages || MAX_PAGES); page++) {
            const result = await list(table, qtype, query, { ...options, rp, page });
            rows.push(...result.registros);
            if (result.registros.length < rp || rows.length >= result.total) break;
        }
        return rows;
    }

    async function byIds(table, ids, options = {}) {
        const rows = [];
        for (const part of chunks(unique(ids), ID_CHUNK)) {
            rows.push(...await listAll(table, options.field || 'id', part.join(','), { ...options, oper: 'IN' }));
        }
        return rows;
    }

    async function findClients(cpfCnpj) {
        const raw = digits(cpfCnpj);
        if (!/^\d{11}(\d{3})?$/.test(raw)) return [];
        // `cliente.cnpj_cpf` é gravado formatado; alguns provedores guardam só dígitos.
        let { registros } = await list('cliente', 'cnpj_cpf', formatCpfCnpj(raw), { rp: 10 });
        if (!registros.length) ({ registros } = await list('cliente', 'cnpj_cpf', raw, { rp: 10 }));
        return registros;
    }

    async function plansById(ids) {
        const plans = new Map();
        for (const plan of await byIds('vd_contratos', ids)) plans.set(String(plan.id), String(plan.nome || '').trim());
        return plans;
    }

    async function cityNames(ids) {
        const missing = unique(ids.filter(present)).filter(id => !cityCache.has(id));
        if (missing.length) {
            for (const city of await byIds('cidade', missing)) cityCache.set(String(city.id), String(city.nome || '').trim());
            if (cityCache.size > 2000) cityCache.clear();
        }
        return id => (present(id) ? cityCache.get(String(id)) || '' : '');
    }

    // Datas de vencimento são locais do provedor; o container roda em UTC.
    function localDateParts() {
        const parts = Object.fromEntries(new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Fortaleza', year: 'numeric', month: '2-digit', day: '2-digit' })
            .formatToParts(now()).filter(p => p.type !== 'literal').map(p => [p.type, p.value]));
        return { year: Number(parts.year), month: Number(parts.month), day: Number(parts.day), iso: `${parts.year}-${parts.month}-${parts.day}` };
    }
    function todayIso() { return localDateParts().iso; }
    function shiftIso(days) {
        const { year, month, day } = localDateParts();
        return new Date(Date.UTC(year, month - 1, day + days)).toISOString().slice(0, 10);
    }

    /** Vencidas + a próxima a vencer: não soma carnê de meses futuros. */
    function openAmountFor(invoices) {
        const today = todayIso();
        const open = invoices.filter(i => i.status === 'A').sort((a, b) => String(a.data_vencimento).localeCompare(String(b.data_vencimento)));
        const overdue = open.filter(i => String(i.data_vencimento) < today);
        const upcoming = open.find(i => String(i.data_vencimento) >= today);
        const counted = upcoming ? [...overdue, upcoming] : overdue;
        return {
            amount: counted.reduce((sum, i) => sum + (number(i.valor_aberto ?? i.valor) || 0), 0),
            due: (open[0] && ixcDate(open[0].data_vencimento)) || null,
            hasOpen: open.length > 0,
        };
    }

    function buildContract({ contract, client, plan, invoices, city, invoicesKnown = true }) {
        const billing = openAmountFor(invoices);
        const label = contractStatusLabel(contract);
        const dueDay = billing.due ? Number(billing.due.slice(8, 10)) : 0;
        return {
            contratoId: String(contract.id),
            id: String(contract.id),
            contratoCentralSenha: CENTRAL_MARKER,
            razaoSocial: String(client.razao || client.fantasia || '').trim(),
            nome: String(client.razao || client.fantasia || '').trim(),
            cpfCnpj: digits(client.cnpj_cpf),
            email: String(client.email || client.hotsite_email || '').trim() || null,
            servico_plano: plan || null,
            plano: plan || null,
            status: label,
            contratoStatus: label,
            contratoStatusDisplay: label,
            // Token sem acesso a fn_areceber: valor desconhecido (null), nunca R$ 0,00 falso.
            contratoValorAberto: !invoicesKnown ? null : billing.hasOpen ? Number(billing.amount.toFixed(2)) : 0,
            cobVencimento: invoicesKnown && billing.due ? billing.due.slice(0, 10) : null,
            vencimento: billingDay(contract) || dueDay || null,
            endereco: {
                logradouro: String(contract.endereco || client.endereco || '').trim(),
                numero: String(contract.numero || client.numero || '').trim(),
                bairro: String(contract.bairro || client.bairro || '').trim(),
                cidade: city || '',
                cep: String(contract.cep || client.cep || '').trim(),
            },
            servicos: [],
        };
    }

    async function contractsForClients(clients, { onlyActive = false, withInvoices = true } = {}) {
        const clientIds = clients.map(c => c.id);
        let contracts = await byIds('cliente_contrato', clientIds, { field: 'id_cliente' });
        if (onlyActive) contracts = contracts.filter(c => String(c.status).toUpperCase() === 'A');
        let invoicesKnown = withInvoices;
        const [plans, invoices, cityOf] = await Promise.all([
            plansById(contracts.map(c => c.id_vd_contrato)),
            withInvoices ? byIds('fn_areceber', clientIds, {
                field: 'id_cliente', sort: 'fn_areceber.data_vencimento', order: 'asc',
                grid: [{ TB: 'fn_areceber.status', OP: '=', P: 'A' }],
            }).catch(() => { invoicesKnown = false; return []; }) : Promise.resolve([]),
            cityNames([...clients.map(c => c.cidade), ...contracts.map(c => c.cidade)]),
        ]);
        const clientById = new Map(clients.map(c => [String(c.id), c]));
        // Avulsos/renegociações (id_contrato 0) entram no valor de um só contrato
        // do cliente, para a soma entre contratos não contar duas vezes.
        const looseOwner = looseInvoiceOwners(contracts);
        return contracts.map(contract => {
            const client = clientById.get(String(contract.id_cliente)) || {};
            return buildContract({
                contract, client, plan: plans.get(String(contract.id_vd_contrato)),
                invoices: invoices.filter(i => String(i.id_contrato) === String(contract.id) ||
                    (isLooseInvoice(i) && looseOwner.get(String(i.id_cliente)) === String(contract.id))),
                city: cityOf(firstPresent(contract.cidade, client.cidade)),
                invoicesKnown: invoicesKnown || !withInvoices,
            });
        });
    }

    async function consultaCliente(body) {
        const clients = await findClients(body.cpfcnpj);
        if (!clients.length) return { contratos: [] };
        return { contratos: await contractsForClients(clients) };
    }

    function invoiceView(invoice, paid) {
        const pix = String(invoice.pix_txid || '').trim();
        const amount = paid ? (number(invoice.valor_recebido) || number(invoice.valor)) : (number(invoice.valor_aberto) ?? number(invoice.valor));
        return {
            id: String(invoice.id),
            nossoNumero: String(invoice.nn_boleto || '').trim() || null,
            numeroDocumento: String(invoice.documento || invoice.id),
            valor: amount,
            dataVencimento: ixcDate(invoice.data_vencimento),
            dataPagamento: paid ? ixcDate(invoice.pagamento_data) : null,
            link: String(invoice.gateway_link || '').trim() || null,
            linhaDigitavel: String(invoice.linha_digitavel || '').trim() || null,
            // Só o payload EMV serve como "copia e cola"; `pix_txid` isolado não paga nada.
            codigoPix: pix.startsWith('000201') ? pix : null,
            contrato: present(invoice.id_contrato) ? String(invoice.id_contrato) : null,
            contratoId: present(invoice.id_contrato) ? String(invoice.id_contrato) : null,
        };
    }

    async function titulos(body) {
        const paid = String(body.status || 'abertos').toLowerCase().startsWith('pag');
        const status = paid ? 'R' : 'A';
        const grid = [{ TB: 'fn_areceber.status', OP: '=', P: status }];
        const options = { sort: 'fn_areceber.data_vencimento', order: paid ? 'desc' : 'asc', grid };
        let rows;
        if (body.contrato) {
            // O contrato precisa pertencer ao CPF informado antes de listar títulos.
            const clients = await findClients(body.cpfcnpj);
            const owned = clients.length ? await byIds('cliente_contrato', clients.map(c => c.id), { field: 'id_cliente' }) : [];
            const contract = owned.find(c => String(c.id) === String(body.contrato));
            if (!contract) return { titulos: [] };
            rows = await listAll('fn_areceber', 'id_contrato', body.contrato, { ...options, rp: paid ? 36 : 100, maxPages: paid ? 1 : MAX_PAGES });
            if (!paid) {
                // Avulsos/renegociações em aberto do dono do contrato (id_contrato 0)
                // aparecem junto do contrato pedido; sem isso ficam invisíveis.
                const loose = (await listAll('fn_areceber', 'id_cliente', contract.id_cliente, { ...options, rp: 100, maxPages: 2 })
                    .catch(() => [])).filter(isLooseInvoice);
                const seen = new Set(rows.map(row => String(row.id)));
                for (const row of loose) if (!seen.has(String(row.id))) rows.push({ ...row, id_contrato: String(body.contrato) });
                rows.sort((a, b) => String(a.data_vencimento).localeCompare(String(b.data_vencimento)));
            }
        } else {
            const clients = await findClients(body.cpfcnpj);
            if (!clients.length) return { titulos: [] };
            rows = [];
            for (const part of chunks(clients.map(c => String(c.id)), ID_CHUNK)) {
                rows.push(...await listAll('fn_areceber', 'id_cliente', part.join(','), { ...options, oper: 'IN', rp: paid ? 36 : 100, maxPages: paid ? 1 : MAX_PAGES }));
            }
            if (!paid && rows.some(isLooseInvoice)) {
                // Sem contrato pedido: o avulso vai para o contrato principal do cliente.
                const owners = looseInvoiceOwners(await byIds('cliente_contrato', clients.map(c => c.id), { field: 'id_cliente' }).catch(() => []));
                rows = rows.map(row => (isLooseInvoice(row) && owners.has(String(row.id_cliente)) ? { ...row, id_contrato: owners.get(String(row.id_cliente)) } : row));
            }
        }
        const view = rows.map(row => invoiceView(row, paid));
        if (!paid && pixLookup) await attachPix(view);
        return { titulos: view };
    }

    function emvFrom(data) {
        const code = data?.pix?.qrCode?.qrcode ?? data?.pix?.qrcode ?? data?.qrcode;
        return typeof code === 'string' && code.trim().startsWith('000201') ? code.trim() : null;
    }

    // Leitura do PIX de cada fatura (equivale ao cliente abrir o PIX na central).
    // Falha numa fatura nunca derruba a lista: o campo só fica vazio.
    // Até PIX_CONCURRENCY consultas simultâneas; cada resultado volta para a
    // própria fatura, então a ordem da lista não muda.
    async function attachPix(view) {
        const pending = view.filter(i => !i.codigoPix).slice(0, MAX_PIX_LOOKUPS);
        await mapBounded(pending, PIX_CONCURRENCY, async invoice => {
            try {
                const data = await call('get_pix', { id_areceber: invoice.id }, '');
                if (data && data.type === 'error') return;
                invoice.codigoPix = emvFrom(data);
            } catch { /* mantém null */ }
        });
    }

    /**
     * PDF do boleto de uma fatura em aberto (equivale a imprimir na central).
     * Antes de emitir confere, pelo próprio fn_areceber, que a fatura é do CPF
     * informado (e do contrato, se vier) e está em aberto. `atualiza_boleto: N`:
     * o IXC não recalcula vencimento/valor; juros e multa ficam com o banco.
     */
    async function boletoPdf(body = {}) {
        const faturaId = String(body.faturaId ?? body.id ?? '').trim();
        if (!/^\d{1,12}$/.test(faturaId)) throw Object.assign(new Error('Fatura inválida.'), { status: 400 });
        const clients = await findClients(body.cpfcnpj);
        const owners = new Set(clients.map(c => String(c.id)));
        if (!owners.size) throw boletoUnavailable('Fatura não encontrada.', 'invoice-not-found');
        const { registros } = await list('fn_areceber', 'id', faturaId, { rp: 1 });
        const invoice = registros.find(row => String(row.id) === faturaId);
        if (!invoice || !owners.has(String(invoice.id_cliente))) throw boletoUnavailable('Fatura não encontrada.', 'invoice-not-found');
        if (present(body.contrato) && !isLooseInvoice(invoice) && String(invoice.id_contrato) !== String(body.contrato)) {
            throw boletoUnavailable('Fatura não encontrada.', 'invoice-not-found');
        }
        if (String(invoice.status).toUpperCase() !== 'A') throw boletoUnavailable('Esta fatura não está em aberto.', 'invoice-not-open');
        const data = await call('get_boleto', {
            boletos: faturaId, juro: 'N', multa: 'N', atualiza_boleto: 'N', tipo_boleto: 'arquivo', base64: 'S',
        }, 'listar');
        const failure = ixcErrorText(data);
        if (failure) {
            // Carteira de API (Sicredi, Santander…) registra o boleto ao emitir e
            // recusa título vencido sem registro; não há o que tentar de novo.
            if (/vencimento/i.test(failure)) throw boletoUnavailable('O boleto desta fatura vencida não pode ser emitido pelo app. Use o PIX ou fale com o suporte.', 'boleto-overdue');
            throw boletoUnavailable();
        }
        return { pdf: decodeBoletoPdf(data), faturaId };
    }

    async function loginsOfContract(contractId) {
        return listAll('radusuarios', 'id_contrato', contractId, { rp: 20, maxPages: 1 });
    }

    async function assertOwnedContract(body) {
        if (!body.contrato) throw unsupported('Contrato obrigatório.');
        if (!body.cpfcnpj) return;
        const clients = await findClients(body.cpfcnpj);
        const owned = clients.length ? await byIds('cliente_contrato', clients.map(c => c.id), { field: 'id_cliente' }) : [];
        if (!owned.some(c => String(c.id) === String(body.contrato))) {
            throw Object.assign(new Error('Contrato não pertence ao cliente.'), { status: 404 });
        }
        return owned.find(c => String(c.id) === String(body.contrato));
    }

    async function verificaAcesso(body) {
        await assertOwnedContract(body);
        const logins = await loginsOfContract(body.contrato);
        const online = logins.some(login => String(login.online || '').toUpperCase().startsWith('S'));
        return { status: online ? 1 : 0, msg: online ? 'Serviço Online' : 'Serviço Offline' };
    }

    async function extratoUso(body) {
        const contract = await assertOwnedContract(body);
        const local = localDateParts();
        const month = Math.min(12, Math.max(1, Number(body.mes) || local.month));
        const year = Number(body.ano) || local.year;
        const start = `${year}-${String(month).padStart(2, '0')}-01 00:00:00`;
        const next = month === 12 ? `${year + 1}-01-01 00:00:00` : `${year}-${String(month + 1).padStart(2, '0')}-01 00:00:00`;
        const logins = await loginsOfContract(body.contrato);
        const sessions = [];
        for (const login of logins.slice(0, 5)) {
            sessions.push(...await listAll('radacct', 'username', login.login, {
                sort: 'radacct.radacctid', order: 'asc', rp: 1000, maxPages: 5,
                grid: [{ TB: 'radacct.acctstarttime', OP: '>=', P: start }, { TB: 'radacct.acctstarttime', OP: '<', P: next }],
            }));
        }
        let total = 0;
        const extrato = [];
        for (const session of sessions) {
            const startedAt = ixcDate(session.acctstarttime);
            if (!startedAt) continue;
            // Accounting RADIUS: Output = enviado ao assinante (download); Input = upload.
            const download = number(session.acctoutputoctets) || 0;
            const upload = number(session.acctinputoctets) || 0;
            total += download + upload;
            extrato.push({ data_inicio: startedAt, download, upload });
        }
        const plan = contract?.id_vd_contrato ? (await plansById([contract.id_vd_contrato])).get(String(contract.id_vd_contrato)) : '';
        return { plano: plan || null, total, extrato };
    }

    async function onuList(body) {
        await assertOwnedContract(body);
        const logins = await loginsOfContract(body.contrato);
        if (!logins.length) return [];
        const onus = await byIds('radpop_radio_cliente_fibra', logins.map(l => l.id), { field: 'id_login' });
        if (!onus.length) return [];
        const olts = new Map();
        for (const olt of await byIds('radpop_radio', onus.map(o => o.id_transmissor)).catch(() => [])) olts.set(String(olt.id), String(olt.descricao || '').trim());
        return onus.map(onu => {
            const login = logins.find(l => String(l.id) === String(onu.id_login)) || logins[0];
            const measuredAt = ixcDate(onu.data_sinal);
            const dbm = value => (measuredAt && number(value) !== null && number(value) !== 0 ? `${Number(number(value)).toFixed(2)} dBm` : 'N/A');
            return {
                info_rx: dbm(onu.sinal_rx),
                info_tx: dbm(onu.sinal_tx),
                online: String(login?.online || '').toUpperCase().startsWith('S'),
                olt_id: onu.id_transmissor ? String(onu.id_transmissor) : '0',
                olt_name: olts.get(String(onu.id_transmissor)) || null,
                slot: onu.slotno || '0',
                pon: onu.ponno || '0',
                onuid: onu.onu_numero || '0',
                temperature: measuredAt ? number(onu.temperatura) : null,
                voltage: measuredAt && number(onu.voltagem) ? number(onu.voltagem) : null,
                type: String(onu.onu_tipo || '').trim() || null,
                phy_addr: String(onu.mac || '').trim() || null,
                vlan: String(onu.vlan_pppoe || onu.vlan || '').trim() || null,
                cto: null,
                info_date: measuredAt,
            };
        });
    }

    async function liberacaoPromessa(body) {
        if (!allowWrites) throw unsupported('Escrita desativada para a integração IXC.');
        await assertOwnedContract(body);
        const data = await call('desbloqueio_confianca', { id: String(body.contrato) }, '');
        const ok = data && String(data.type || '').toLowerCase() === 'success';
        return { status: ok ? 1 : 0, msg: String(data?.message || (ok ? 'Liberação em confiança realizada.' : 'Não foi possível liberar.')).slice(0, 200) };
    }

    async function clientes(body) {
        const limit = Math.min(100, Math.max(1, Number(body.limit) || 100));
        const offset = Math.max(0, Number(body.offset) || 0);
        const page = Math.floor(offset / limit) + 1;
        const result = await list('cliente', 'ativo', 'S', { rp: limit, page, sort: 'cliente.id', order: 'asc' });
        const contratos = await contractsForClients(result.registros, { onlyActive: true, withInvoices: false });
        await enrichForSync(contratos);
        return {
            clientes: result.registros.map(client => ({
                id: String(client.id),
                nome: String(client.razao || client.fantasia || '').trim(),
                cpfcnpj: digits(client.cnpj_cpf),
                contratos: contratos.filter(c => String(c.cpfCnpj) === digits(client.cnpj_cpf)),
            })),
            paginacao: { total: result.total, total_paginas: Math.max(1, Math.ceil(result.total / limit)) },
        };
    }

    /**
     * Sincronização: login PPPoE, OLT/slot/PON e dia de vencimento de cada
     * contrato da página, no formato `servicos[].onu` que o SGP já usa. Poucas
     * chamadas em lote; sem permissão numa tabela, só pula aquela parte.
     */
    async function enrichForSync(contracts) {
        if (!contracts.length) return;
        const ids = contracts.map(c => c.contratoId);
        const soft = promise => promise.catch(() => null);
        const [logins, invoices] = await Promise.all([
            soft(byIds('radusuarios', ids, { field: 'id_contrato', rp: 500, maxPages: 2 })),
            contracts.some(c => !c.vencimento) ? soft(byIds('fn_areceber', ids, {
                field: 'id_contrato', sort: 'fn_areceber.data_vencimento', order: 'asc', rp: 500, maxPages: 2,
                grid: [{ TB: 'fn_areceber.status', OP: '=', P: 'A' },
                    { TB: 'fn_areceber.data_vencimento', OP: '>=', P: shiftIso(-DUE_WINDOW_DAYS) },
                    { TB: 'fn_areceber.data_vencimento', OP: '<=', P: shiftIso(DUE_WINDOW_DAYS) }],
            })) : Promise.resolve(null),
        ]);
        const onus = logins?.length ? await soft(byIds('radpop_radio_cliente_fibra', logins.map(l => l.id), { field: 'id_login', rp: 500, maxPages: 2 })) : null;
        const olts = new Map();
        if (onus?.length) {
            for (const olt of await soft(byIds('radpop_radio', onus.map(o => o.id_transmissor))) || []) olts.set(String(olt.id), String(olt.descricao || '').trim());
        }
        const onuByLogin = new Map((onus || []).map(onu => [String(onu.id_login), onu]));
        const dueByContract = new Map();
        for (const invoice of invoices || []) {
            const due = ixcDate(invoice.data_vencimento);
            const key = String(invoice.id_contrato);
            if (due && !dueByContract.has(key)) dueByContract.set(key, Number(due.slice(8, 10)));
        }
        for (const contract of contracts) {
            if (!contract.vencimento && dueByContract.get(contract.contratoId)) contract.vencimento = dueByContract.get(contract.contratoId);
            if (!logins) continue;
            contract.servicos = logins.filter(l => String(l.id_contrato) === contract.contratoId).map(login => {
                const onu = onuByLogin.get(String(login.id));
                return {
                    login: String(login.login || '').trim(),
                    onu: onu ? {
                        olt_id: present(onu.id_transmissor) ? String(onu.id_transmissor) : null,
                        olt_nome: olts.get(String(onu.id_transmissor)) || null,
                        slot: filled(onu.slotno) ? String(onu.slotno).trim() : null,
                        pon: filled(onu.ponno) ? String(onu.ponno).trim() : null,
                    } : null,
                };
            });
        }
    }

    const ROUTES = [
        [/\/ura\/consultacliente\/?$/, consultaCliente],
        [/\/ura\/titulos\/?$/, titulos],
        [/\/central\/verificaacesso\/?$/, verificaAcesso],
        [/\/central\/extratouso\/?$/, extratoUso],
        [/\/fttx\/onu\/list\/?$/, onuList],
        [/\/ura\/liberacaopromessa\/?$/, liberacaoPromessa],
        [/\/ura\/clientes\/?$/, clientes],
    ];

    /** `path` é o caminho SGP (`/api/ura/titulos/`); `body` o corpo/params SGP. */
    async function handle(path, body = {}) {
        const route = ROUTES.find(([pattern]) => pattern.test(path));
        if (!route) throw unsupported('Recurso não disponível para integrações IXC.');
        return route[1](body);
    }

    return { handle, list, boletoPdf, contractStatusLabel };
}

/** Sem `ixcsoft: listar` o IXC trata o POST como escrita; leitura sempre usa `listar`. */
function ixcHeaders(token, action) {
    const headers = { authorization: `Basic ${Buffer.from(String(token), 'utf8').toString('base64')}` };
    if (action) headers.ixcsoft = action;
    return headers;
}

function ixcUrl(baseUrl, table) {
    if (!/^[a-z0-9_]{1,64}$/i.test(table)) throw ixcError('tabela inválida');
    return `${String(baseUrl).replace(/\/$/, '')}/webservice/v1/${table}`;
}

module.exports = { createIxcGateway, decodeBoletoPdf, ixcErrorText, MAX_BOLETO_BYTES, formatCpfCnpj, ixcDate, contractStatusLabel, ixcHeaders, ixcUrl, CENTRAL_MARKER };
