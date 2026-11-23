'use strict';

/** Monetary values from SGP may use decimal dots or Brazilian separators. */
function invoiceAmount(value) {
    if (typeof value === 'number') return Number.isFinite(value) ? value : null;
    if (typeof value !== 'string') return null;
    let text = value.trim().replace(/^R\$\s*/, '');
    if (/^-?(?:\d+|\d{1,3}(?:\.\d{3})+),\d{1,2}$/.test(text)) {
        text = text.replace(/\./g, '').replace(',', '.');
    } else if (!/^-?\d+(?:\.\d+)?$/.test(text)) {
        return null;
    }
    const result = Number(text);
    return Number.isFinite(result) ? result : null;
}

module.exports = { invoiceAmount };
