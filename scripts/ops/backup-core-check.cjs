// Confere a contagem das tabelas principais de um dump restaurado.
// Uso: <json de contagens> | node backup-core-check.cjs <logical|physical>
const REQUIRED = ['providers', 'admin_users', 'provider_secrets'];

function checkCoreCounts(raw) {
    let counts;
    try { counts = JSON.parse(String(raw).trim()); } catch { throw new Error('Contagem das tabelas ilegível.'); }
    const empty = REQUIRED.filter(name => !(Number(counts?.[name]) > 0));
    if (empty.length) throw new Error(`Backup sem dados em: ${empty.join(', ')}.`);
    return Object.fromEntries(Object.entries(counts).map(([name, value]) => [name, Number(value)]));
}

if (require.main === module) {
    const mode = process.argv[2] === 'physical' ? 'physical' : 'logical';
    let input = '';
    process.stdin.on('data', chunk => { input += chunk; });
    process.stdin.on('end', () => {
        try {
            console.log(JSON.stringify({ [`${mode}RestoredRows`]: checkCoreCounts(input) }));
        } catch (error) {
            console.error(JSON.stringify({ backupVerifyFailed: true, mode, message: error.message }));
            process.exitCode = 1;
        }
    });
}

module.exports = { checkCoreCounts, REQUIRED };
