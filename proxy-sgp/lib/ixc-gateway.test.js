'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createIxcGateway, decodeBoletoPdf, ixcErrorText, MAX_BOLETO_BYTES, formatCpfCnpj, ixcDate, ixcHeaders, ixcUrl, contractStatusLabel } = require('./ixc-gateway');
const outbound = require('./sgp-outbound');

const NOW = new Date('2026-11-24T12:00:00Z');

function dataset() {
    return {
        cliente: [
            { id: '1', razao: 'Maria Teste', fantasia: '', cnpj_cpf: '123.456.789-09', email: 'maria@example.com', cidade: '10', endereco: 'Rua A', numero: '5', bairro: 'Centro', cep: '55000', ativo: 'S' },
            { id: '2', razao: 'Empresa Teste', cnpj_cpf: '12.345.678/0001-95', email: '', cidade: '10', ativo: 'S' },
            { id: '3', razao: 'Outro', cnpj_cpf: '987.654.321-00', cidade: '10', ativo: 'N' },
        ],
        cliente_contrato: [
            { id: '100', id_cliente: '1', status: 'A', status_internet: 'A', id_vd_contrato: '7' },
            { id: '101', id_cliente: '1', status: 'A', status_internet: 'FA', id_vd_contrato: '7' },
            { id: '102', id_cliente: '1', status: 'I', status_internet: 'D', id_vd_contrato: '7' },
            { id: '200', id_cliente: '2', status: 'A', status_internet: 'CM', id_vd_contrato: '8' },
            { id: '300', id_cliente: '3', status: 'A', status_internet: 'A', id_vd_contrato: '7' },
        ],
        vd_contratos: [{ id: '7', nome: 'Fibra 300MB' }, { id: '8', nome: 'Empresarial 1GB' }],
        cidade: [{ id: '10', nome: 'Olinda' }],
        fn_areceber: [
            { id: '900', id_cliente: '1', id_contrato: '100', status: 'A', valor: '80.00', valor_aberto: '80.00', data_vencimento: '2026-11-10', documento: 'D1', nn_boleto: '777', linha_digitavel: '34191.0000', gateway_link: 'https://pay.example/900', pix_txid: 'abc123' },
            { id: '901', id_cliente: '1', id_contrato: '100', status: 'A', valor: '80.00', valor_aberto: '80.00', data_vencimento: '2026-12-10', pix_txid: '000201010212...EMV' },
            { id: '902', id_cliente: '1', id_contrato: '100', status: 'A', valor: '80.00', valor_aberto: '80.00', data_vencimento: '2027-01-10' },
            { id: '903', id_cliente: '1', id_contrato: '100', status: 'R', valor: '80.00', valor_recebido: '79.50', data_vencimento: '2026-10-10', pagamento_data: '2026-10-09' },
            { id: '904', id_cliente: '1', id_contrato: '100', status: 'C', valor: '80.00', data_vencimento: '2026-09-10' },
            { id: '905', id_cliente: '2', id_contrato: '200', status: 'A', valor: '150.00', valor_aberto: '150.00', data_vencimento: '2026-12-05' },
        ],
        radusuarios: [
            { id: '50', id_contrato: '100', login: 'maria.fibra', online: 'SS', ativo: 'S' },
            { id: '51', id_contrato: '200', login: 'empresa.fibra', online: 'N', ativo: 'S' },
        ],
        radacct: [
            { radacctid: '1', username: 'maria.fibra', acctstarttime: '03/11/2026 05:12:25', acctoutputoctets: String(2 * 1024 ** 3), acctinputoctets: String(1024 ** 3) },
            { radacctid: '2', username: 'maria.fibra', acctstarttime: '10/11/2026 08:00:00', acctoutputoctets: String(1024 ** 3), acctinputoctets: '0' },
            { radacctid: '3', username: 'maria.fibra', acctstarttime: '30/10/2026 23:00:00', acctoutputoctets: String(9 * 1024 ** 3), acctinputoctets: '0' },
        ],
        radpop_radio_cliente_fibra: [
            { id: '60', id_login: '50', id_transmissor: '3', slotno: '1', ponno: '4', onu_numero: '14', onu_tipo: 'TPLG-XC220', mac: '54:50:4C:00:00:01', sinal_rx: '-25.08', sinal_tx: '-20.92', temperatura: '56.00', voltagem: '3.30', data_sinal: '2026-11-24 12:01:17', vlan_pppoe: '100' },
            { id: '61', id_login: '51', id_transmissor: '3', sinal_rx: '0.00', sinal_tx: '0.00', temperatura: '0', data_sinal: '0000-00-00 00:00:00' },
        ],
        radpop_radio: [{ id: '3', descricao: 'OLT BOMBA' }],
    };
}

