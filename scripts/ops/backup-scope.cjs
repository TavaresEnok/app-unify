const ephemeral = new Set(['function_requests', 'function_responses', 'function_locks', 'audit_logs', 'maintenance_logs']);
function firestoreScope(rootCollections, { full = false } = {}) {
    if (full) return [];
    // Collection-group export includes nested documents with these collection IDs.
    return [...new Set([...rootCollections, 'clientes', 'secrets', 'messages', 'backups', 'migration_backups', 'incidents', 'diagnostic_results'])]
        .filter(name => !ephemeral.has(name)).sort();
}
module.exports = { firestoreScope };
