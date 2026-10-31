'use strict';
const { timingSafeEqual } = require('crypto');
function secretMatches(provided, configured) {
    if (typeof provided !== 'string' || typeof configured !== 'string') return false;
    // Secret Manager imports made with echo may include a trailing line break.
    // Normalize only the internal service token, never subscriber passwords.
    const a = Buffer.from(provided.trim());
    const b = Buffer.from(configured.trim());
    return a.length > 0 && b.length > 0 && a.length === b.length && timingSafeEqual(a, b);
}
module.exports = { secretMatches };
