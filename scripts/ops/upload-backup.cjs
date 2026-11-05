const admin = require('firebase-admin');
const fs = require('fs');
const [file, bucket, destination] = process.argv.slice(2);
if (!file || !bucket || !destination?.startsWith('backend_backups/') || destination.includes('..')) throw new Error('Arquivo, bucket e destino privado backend_backups/ são obrigatórios.');
admin.initializeApp();
(async () => {
    const [object] = await admin.storage().bucket(bucket).upload(file, { destination, validation: 'crc32c', metadata: { contentType: 'application/octet-stream', cacheControl: 'no-store' } });
    const [metadata] = await object.getMetadata();
    if (Number(metadata.size) !== fs.statSync(file).size) throw new Error('Tamanho do backup remoto divergente.');
    console.log(JSON.stringify({ destination, bytes: Number(metadata.size), generation: metadata.generation }));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
