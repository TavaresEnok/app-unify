const fs = require('node:fs');
const path = require('node:path');
const root = path.join(process.env.PAINEL_BACKUP_DIR || '/home/app/.backups/painel_provedores', 'runs');
try {
    const runs = fs.readdirSync(root).filter(name => /^\d{8}T\d{6}Z-\d+$/.test(name)).sort().reverse();
    const name = runs.find(name => fs.existsSync(path.join(root, name, 'manifest.json')));
    if (!name) throw new Error('Nenhum backup externo concluído.');
    const manifest = JSON.parse(fs.readFileSync(path.join(root, name, 'manifest.json'), 'utf8'));
    const ageHours = (Date.now() - Date.parse(manifest.completedAt)) / 3600000;
    if (!Number.isFinite(ageHours) || ageHours > 26) throw new Error('Backup externo atrasado: mais de 26 horas.');
    console.log(JSON.stringify({ service: 'backup', status: 'ok', completedAt: manifest.completedAt, ageHours: Math.round(ageHours * 100) / 100 }));
} catch (error) {
    console.error(JSON.stringify({ service: 'backup', status: 'unavailable', message: error.message })); process.exitCode = 1;
}
