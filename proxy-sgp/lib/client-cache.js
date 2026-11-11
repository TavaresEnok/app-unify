'use strict';
let ready;
function ensureClientCache(pool) {
    if (!ready) ready = pool.query(`CREATE TABLE IF NOT EXISTS sgp_clients (
        provider_id TEXT NOT NULL, client_id TEXT NOT NULL, nome TEXT NOT NULL DEFAULT '',
        cpfcnpj TEXT NOT NULL, contratos JSONB NOT NULL DEFAULT '[]',
        PRIMARY KEY(provider_id, client_id)
    )`).then(() => pool.query('CREATE INDEX IF NOT EXISTS sgp_clients_name ON sgp_clients(provider_id,nome,client_id)')).catch(error => { ready = null; throw error; });
    return ready;
}
module.exports = { ensureClientCache };