/** Servidor IXC falso: implementa `=`/`IN` e grid_param (`=`, `>=`, `<`). */
function fakeIxc(data = dataset(), { onCall } = {}) {
    const calls = [];
    const call = async (table, body, action) => {
        calls.push({ table, body, action });
        if (onCall) { const custom = onCall(table, body, action); if (custom !== undefined) return custom; }
        if (table === 'desbloqueio_confianca') return { type: 'success', message: 'Liberado' };
        const rows = data[table] || [];
        const field = body.qtype.split('.')[1];
        const cmp = (value, op, p) => op === '=' ? String(value) === String(p) : op === '>=' ? String(value) >= String(p) : op === '<' ? String(value) < String(p)
            : op === '<=' ? String(value) <= String(p) : op === '>' ? String(value) > String(p) : false;
        const dateKey = value => {
            const m = String(value).match(/^(\d{2})\/(\d{2})\/(\d{4}) (.*)$/);
            return m ? `${m[3]}-${m[2]}-${m[1]} ${m[4]}` : String(value);
        };
        let found = rows.filter(row => body.oper === 'IN' ? String(body.query).split(',').includes(String(row[field])) : cmp(row[field], body.oper, body.query));
        for (const g of JSON.parse(body.grid_param || '[]')) {
            const column = g.TB.split('.')[1];
            found = found.filter(row => cmp(column.includes('start') ? dateKey(row[column]) : row[column], g.OP, g.P));
        }
        const rp = Number(body.rp); const page = Number(body.page);
        return { page, total: found.length, registros: found.slice((page - 1) * rp, page * rp) };
    };
    return { call, calls };
}

const gateway = (opts = {}, data) => { const fake = fakeIxc(data, opts); return { ...createIxcGateway({ call: fake.call, now: () => NOW, ...opts.gateway }), calls: fake.calls }; };

test('formata CPF/CNPJ como o IXC grava e normaliza datas mistas', () => {
    assert.equal(formatCpfCnpj('12345678909'), '123.456.789-09');
    assert.equal(formatCpfCnpj('12345678000195'), '12.345.678/0001-95');
    assert.equal(ixcDate('24/11/2026 05:12:25'), '2026-11-24T05:12:25');
    assert.equal(ixcDate('2026-11-24 12:01:17'), '2026-11-24T12:01:17');
    assert.equal(ixcDate('2026-11-24'), '2026-11-24');
    assert.equal(ixcDate('0000-00-00 00:00:00'), null);
    assert.equal(ixcDate(''), null);
});

test('consultacliente: contratos no formato SGP e consulta por CPF formatado', async () => {
    const g = gateway();
    const { contratos } = await g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' });
    assert.deepEqual(contratos.map(c => c.contratoId), ['100', '101', '102']);
    assert.equal(g.calls[0].body.query, '123.456.789-09');
    const active = contratos[0];
    assert.equal(active.contratoStatusDisplay, 'Ativo');
    assert.equal(active.razaoSocial, 'Maria Teste');
    assert.equal(active.servico_plano, 'Fibra 300MB');
    assert.equal(active.cpfCnpj, '12345678909');
    assert.equal(active.endereco.cidade, 'Olinda');
    assert.ok(active.contratoCentralSenha, 'senha marcador mantém o fluxo SGP elegível');
    // vencida (80) + próxima a vencer (80); o carnê futuro de 2027 não entra.
    assert.equal(active.contratoValorAberto, 160);
    assert.equal(active.cobVencimento, '2026-11-10');
    assert.equal(active.vencimento, 10);
    assert.equal(contratos[1].contratoStatusDisplay, 'Suspenso por atraso financeiro');
    assert.equal(contratos[2].contratoStatusDisplay, 'Inativo');
});

