'use strict';
const SENSITIVE = /senha|password|token|secret|authorization/i;
function sanitize(value) {
    if (Array.isArray(value)) return value.map(sanitize);
    if (!value || typeof value !== 'object') return value;
    return Object.fromEntries(Object.entries(value).filter(([key]) => !SENSITIVE.test(key)).map(([key, value]) => [key, sanitize(value)]));
}
module.exports = { sanitize };
