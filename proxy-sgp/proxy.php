<?php
$log_file = 'proxy_debug.log';
file_put_contents($log_file, "");

function write_log($message) {
    global $log_file;
    file_put_contents($log_file, date('Y-m-d H:i:s') . " - " . print_r($message, true) . "\n", FILE_APPEND);
}

function is_sensitive_key($key) {
    $key = strtolower((string)$key);
    $patterns = ['senha', 'password', 'token', 'authorization', 'cpf', 'cnpj', 'apitoken', 'codigopix', 'linha_digitavel'];
    foreach ($patterns as $pattern) {
        if (strpos($key, $pattern) !== false) return true;
    }
    return false;
}

function mask_string($value) {
    $value = (string)$value;
    if (strlen($value) <= 4) return '***';
    return substr($value, 0, 2) . '***' . substr($value, -2);
}

function sanitize_sensitive($value, $currentKey = '') {
    if (is_array($value)) {
        $sanitized = [];
        foreach ($value as $k => $v) {
            $sanitized[$k] = sanitize_sensitive($v, (string)$k);
        }
        return $sanitized;
    }

    if (is_sensitive_key($currentKey)) {
        if (is_string($value) || is_numeric($value)) {
            return mask_string($value);
        }
        return '***';
    }

    return $value;
}

write_log("--- Script PHP iniciado ---");
$input = file_get_contents('php://stdin');
write_log("Dados recebidos do Node.js (sanitizados).");

$data = json_decode($input, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    write_log("ERRO FATAL: JSON inválido.");
    http_response_code(500);
    echo json_encode(['error' => 'Input JSON inválido para o PHP.']);
    exit;
}

$sgp_api_url = $data['params']['url'];
unset($data['params']['url']);
$params = $data['params'];

write_log("URL da API do SGP: " . $sgp_api_url);
write_log("Parâmetros para a API (sanitizados): " . print_r(sanitize_sensitive($params), true));

// ===== CORREÇÃO DE LÓGICA INTELIGENTE APLICADA AQUI =====
// Lista de partes de URL que sabemos que exigem JSON
$json_endpoints = [
    '/api/ura/titulos/',
    '/api/ura/liberacaopromessa/'
];

$use_json = false;
foreach ($json_endpoints as $endpoint) {
    if (strpos($sgp_api_url, $endpoint) !== false) {
        $use_json = true;
        break;
    }
}

if ($use_json) {
    write_log("Detectado endpoint JSON, usando Content-Type: application/json");
    $post_data = json_encode($params);
    $headers = array('Content-Type: application/json');
} else {
    // Para todos os outros endpoints (como /ws/ ou /api/central/), usa o formato padrão
    write_log("Endpoint padrão detectado, usando Content-Type: application/x-www-form-urlencoded");
    $post_data = http_build_query($params);
    $headers = array('Content-Type: application/x-www-form-urlencoded');
}
// ===== FIM DA CORREÇÃO =====

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $sgp_api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $post_data);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

write_log("cURL concluído. Código HTTP: " . $http_code);
write_log("Resposta recebida do SGP (bytes): " . strlen((string)$response));

if ($response === false) {
    http_response_code(500);
    echo json_encode(['error' => 'Erro no cURL do PHP', 'details' => $curl_error]);
} else {
    http_response_code($http_code);
    echo $response;
}

write_log("--- Script PHP finalizado ---");
?>