test('consultacliente: cai para CPF só com dígitos e devolve vazio sem cliente', async () => {
    const data = dataset(); data.cliente[0].cnpj_cpf = '12345678909';
    const g = gateway({}, data);
    assert.equal((await g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' })).contratos.length, 3);
    assert.deepEqual(g.calls.slice(0, 2).map(c => c.body.query), ['123.456.789-09', '12345678909']);
    assert.deepEqual(await g.handle('/api/ura/consultacliente/', { cpfcnpj: '11111111111' }), { contratos: [] });
    assert.deepEqual(await g.handle('/api/ura/consultacliente/', { cpfcnpj: 'abc' }), { contratos: [] });
});

test('status de contrato diferencia bloqueios que ainda podem entrar no app', () => {
    const label = (status, status_internet) => contractStatusLabel({ status, status_internet });
    assert.equal(label('A', 'A'), 'Ativo');
    assert.equal(label('A', 'CM'), 'Bloqueio manual');
    assert.equal(label('A', 'CA'), 'Bloqueio automático');
    assert.equal(label('A', 'AA'), 'Aguardando assinatura');
    assert.equal(label('A', 'D'), 'Desativado');
    assert.equal(label('D', 'D'), 'Cancelado');
    assert.equal(label('I', 'A'), 'Inativo');
    assert.equal(label('P', 'A'), 'Pré-contrato');
});

test('consultacliente: token sem acesso a faturas devolve valor desconhecido, não R$ 0,00', async () => {
    const g = gateway({ onCall: table => table === 'fn_areceber' ? { type: 'error', message: 'Você não tem permissão para acessar o recurso fn_areceber' } : undefined });
    const { contratos } = await g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' });
    assert.equal(contratos.length, 3);
    for (const contrato of contratos) {
        assert.equal(contrato.contratoValorAberto, null);
        assert.equal(contrato.cobVencimento, null);
    }
    assert.equal(contratos[0].contratoStatusDisplay, 'Ativo');
});

test('titulos: abertos e pagos, sem cancelados, com PIX só quando é payload EMV', async () => {
    const g = gateway();
    const open = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' })).titulos;
    assert.deepEqual(open.map(t => t.id), ['900', '901', '902']);
    assert.equal(open[0].valor, 80);
    assert.equal(open[0].dataVencimento, '2026-11-10');
    assert.equal(open[0].link, 'https://pay.example/900');
    assert.equal(open[0].linhaDigitavel, '34191.0000');
    assert.equal(open[0].codigoPix, null, 'pix_txid sozinho não é copia e cola');
    assert.equal(open[1].codigoPix, '000201010212...EMV');
    assert.equal(open[0].contratoId, '100');
    const paid = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'pagos' })).titulos;
    assert.deepEqual(paid.map(t => t.id), ['903']);
    assert.equal(paid[0].valor, 79.5);
    assert.equal(paid[0].dataPagamento, '2026-10-09');
});

test('titulos: filtra por contrato e bloqueia contrato de outro CPF', async () => {
    const g = gateway();
    const own = await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos', contrato: '100' });
    assert.equal(own.titulos.length, 3);
    const foreign = await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos', contrato: '200' });
    assert.deepEqual(foreign, { titulos: [] });
});

test('verificaacesso: online pelo radius e recusa contrato alheio', async () => {
    const g = gateway();
    assert.deepEqual(await g.handle('/api/central/verificaacesso/', { cpfcnpj: '12345678909', contrato: '100' }), { status: 1, msg: 'Serviço Online' });
    assert.deepEqual(await g.handle('/api/central/verificaacesso/', { cpfcnpj: '12345678000195', contrato: '200' }), { status: 0, msg: 'Serviço Offline' });
    await assert.rejects(g.handle('/api/central/verificaacesso/', { cpfcnpj: '12345678909', contrato: '200' }), { status: 404 });
});

test('extratouso: soma só o mês pedido, converte datas e separa download/upload', async () => {
    const g = gateway();
    const extrato = await g.handle('/api/central/extratouso/', { cpfcnpj: '12345678909', contrato: '100', mes: '11', ano: '2026' });
    assert.equal(extrato.plano, 'Fibra 300MB');
    assert.equal(extrato.extrato.length, 2);
    assert.equal(extrato.total, 4 * 1024 ** 3);
    assert.deepEqual(extrato.extrato[0], { data_inicio: '2026-11-03T05:12:25', download: 2 * 1024 ** 3, upload: 1024 ** 3 });
    assert.ok(!Number.isNaN(new Date(extrato.extrato[0].data_inicio).getTime()));
    const grid = JSON.parse(g.calls.find(c => c.table === 'radacct').body.grid_param);
    assert.deepEqual(grid.map(c => [c.OP, c.P]), [['>=', '2026-11-01 00:00:00'], ['<', '2026-12-01 00:00:00']]);
});

