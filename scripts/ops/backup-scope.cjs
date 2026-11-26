const ephemeral = new Set(['function_requests', 'function_responses', 'function_locks', 'audit_logs', 'maintenance_logs']);
// Cópias legadas de dados de assinantes (CPF, endereço, faturas) e segredos de
// integração: a fonte oficial agora é o PostgreSQL. Ficam fora do export diário
// (LGPD: menos cópias espalhadas) e só entram no completo de domingo até o
// Firestore legado ser desligado.
const legacySensitive = new Set(['clientes', 'secrets']);
function firestoreScope(rootCollections, { full = false } = {}) {
    if (full) return [];
    // Collection-group export includes nested documents with these collection IDs.
    return [...new Set([...rootCollections, 'messages', 'backups', 'migration_backups', 'incidents', 'diagnostic_results'])]
        .filter(name => !ephemeral.has(name) && !legacySensitive.has(name)).sort();
}
module.exports = { firestoreScope };
