'use strict';
// Leitura ao vivo da ONU na OLT (GET /api/fttx/onu/{id}/info/ do SGP). O texto
// varia por fabricante: só campos conhecidos são extraídos (lista fechada) e o
// resto é descartado. Nunca devolve serial, MAC, perfis ou senhas.

function toNumber(value) {
    const match = String(value ?? '').replace(',', '.').match(/-?\d+(?:\.\d+)?/);
    if (!match) return null;
    const n = Number(match[0]);
    return Number.isFinite(n) ? n : null;
}

function parseDuration(value) {
    const text = String(value || '').toLowerCase();
    if (!text) return null;
    let total = 0; let found = false;
    const units = [[/(\d+)\s*(?:d|day|days|dia|dias)(?:\(s\))?\b/, 86400], [/(\d+)\s*(?:h|hour|hours|hora|horas)(?:\(s\))?\b/, 3600],
        [/(\d+)\s*(?:m|min|minute|minutes|minuto|minutos)(?:\(s\))?\b/, 60], [/(\d+)\s*(?:s|sec|second|seconds|segundo|segundos)(?:\(s\))?\b/, 1]];
    for (const [re, mult] of units) {
        const m = text.match(re);
        if (m) { total += Number(m[1]) * mult; found = true; }
    }
    return found ? total : null;
}

function parseTime(value) {
    const raw = String(value || '').trim();
    if (!raw || /^-+$/.test(raw)) return null;
    const m = raw.match(/^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})(?:\s*([+-]\d{2}:?\d{2}|Z))?/);
    if (!m) return null;
    const zone = m[3] ? (m[3] === 'Z' ? 'Z' : m[3].replace(/^([+-]\d{2})(\d{2})$/, '$1:$2')) : '-03:00';
    const ms = Date.parse(`${m[1]}T${m[2]}${zone}`);
    return Number.isFinite(ms) ? new Date(ms).toISOString() : null;
}

const FIELDS = [
    ['runState', /^run state$/i],
    ['onlineDuration', /online duration/i],
    ['lastUpTime', /^last up time$/i],
    ['lastDownTime', /^last down time$/i],
    ['lastDownCause', /^last down cause$/i],
    ['lastDyingGasp', /^last dying gasp time$/i],
    ['distance', /distance/i],
    ['oltRx', /^olt rx/i],
    ['rx', /^rx optical power/i],
    ['tx', /^tx optical power/i],
    ['temperature', /^temperature/i],
];

function downCauseLabel(value) {
    const text = String(value || '').trim();
    if (!text || /^-+$/.test(text)) return null;
    if (/dying[- ]?gasp/i.test(text)) return 'Falta de energia no equipamento';
    if (/\blosi?\b|loss of signal|lofi?\b/i.test(text)) return 'Perda de sinal na fibra';
    if (/deactiv|deregist|reset|reboot/i.test(text)) return 'Equipamento reiniciado ou desativado';
    return text.slice(0, 60);
}

function parseOnuInfo(payload, now = new Date()) {
    const text = typeof payload === 'string' ? payload
        : payload && typeof payload.result === 'string' ? payload.result
            : payload && typeof payload.info === 'string' ? payload.info : '';
    const found = {};
    for (const line of text.split(/\r?\n/)) {
        const m = line.match(/^\s*([^:]{2,60}?)\s*:\s*(.*?)\s*$/);
        if (!m) continue;
        const [, key, value] = m;
        for (const [name, re] of FIELDS) {
            if (found[name] === undefined && re.test(key.trim())) { found[name] = value; break; }
        }
    }
    if (!Object.keys(found).length) return null;
    const runState = String(found.runState || '').toLowerCase();
    const online = runState ? /online|up|working/.test(runState) && !/offline/.test(runState) : null;
    const durationSeconds = parseDuration(found.onlineDuration);
    const lastUp = parseTime(found.lastUpTime);
    const onlineSince = online ? (durationSeconds != null ? new Date(now.getTime() - durationSeconds * 1000).toISOString() : lastUp) : null;
    return {
        online,
        onlineSince,
        onlineDurationSeconds: online ? durationSeconds : null,
        lastDownAt: parseTime(found.lastDownTime),
        lastDownCause: downCauseLabel(found.lastDownCause),
        lastDyingGaspAt: parseTime(found.lastDyingGasp),
        distanceMeters: toNumber(found.distance),
        rxPowerDbm: toNumber(found.rx),
        txPowerDbm: toNumber(found.tx),
        oltRxPowerDbm: toNumber(found.oltRx),
        temperatureC: toNumber(found.temperature),
        source: 'olt',
        fetchedAt: now.toISOString(),
    };
}

module.exports = { parseOnuInfo, parseDuration, parseTime, downCauseLabel };
