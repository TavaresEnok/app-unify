const fs = require('node:fs');
const path = require('node:path');
const MAX_AGE_HOURS = 26;
// Lê o último backup concluído (com manifest) e diz se está em dia.
function evaluateBackup(root, now = Date.now()) {
    const runs = fs.readdirSync(root).filter(name => /^\d{8}T\d{6}Z-\d+$/.test(name)).sort().reverse();
    const name = runs.find(name => fs.existsSync(path.join(root, name, 'manifest.json')));
    if (!name) return { service: 'backup', status: 'unavailable', message: 'Nenhum backup externo concluído.' };
    const manifest = JSON.parse(fs.readFileSync(path.join(root, name, 'manifest.json'), 'utf8'));
    const ageHours = (now - Date.parse(manifest.completedAt)) / 3600000;
    if (!Number.isFinite(ageHours) || ageHours > MAX_AGE_HOURS) {
        return { service: 'backup', status: 'unavailable', runId: name, message: `Backup externo atrasado: mais de ${MAX_AGE_HOURS} horas.` };
    }
    const result = { service: 'backup', status: 'ok', runId: name, completedAt: manifest.completedAt, ageHours: Math.round(ageHours * 100) / 100 };
    if (Array.isArray(manifest.warnings) && manifest.warnings.length) {
        return { ...result, status: 'degraded', message: `Backup com avisos: ${manifest.warnings.join('; ')}` };
    }
    return result;
}
function backupRoot(env = process.env) {
    return path.join(env.PAINEL_BACKUP_DIR || '/home/app/.backups/painel_provedores', 'runs');
}
if (require.main === module) {
    let result;
    try { result = evaluateBackup(backupRoot()); } catch (error) { result = { service: 'backup', status: 'unavailable', message: error.message }; }
    if (result.status === 'ok') console.log(JSON.stringify(result));
    else { console.error(JSON.stringify(result)); process.exitCode = 1; }
}
module.exports = { evaluateBackup, backupRoot, MAX_AGE_HOURS };
