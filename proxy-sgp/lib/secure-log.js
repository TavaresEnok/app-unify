const SENSITIVE_KEY_PATTERNS = [
    'senha', 'password', 'token', 'authorization', 'cpf', 'cnpj',
    'apiToken', 'codigoPix', 'linha_digitavel',
];

function isSensitiveKey(key = '') {
    const normalized = String(key).toLowerCase();
    return SENSITIVE_KEY_PATTERNS.some((pattern) => normalized.includes(pattern.toLowerCase()));
}

function maskString(value) {
    if (typeof value !== 'string') return value;
    if (value.length <= 4) return '***';
    return `${value.slice(0, 2)}***${value.slice(-2)}`;
}

function maskCpfCnpj(value) {
    const digits = String(value || '').replace(/\D/g, '');
    if (!digits) return 'N/A';
    if (digits.length <= 4) return '***';
    return `${digits.slice(0, 2)}***${digits.slice(-2)}`;
}

function sanitizeForLog(value, currentKey = '') {
    if (value === null || value === undefined) return value;
    if (Array.isArray(value)) return value.map((item) => sanitizeForLog(item, currentKey));
    if (typeof value === 'object') {
        return Object.fromEntries(
            Object.entries(value).map(([key, item]) => [key, sanitizeForLog(item, key)]),
        );
    }
    if (!isSensitiveKey(currentKey)) return value;
    if (typeof value === 'string') return maskString(value);
    if (typeof value === 'number') return -1;
    return '***';
}

function secureLog(prefix, payload) {
    if (payload === undefined) return console.log(prefix);
    console.log(prefix, sanitizeForLog(payload));
}

module.exports = { maskCpfCnpj, sanitizeForLog, secureLog };
