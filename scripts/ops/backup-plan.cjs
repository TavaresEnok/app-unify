// Regras do que entra em cada backup (puras, para testar sem nuvem).
function weekdayInFortaleza(date) {
    return new Intl.DateTimeFormat('en-US', { timeZone: 'America/Fortaleza', weekday: 'short' }).format(date);
}
// Export do Firestore/Firebase Auth legado: ligado enquanto os APKs antigos
// existem; PAINEL_BACKUP_FIRESTORE=false desliga quando o Firebase sair.
function legacyExportEnabled(env = process.env) {
    return String(env.PAINEL_BACKUP_FIRESTORE ?? 'true').trim().toLowerCase() !== 'false';
}
function isFullFirestoreDay(date = new Date(), env = process.env) {
    return env.PAINEL_BACKUP_FIRESTORE_FULL === 'true' || weekdayInFortaleza(date) === 'Sun';
}
module.exports = { legacyExportEnabled, isFullFirestoreDay, weekdayInFortaleza };
