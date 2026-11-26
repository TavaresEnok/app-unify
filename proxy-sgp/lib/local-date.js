'use strict';
// Datas de negócio no fuso do provedor (containers rodam em UTC).
const TIME_ZONE = 'America/Fortaleza';

function localParts(now = new Date(), timeZone = TIME_ZONE) {
    const parts = Object.fromEntries(new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' })
        .formatToParts(now).filter((p) => p.type !== 'literal').map((p) => [p.type, p.value]));
    return { year: Number(parts.year), month: Number(parts.month), day: Number(parts.day) };
}

function localIsoDate(now = new Date(), timeZone = TIME_ZONE) {
    return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
}

module.exports = { localParts, localIsoDate, TIME_ZONE };