test('onu: sinal em dBm, N/A sem leitura e nome da OLT', async () => {
    const g = gateway();
    const [onu] = await g.handle('/api/fttx/onu/list/', { cpfcnpj: '12345678909', contrato: '100' });
    assert.equal(onu.info_rx, '-25.08 dBm');
    assert.equal(onu.info_tx, '-20.92 dBm');
    assert.equal(onu.online, true);
    assert.equal(onu.olt_name, 'OLT BOMBA');
    assert.equal(onu.slot, '1');
    assert.equal(onu.pon, '4');
    assert.equal(onu.onuid, '14');
    assert.equal(onu.temperature, 56);
    assert.equal(onu.phy_addr, '54:50:4C:00:00:01');
    assert.equal(onu.vlan, '100');
    const [idle] = await g.handle('/api/fttx/onu/list/', { cpfcnpj: '12345678000195', contrato: '200' });
    assert.equal(idle.info_rx, 'N/A');
    assert.equal(idle.temperature, null);
    assert.equal(idle.online, false);
    assert.deepEqual(await g.handle('/api/fttx/onu/list/', { cpfcnpj: '12345678909', contrato: '101' }), []);
});

test('liberacaopromessa: escrita só com contrato do CPF e respeita o desligamento', async () => {
    const g = gateway();
    assert.deepEqual(await g.handle('/api/ura/liberacaopromessa/', { cpfcnpj: '12345678909', contrato: '100' }), { status: 1, msg: 'Liberado' });
    const write = g.calls.find(c => c.table === 'desbloqueio_confianca');
    assert.deepEqual(write.body, { id: '100' });
    assert.equal(write.action, '', 'escrita não envia ixcsoft: listar');
    await assert.rejects(g.handle('/api/ura/liberacaopromessa/', { cpfcnpj: '12345678909', contrato: '200' }), { status: 404 });
    const denied = gateway({ gateway: { allowWrites: false } });
    await assert.rejects(denied.handle('/api/ura/liberacaopromessa/', { cpfcnpj: '12345678909', contrato: '100' }), { status: 501 });
    assert.equal(denied.calls.length, 0);
    const refused = gateway({ onCall: table => table === 'desbloqueio_confianca' ? { type: 'error', message: 'Sem direito' } : undefined });
    assert.deepEqual(await refused.handle('/api/ura/liberacaopromessa/', { cpfcnpj: '12345678909', contrato: '100' }), { status: 0, msg: 'Sem direito' });
});

test('clientes: pagina clientes ativos com contratos ativos e total de páginas', async () => {
    const g = gateway();
    const result = await g.handle('/api/ura/clientes/', { limit: 1, offset: 0 });
    assert.equal(result.clientes.length, 1);
    assert.equal(result.clientes[0].cpfcnpj, '12345678909');
    assert.deepEqual(result.clientes[0].contratos.map(c => c.contratoId), ['100', '101']);
    assert.deepEqual(result.paginacao, { total: 2, total_paginas: 2 });
    const second = await g.handle('/api/ura/clientes/', { limit: 1, offset: 1 });
    assert.equal(second.clientes[0].cpfcnpj, '12345678000195');
    // Sync só lê faturas numa janela curta para achar o dia de vencimento; nunca PIX.
    const invoiceCalls = g.calls.filter(c => c.table === 'fn_areceber');
    assert.ok(invoiceCalls.every(c => JSON.parse(c.body.grid_param).some(f => f.TB === 'fn_areceber.data_vencimento' && f.OP === '>=')));
    assert.equal(g.calls.some(c => c.table === 'get_pix'), false);
});

