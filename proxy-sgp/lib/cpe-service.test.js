const test = require('node:test');
const assert = require('node:assert/strict');
const { pickInternetServiceId, normalizeCpeWifiResponse } = require('./cpe-service');
const { wifiNetworks } = require('./wifi-response');

const clientes = { clientes: [{ cpfcnpj: '111.222.333-44', contratos: [{ id: 3894, servicos: [
  { id: 293, tipo: 'tv', status: 'Ativo' },
  { id: 3001, tipo: 'internet', status: 'Inativo' },
  { id: 3585, tipo: 'internet', status: 'Ativo' },
] }] }] };

test('usa o ID do serviço de internet ativo, não o do contrato', () => {
  assert.equal(pickInternetServiceId(clientes, '3894', '11122233344'), '3585');
});

test('não resolve serviço de contrato de outro CPF nem contrato sem internet', () => {
  assert.throws(() => pickInternetServiceId(clientes, 3894, '99999999999'), { status: 404 });
  assert.throws(() => pickInternetServiceId(clientes, 1, '11122233344'), { status: 404 });
  const semInternet = { clientes: [{ cpfcnpj: '11122233344', contratos: [{ id: 5, servicos: [{ id: 9, tipo: 'tv' }] }] }] };
  assert.throws(() => pickInternetServiceId(semInternet, 5, '11122233344'), { status: 404 });
});

// Formato real do CPE Manager do SGP (GenieACS), com valores sintéticos.
const real = {
  cpe_manager: { exibir_wifi_senha: false, id: 2, nome: 'genieacs' },
  result: {
    manufacturer: 'NV21', model: 'NV21 - X1', version: 'V7.0.1', wan_ip: '10.0.0.2', wan_up_time: 30718,
    lastboot_date: '2026-03-16T18:52:51Z', wifi_id: '1-6', wifi_ssid: 'Casa', wifi_password: 'segredo-nao-exibir',
    virtual_wifi: [{ id: '1-2', ssid: 'Guest', frequency: '5GHz', enabled: false, channel: 44, password: 'x' }],
    interface_info: { wlan_interfaces: [
      { chave: '1-1', ssid: 'Casa-5G', frequency: '5GHz', enabled: true, radio_enabled: true, channel: 44, mode: 'ac', password: 'p', path: 'IGD.LANDevice.1.WLANConfiguration.1' },
      { chave: '1-6', ssid: 'Casa', frequency: '2.4GHz', enabled: true, radio_enabled: true, channel: 11, mode: '', password: '', path: 'IGD.LANDevice.1.WLANConfiguration.6' },
      { chave: '1-7', ssid: 'AP-1', frequency: '2.4GHz', enabled: false, radio_enabled: false, channel: 11, path: 'IGD.LANDevice.1.WLANConfiguration.7' },
    ] },
    lan_devices: [
      { dhcp_name: 'celular', ip: '192.168.1.8', mac: 'aa:bb:cc:00:00:01' },
      { mac: 'aa:bb:cc:00:00:01', ip: '192.168.1.8', dhcp_name: '', wifi_signal: '', path: 'IGD.LANDevice.1.WLANConfiguration.6.AssociatedDevice.1' },
      { mac: 'aa:bb:cc:00:00:02', ip: '192.168.1.3', dhcp_name: '', wifi_signal: '-61', path: 'IGD.LANDevice.1.WLANConfiguration.1.AssociatedDevice.1' },
    ],
  },
};

test('normaliza a resposta real: redes, aparelho e hosts sem duplicar', () => {
  const { networks, device } = normalizeCpeWifiResponse(real, wifiNetworks);
  assert.deepEqual(networks.map((n) => [n.id, n.ssid, n.frequency, n.enabled, n.channel, n.mode]), [
    ['1-1', 'Casa-5G', '5GHz', true, '44', 'ac'], ['1-6', 'Casa', '2.4GHz', true, '11', ''],
  ], 'rede virtual desativada (1-7) não aparece');
  assert.ok(networks.every((n) => !('password' in n)), 'exibir_wifi_senha=false nunca expõe senha');
  assert.deepEqual([device.manager, device.manufacturer, device.firmware, device.wanIp, device.wanUptimeSeconds], ['genieacs', 'NV21', 'V7.0.1', '10.0.0.2', 30718]);
  assert.deepEqual(device.hosts, [
    { mac: 'AA:BB:CC:00:00:01', hostname: 'celular', ip: '192.168.1.8', interfaceType: 'wifi_2g', rssiDbm: null },
    { mac: 'AA:BB:CC:00:00:02', hostname: '', ip: '192.168.1.3', interfaceType: 'wifi_5g', rssiDbm: -61 },
  ]);
});

test('passwordReadable acompanha exibir_wifi_senha', () => {
  assert.equal(normalizeCpeWifiResponse(real, wifiNetworks).passwordReadable, false);
  assert.equal(normalizeCpeWifiResponse(real, wifiNetworks).device.passwordReadable, false);
  assert.equal(normalizeCpeWifiResponse({ ...real, cpe_manager: { exibir_wifi_senha: true } }, wifiNetworks).passwordReadable, true);
});

test('redes virtuais só aparecem quando o template do SGP permite', () => {
  const shown = normalizeCpeWifiResponse({ ...real, cpe_template: { exibir: { wifi_virtual: true } } }, wifiNetworks);
  assert.deepEqual(shown.networks.map((n) => n.id), ['1-1', '1-6', '1-7']);
  const allOff = { ...real, result: { ...real.result, wifi_id: '1-6', interface_info: { wlan_interfaces: real.result.interface_info.wlan_interfaces.map((w) => ({ ...w, enabled: false })) } } };
  assert.deepEqual(normalizeCpeWifiResponse(allOff, wifiNetworks).networks.map((n) => n.id), ['1-1', '1-6'], 'mantém a principal de cada banda');
});

test('exibe senha só quando o SGP permite', () => {
  const { networks } = normalizeCpeWifiResponse({ ...real, cpe_manager: { exibir_wifi_senha: true } }, wifiNetworks);
  assert.equal(networks.find((n) => n.id === '1-1').password, 'p');
  assert.equal('password' in networks.find((n) => n.id === '1-6'), false);
});

test('sem interface_info usa virtual_wifi + redes principais', () => {
  const { interface_info, ...result } = real.result;
  const { networks } = normalizeCpeWifiResponse({ cpe_manager: {}, result }, wifiNetworks);
  assert.deepEqual(networks.map((n) => n.id), ['1-6', '1-2']);
});

test('mensagens do SGP viram erro claro; formatos antigos continuam aceitos', () => {
  assert.throws(() => normalizeCpeWifiResponse({ msg: 'Equipamento não encontrado.' }, wifiNetworks), { status: 422, publicMessage: 'Equipamento não encontrado.' });
  assert.deepEqual(normalizeCpeWifiResponse({ data: [{ id: '2' }] }, wifiNetworks), { networks: [{ id: '2' }], device: null });
});
