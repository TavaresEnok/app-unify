function wifiError(message, status = 502) {
    return Object.assign(new Error(message), { status, publicMessage: message });
}
function assertWifiResponse(response) {
    if (response == null || response === false || response.error || response.success === false || response.status === false) {
        throw wifiError('O equipamento não confirmou a operação de Wi-Fi.');
    }
    return response;
}
function wifiNetworks(response) {
    assertWifiResponse(response);
    const networks = Array.isArray(response) ? response : response.data ?? response.wifis;
    if (!Array.isArray(networks) || networks.some(item => !item || typeof item !== 'object' || Array.isArray(item))) {
        throw wifiError('Resposta de Wi-Fi inválida recebida do equipamento.');
    }
    return networks;
}
function preservedWifiPassword(networks, wifiId) {
    const network = networks.find(item => String(item.id ?? item.wifi_id) === String(wifiId));
    const password = network?.password ?? network?.senha;
    // Masked or absent values must never overwrite the router's password.
    if (typeof password !== 'string' || !password || /^[*•]+$/.test(password)) {
        throw wifiError('Informe a senha do Wi-Fi para salvar a alteração. O equipamento não disponibiliza a senha atual.', 422);
    }
    return password;
}
module.exports = { assertWifiResponse, wifiNetworks, preservedWifiPassword };