test('erros do IXC viram 502 e rotas não suportadas viram 501', async () => {
    const g = gateway({ onCall: () => ({ type: 'error', message: 'Você não tem permissão para acessar o recurso fn_areceber' }) });
    await assert.rejects(g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' }), { status: 502 });
    await assert.rejects(gateway().handle('/api/cpemanager/servico/1/wifi/list/', {}), { status: 501 });
});

test('cabeçalhos IXC: Authorization Basic e ixcsoft; tabela validada', () => {
    const headers = ixcHeaders('user:secret', 'listar');
    assert.equal(headers.authorization, `Basic ${Buffer.from('user:secret').toString('base64')}`);
    assert.equal(headers.ixcsoft, 'listar');
    assert.equal('ixcsoft' in ixcHeaders('t', ''), false);
    assert.equal(ixcUrl('https://ixc.example.com/', 'cliente'), 'https://ixc.example.com/webservice/v1/cliente');
    assert.throws(() => ixcUrl('https://ixc.example.com', '../admin'));
});

test('transporte só aceita cabeçalhos de autenticação do ERP', () => {
    assert.deepEqual(outbound.safeHeaders({ Authorization: 'Basic abc', ixcsoft: 'listar' }), { authorization: 'Basic abc', ixcsoft: 'listar' });
    assert.deepEqual(outbound.safeHeaders(undefined), {});
    for (const bad of [{ Host: 'evil.test' }, { 'X-Forwarded-For': '1.1.1.1' }, { authorization: 'a\r\nHost: evil' }, { authorization: '' }, { authorization: 1 }, ['authorization'], null]) {
        assert.throws(() => outbound.safeHeaders(bad), /inválido|interno/, JSON.stringify(bad));
    }
});

test('integração privada: erp padrão sgp exige app; ixc dispensa app', () => {
    const base = { sgpBaseUrl: 'https://erp.example.com', apiToken: 'tok' };
    assert.deepEqual(outbound.privateIntegration({ ...base, appName: 'app' }), { baseUrl: 'https://erp.example.com', token: 'tok', app: 'app', erp: 'sgp' });
    assert.throws(() => outbound.privateIntegration(base));
    assert.deepEqual(outbound.privateIntegration({ ...base, erp: 'ixc' }), { baseUrl: 'https://erp.example.com', token: 'tok', app: '', erp: 'ixc' });
    assert.throws(() => outbound.privateIntegration({ ...base, appName: 'app', erp: 'outro' }));
});

test('titulos: busca o PIX copia e cola no get_pix só para faturas em aberto sem EMV', async () => {
    const emv = id => `00020101021226${id}EMV`;
    const g = gateway({ onCall: (table, body) => table === 'get_pix'
        ? (body.id_areceber === '902' ? { type: 'error', message: 'Gateway sem PIX' } : { type: 'success', pix: { qrCode: { qrcode: emv(body.id_areceber) } } })
        : undefined });
    const open = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' })).titulos;
    assert.equal(open[0].codigoPix, emv('900'));
    assert.equal(open[1].codigoPix, '000201010212...EMV', 'EMV já gravado não gera chamada');
    assert.equal(open[2].codigoPix, null, 'erro do IXC deixa o campo vazio sem derrubar a lista');
    assert.deepEqual(g.calls.filter(c => c.table === 'get_pix').map(c => c.body.id_areceber), ['900', '902']);
    await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'pagos' });
    assert.equal(g.calls.filter(c => c.table === 'get_pix').length, 2, 'faturas pagas não buscam PIX');
});

test('titulos: resposta de PIX que não é EMV é descartada e a busca pode ser desligada', async () => {
    const g = gateway({ onCall: table => table === 'get_pix' ? { type: 'success', pix: { qrCode: { qrcode: 'txid-solto' } } } : undefined });
    const open = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' })).titulos;
    assert.equal(open[0].codigoPix, null);
    const off = gateway({ gateway: { pixLookup: false } });
    await off.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' });
    assert.equal(off.calls.some(c => c.table === 'get_pix'), false);
});

test('valor em aberto usa a data de Fortaleza: fatura que vence hoje não vira vencida às 21h', async () => {
    // 10/12/2026 23:30 em Fortaleza = 11/12 02:30 UTC. A fatura de 10/12 ainda
    // é a "próxima a vencer"; a de 2027 não pode entrar na soma.
    const lateEvening = new Date('2026-12-11T02:30:00Z');
    const g = gateway({ gateway: { now: () => lateEvening } });
    const { contratos } = await g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' });
    assert.equal(contratos[0].contratoValorAberto, 160);
});

