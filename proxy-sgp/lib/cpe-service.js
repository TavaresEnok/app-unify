'use strict';

// CPE Manager do SGP (TR-069 via GenieACS/Flashman configurado no próprio SGP).
// - As rotas /api/cpemanager/servico/{id}/... recebem o ID do SERVIÇO, não do
//   contrato. O ID vem de /api/ura/clientes/?contrato=, que também confirma que
//   o contrato pertence ao CPF/CNPJ autenticado.
// - A resposta real é { cpe_manager, result: { interface_info, lan_devices, ... } }.

const digits = (value) => String(value ?? '').replace(/\D/g, '');

function cpeError(message, status) {
  return Object.assign(new Error(message), { status, publicMessage: message });
}

function pickInternetServiceId(clientesResponse, contratoId, cpfCnpj) {
  const clientes = Array.isArray(clientesResponse?.clientes) ? clientesResponse.clientes : [];
  const cpf = digits(cpfCnpj);
  for (const cliente of clientes) {
    if (!cpf || digits(cliente?.cpfcnpj) !== cpf) continue;
    const contrato = (cliente.contratos || []).find((c) => String(c?.id) === String(contratoId));
    if (!contrato) continue;
    const internet = (contrato.servicos || []).filter((s) => s && s.id != null && String(s.tipo || '').toLowerCase() === 'internet');
    const chosen = internet.find((s) => String(s.status || '').toLowerCase() === 'ativo') || internet[0];
    if (chosen) return String(chosen.id);
    throw cpeError('Este contrato não possui serviço de internet com roteador gerenciado.', 404);
  }
  throw cpeError('Contrato não encontrado para este assinante.', 404);
}

function bandOf(value) {
  const text = String(value || '').toLowerCase();
  return text.includes('5') ? '5GHz' : '2.4GHz';
}

function cleanPassword(value, showPasswords) {
  return showPasswords && typeof value === 'string' && value ? value : undefined;
}

function networksFromResult(result, showPasswords) {
  const interfaces = Array.isArray(result?.interface_info?.wlan_interfaces) ? result.interface_info.wlan_interfaces : null;
  const source = interfaces || (Array.isArray(result?.virtual_wifi) ? result.virtual_wifi : []);
  const rows = source.map((w) => ({
    id: String(w.chave ?? w.id ?? ''),
    ssid: String(w.ssid ?? ''),
    frequency: bandOf(w.frequency),
    enabled: w.enabled === true && w.radio_enabled !== false,
    channel: w.channel != null ? String(w.channel) : 'auto',
    mode: w.mode || '',
    bandwidth: w.bandwidth ?? null,
    password: cleanPassword(w.password, showPasswords),
  }));

  // Sem interface_info, as redes principais vêm em campos soltos.
  if (!interfaces) {
    for (const [suffix, freq] of [['', '2.4GHz'], ['_5ghz', '5GHz']]) {
      const id = result?.[`wifi_id${suffix}`];
      if (id == null || rows.some((r) => r.id === String(id))) continue;
      rows.unshift({
        id: String(id),
        ssid: String(result[`wifi_ssid${suffix}`] ?? ''),
        frequency: freq,
        enabled: result[`wifi_enabled${suffix}`] === true,
        channel: result[`wifi_channel${suffix}`] != null ? String(result[`wifi_channel${suffix}`]) : 'auto',
        mode: result[`wifi_mode${suffix}`] || '',
        bandwidth: result[`wifi_bandwidth${suffix}`] ?? null,
        password: cleanPassword(result[`wifi_password${suffix}`], showPasswords),
      });
    }
  }
  return rows.filter((r) => r.id).map((r) => (r.password === undefined ? (({ password, ...rest }) => rest)(r) : r));
}

function hostsFromResult(result) {
  const byMac = new Map();
  for (const d of Array.isArray(result?.lan_devices) ? result.lan_devices : []) {
    const mac = String(d?.mac || '').toUpperCase();
    if (!mac) continue;
    const prev = byMac.get(mac) || { mac, hostname: '', ip: '', interfaceType: 'ethernet', rssiDbm: null };
    const path = String(d.path || '');
    const wlan = /WLANConfiguration\.(\d+)/.exec(path);
    const iface = wlan
      ? (result?.interface_info?.wlan_interfaces || []).find((w) => String(w.path || '').endsWith(`WLANConfiguration.${wlan[1]}`))
      : null;
    const signal = Number(d.wifi_signal);
    byMac.set(mac, {
      mac,
      hostname: prev.hostname || String(d.dhcp_name || ''),
      ip: prev.ip || String(d.ip || ''),
      interfaceType: wlan ? (bandOf(iface?.frequency) === '5GHz' ? 'wifi_5g' : 'wifi_2g') : prev.interfaceType,
      rssiDbm: d.wifi_signal !== '' && Number.isFinite(signal) ? signal : prev.rssiDbm,
    });
  }
  return [...byMac.values()];
}

function deviceFromResult(result, manager) {
  const uptime = Number(result?.wan_up_time);
  return {
    manager: String(manager?.nome || ''),
    manufacturer: String(result?.manufacturer || ''),
    model: String(result?.model || result?.product_class || ''),
    firmware: String(result?.version || ''),
    wanIp: String(result?.wan_ip || result?.ip || ''),
    wanUptimeSeconds: Number.isFinite(uptime) && uptime >= 0 ? uptime : null,
    lastBoot: typeof result?.lastboot_date === 'string' ? result.lastboot_date : null,
    hosts: hostsFromResult(result),
  };
}

// Converte a resposta do CPE Manager em { networks, device }. Respostas antigas
// (lista direta, { data }, { wifis }) continuam aceitas, sem dados do aparelho.
function normalizeCpeWifiResponse(response, legacyParser) {
  if (response && typeof response === 'object' && !Array.isArray(response) && response.result && typeof response.result === 'object') {
    const showPasswords = response.cpe_manager?.exibir_wifi_senha === true;
    return { networks: networksFromResult(response.result, showPasswords), device: deviceFromResult(response.result, response.cpe_manager) };
  }
  if (response && typeof response === 'object' && !Array.isArray(response) && typeof response.msg === 'string' && !response.data && !response.wifis) {
    // Ex.: "Equipamento não encontrado.", "Gerenciador CPE não definido para este serviço."
    throw cpeError(response.msg, 422);
  }
  return { networks: legacyParser(response), device: null };
}

module.exports = { pickInternetServiceId, normalizeCpeWifiResponse, hostsFromResult };
