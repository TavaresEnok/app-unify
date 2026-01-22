const fs = require('fs');
const https = require('https');
const path = require('path');

const PROJECT_ID = 'app-ajust-provedor';
const SOURCE_DOC_ID = '3kdrQFcCkRga234iB1YX';
const TARGET_DOC_ID = 'vibe';

async function request(options, body = null) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    if (res.statusCode >= 200 && res.statusCode < 300) resolve(json);
                    else reject({ statusCode: res.statusCode, error: json });
                } catch (e) { reject({ statusCode: res.statusCode, error: data }); }
            });
        });
        req.on('error', reject);
        if (body) req.write(body);
        req.end();
    });
}

async function run() {
    try {
        const configPath = path.join('/home/app/.config/configstore/firebase-tools.json');
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        const accessToken = config.tokens.access_token;
        const firestoreHost = 'firestore.googleapis.com';

        // Listar subcoleções do documento original
        console.log(`📡 Listando subcoleções de ${SOURCE_DOC_ID}...`);

        // Firestore REST não tem "listCollections" direto em um documento document:listCollectionIds
        // POST /v1/{parent=projects/*/databases/*/documents/*/*}:listCollectionIds

        const listPath = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/provedores/${SOURCE_DOC_ID}:listCollectionIds`;

        const collections = await request({
            hostname: firestoreHost,
            path: listPath,
            method: 'POST', // É POST
            headers: { 'Authorization': `Bearer ${accessToken}` }
        });

        console.log('📂 Subcoleções encontradas:', collections.collectionIds || 'Nenhuma');

        if (collections.collectionIds && collections.collectionIds.length > 0) {
            console.log('⚠️  ALERTA: O documento original TEM subcoleções que NÃO foram copiadas!');
            console.log('Isso explica por que tickets e clientes não aparecem se estivessem lá.');
        } else {
            console.log('ℹ️  Nenhuma subcoleção no documento original.');
        }

    } catch (e) {
        console.error('❌ Erro:', e);
    }
}

run();