test('titulos: get_pix em paralelo (até 3 por vez) sem mudar a ordem das faturas', async () => {
    const data = dataset();
    for (let i = 0; i < 6; i++) data.fn_areceber.push({ id: String(910 + i), id_cliente: '1', id_contrato: '100', status: 'A', valor: '10', data_vencimento: `2027-0${i + 2}-10` });
    let inFlight = 0; let peak = 0;
    const g = gateway({ onCall: (table, body) => {
        if (table !== 'get_pix') return undefined;
        inFlight++; peak = Math.max(peak, inFlight);
        // Respostas fora de ordem: a mais antiga demora mais.
        const delay = 30 - (Number(body.id_areceber) % 10) * 3;
        return new Promise(resolve => setTimeout(() => { inFlight--; resolve({ pix: { qrCode: { qrcode: `000201${body.id_areceber}` } } }); }, delay));
    } }, data);
    const open = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' })).titulos;
    assert.equal(peak, 3, 'no máximo 3 get_pix simultâneos');
    assert.deepEqual(open.map(t => t.id), ['900', '901', '902', '910', '911', '912', '913', '914', '915']);
    const looked = open.filter(t => t.id !== '901');
    assert.deepEqual(looked.slice(0, 6).map(t => t.codigoPix), looked.slice(0, 6).map(t => `000201${t.id}`), 'cada PIX volta para a própria fatura');
    assert.equal(g.calls.filter(c => c.table === 'get_pix').length, 6, 'limite de consultas por lista mantido');
});

function looseDataset() {
    const data = dataset();
    data.fn_areceber.push(
        { id: '950', id_cliente: '1', id_contrato: '0', id_contrato_avulso: '77', status: 'A', valor: '45.00', valor_aberto: '45.00', data_vencimento: '2026-11-20' },
        { id: '951', id_cliente: '1', id_contrato: '', status: 'A', valor: '15.00', valor_aberto: '15.00', data_vencimento: '2026-11-05' },
        { id: '952', id_cliente: '1', id_contrato: '0', status: 'R', valor: '30.00', valor_recebido: '30.00', data_vencimento: '2026-10-01', pagamento_data: '2026-10-01' },
        { id: '953', id_cliente: '2', id_contrato: '0', status: 'A', valor: '99.00', valor_aberto: '99.00', data_vencimento: '2026-11-15' },
    );
    return data;
}

test('titulos: avulso/renegociação (id_contrato 0 ou vazio) aparece no contrato pedido', async () => {
    const g = gateway({ gateway: { pixLookup: false } }, looseDataset());
    const own = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos', contrato: '100' })).titulos;
    assert.deepEqual(own.map(t => t.id), ['951', '900', '950', '901', '902'], 'ordenado por vencimento');
    assert.ok(own.every(t => t.contratoId === '100' && t.contrato === '100'));
    const other = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos', contrato: '101' })).titulos;
    assert.deepEqual(other.map(t => t.id), ['951', '950'], 'cliente com vários contratos: vai para o contrato pedido');
    const paid = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'pagos', contrato: '100' })).titulos;
    assert.deepEqual(paid.map(t => t.id), ['903'], 'pagos seguem só pelo contrato');
    const all = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' })).titulos;
    assert.equal(all.find(t => t.id === '950').contratoId, '100', 'sem contrato pedido: vai para o contrato principal');
    assert.ok(!all.some(t => t.id === '953'), 'avulso de outro cliente nunca entra');
});

test('titulos: título com id_contrato 0 sem dono conhecido fica com contrato null (nunca "0")', async () => {
    const data = looseDataset();
    data.cliente_contrato = data.cliente_contrato.filter(c => c.id_cliente !== '1');
    const g = gateway({ gateway: { pixLookup: false } }, data);
    const all = (await g.handle('/api/ura/titulos/', { cpfcnpj: '12345678909', status: 'abertos' })).titulos;
    assert.equal(all.find(t => t.id === '950').contrato, null);
});

test('consultacliente: avulso entra no valor em aberto de um único contrato do cliente', async () => {
    const g = gateway({}, looseDataset());
    const { contratos } = await g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' });
    // 951 (05/11) + 900 (10/11) + 950 (20/11) vencidas + 901 (próxima) = 15 + 80 + 45 + 80.
    assert.equal(contratos[0].contratoValorAberto, 220);
    assert.equal(contratos[0].cobVencimento, '2026-11-05');
    assert.equal(contratos[1].contratoValorAberto, 0, 'sem contar duas vezes no segundo contrato');
});

