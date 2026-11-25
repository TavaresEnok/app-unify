'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createIxcGateway, formatCpfCnpj, ixcDate, ixcHeaders, ixcUrl, contractStatusLabel } = require('./ixc-gateway');
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
        const cmp = (value, op, p) => op === '=' ? String(value) === String(p) : op === '>=' ? String(value) >= String(p) : op === '<' ? String(value) < String(p) : false;
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
    assert.equal(g.calls.some(c => c.table === 'fn_areceber'), false, 'sync não consulta faturas');
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