test('cidade "0" ou vazia conta como ausente e a cidade do contrato é buscada', async () => {
    const data = dataset();
    data.cidade.push({ id: '11', nome: 'Recife' });
    data.cliente_contrato[0].cidade = '0';
    data.cliente_contrato[1].cidade = '11';
    data.cliente_contrato[2].cidade = '';
    const g = gateway({}, data);
    const { contratos } = await g.handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' });
    assert.deepEqual(contratos.map(c => c.endereco.cidade), ['Olinda', 'Recife', 'Olinda']);
    assert.ok(!g.calls.some(c => c.table === 'cidade' && String(c.body.query).split(',').includes('0')), 'id 0 nunca é consultado');
    const none = dataset(); none.cliente[0].cidade = '0'; none.cliente_contrato[0].cidade = '0';
    const n = await gateway({}, none).handle('/api/ura/consultacliente/', { cpfcnpj: '12345678909' });
    assert.equal(n.contratos[0].endereco.cidade, '');
});

test('clientes (sync): login, OLT/slot/PON e dia de vencimento em lote, no formato servicos[].onu do SGP', async () => {
    const data = dataset();
    data.cliente_contrato[1].dia_vencimento = '15';
    const g = gateway({}, data);
    const result = await g.handle('/api/ura/clientes/', { limit: 100, offset: 0 });
    const maria = result.clientes.find(c => c.cpfcnpj === '12345678909');
    const [c100, c101] = maria.contratos;
    assert.deepEqual(c100.servicos, [{ login: 'maria.fibra', onu: { olt_id: '3', olt_nome: 'OLT BOMBA', slot: '1', pon: '4' } }]);
    assert.equal(c100.vencimento, 10, 'dia da fatura em aberto na janela');
    assert.deepEqual(c101.servicos, [], 'contrato sem login');
    assert.equal(c101.vencimento, 15, 'campo de dia de cobrança do contrato tem prioridade');
    const empresa = result.clientes.find(c => c.cpfcnpj === '12345678000195').contratos[0];
    assert.deepEqual(empresa.servicos, [{ login: 'empresa.fibra', onu: { olt_id: '3', olt_nome: 'OLT BOMBA', slot: null, pon: null } }]);
    const perTable = table => g.calls.filter(c => c.table === table).length;
    assert.deepEqual(['radusuarios', 'radpop_radio_cliente_fibra', 'radpop_radio', 'fn_areceber'].map(perTable), [1, 1, 1, 1], 'uma chamada em lote por tabela');
    assert.ok(g.calls.filter(c => ['radusuarios', 'radpop_radio_cliente_fibra'].includes(c.table)).every(c => c.body.oper === 'IN'));
});

test('clientes (sync): sem permissão nas tabelas de rede/faturas, sincroniza sem enriquecer', async () => {
    const denied = { type: 'error', message: 'Você não tem permissão para acessar o recurso' };
    const g = gateway({ onCall: table => (['radusuarios', 'fn_areceber'].includes(table) ? denied : undefined) });
    const result = await g.handle('/api/ura/clientes/', { limit: 100, offset: 0 });
    assert.equal(result.clientes.length, 2);
    const contrato = result.clientes[0].contratos[0];
    assert.deepEqual(contrato.servicos, []);
    assert.equal(contrato.vencimento, null);
    const partial = gateway({ onCall: table => (table === 'radpop_radio_cliente_fibra' ? denied : undefined) });
    const withLogins = (await partial.handle('/api/ura/clientes/', { limit: 100, offset: 0 })).clientes[0].contratos[0];
    assert.deepEqual(withLogins.servicos, [{ login: 'maria.fibra', onu: null }]);
});

const FAKE_PDF = Buffer.concat([Buffer.from('%PDF-1.7\n'), Buffer.alloc(64, 1), Buffer.from('\n%%EOF')]);
const boletoGateway = (reply = FAKE_PDF.toString('base64')) => gateway({ onCall: table => (table === 'get_boleto' ? (typeof reply === 'function' ? reply() : reply) : undefined) });

test('boletoPdf: confere dono e situação no fn_areceber e decodifica o base64 do get_boleto', async () => {
    const g = boletoGateway();
    const { pdf, faturaId } = await g.boletoPdf({ cpfcnpj: '12345678909', faturaId: '901', contrato: '100' });
    assert.equal(faturaId, '901');
    assert.deepEqual(pdf, FAKE_PDF);
    const emit = g.calls.find(c => c.table === 'get_boleto');
    assert.deepEqual(emit.body, { boletos: '901', juro: 'N', multa: 'N', atualiza_boleto: 'N', tipo_boleto: 'arquivo', base64: 'S' });
    assert.equal(emit.action, 'listar', 'get_boleto é leitura: nunca sem ixcsoft listar');
    const lookup = g.calls.find(c => c.table === 'fn_areceber');
    assert.equal(lookup.body.qtype, 'fn_areceber.id');
    assert.equal(lookup.body.query, '901');
});

test('boletoPdf: fatura de outro cliente, de outro contrato, paga ou inexistente não chega ao get_boleto', async () => {
    for (const [body, code] of [
        [{ cpfcnpj: '12345678909', faturaId: '905' }, 'invoice-not-found'], // fatura do cliente 2
        [{ cpfcnpj: '12345678909', faturaId: '901', contrato: '101' }, 'invoice-not-found'],
        [{ cpfcnpj: '12345678909', faturaId: '903' }, 'invoice-not-open'],
        [{ cpfcnpj: '12345678909', faturaId: '999' }, 'invoice-not-found'],
        [{ cpfcnpj: '00000000000', faturaId: '901' }, 'invoice-not-found'],
    ]) {
        const g = boletoGateway();
        await assert.rejects(g.boletoPdf(body), error => error.status === 404 && error.code === code, JSON.stringify(body));
        assert.equal(g.calls.some(c => c.table === 'get_boleto'), false);
    }
    await assert.rejects(boletoGateway().boletoPdf({ cpfcnpj: '12345678909', faturaId: '9 OR 1' }), { status: 400 });
});

test('boletoPdf: erro do IXC (JSON ou dentro de HTML) vira "não disponível" sem expor a mensagem', async () => {
    await assert.rejects(boletoGateway({ type: 'error', message: 'Carteira sem permissão' }).boletoPdf({ cpfcnpj: '12345678909', faturaId: '901' }),
        error => error.status === 404 && error.code === 'boleto-unavailable' && !/Carteira/.test(error.message));
    const html = '<!DOCTYPE html><html><body><script>x()</script>Boleto id: 901 API retornou: Negócio: Data de vencimento tem que ser posterior ou igual a data atual. {"type":"error","message":"Boleto id: 901 API retornou: Neg\\u00f3cio: Data de vencimento"}</body></html>';
    await assert.rejects(boletoGateway(html).boletoPdf({ cpfcnpj: '12345678909', faturaId: '901' }), { status: 404, code: 'boleto-overdue' });
    assert.match(ixcErrorText(html), /Negócio: Data de vencimento/);
    assert.equal(ixcErrorText(FAKE_PDF.toString('base64')), '');
});

test('boletoPdf: rejeita o que não é PDF e arquivo acima do teto', async () => {
    await assert.rejects(boletoGateway(Buffer.from('<html>oi</html>').toString('base64')).boletoPdf({ cpfcnpj: '12345678909', faturaId: '901' }), { status: 502 });
    await assert.rejects(boletoGateway('não é base64!').boletoPdf({ cpfcnpj: '12345678909', faturaId: '901' }), { status: 502 });
    await assert.rejects(boletoGateway({ total: 0 }).boletoPdf({ cpfcnpj: '12345678909', faturaId: '901' }), { status: 502 });
    const huge = Buffer.concat([Buffer.from('%PDF-'), Buffer.alloc(MAX_BOLETO_BYTES)]).toString('base64');
    assert.throws(() => decodeBoletoPdf(huge), { status: 502 });
    assert.deepEqual(decodeBoletoPdf(`data:application/pdf;base64,${FAKE_PDF.toString('base64').replace(/(.{20})/g, '$1\n')}`), FAKE_PDF);
    assert.deepEqual(decodeBoletoPdf({ base64: FAKE_PDF.toString('base64') }), FAKE_PDF);
});
