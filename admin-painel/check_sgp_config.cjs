const admin = require('firebase-admin');
const fs = require('fs');

// Inicializa com credenciais padrão que já sabemos estarem funcionando no ambiente
const serviceAccount = require('/home/app/painel-provedores-projeto/api-service/src/config/serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkConfig() {
    try {
        console.log("🔍 Lendo configuração do provedor 'vibe'...");
        const doc = await db.collection('provedores').doc('vibe').get();

        if (!doc.exists) {
            console.log("❌ Documento 'vibe' não existe.");
            return;
        }

        const data = doc.data();
        const integrations = data.integrations || {};
        const details = data.details || {};

        // Check legacy and new fields
        const sgpUrl = integrations.sgpBaseUrl || integrations.systemUrl || details.systemUrl || data.sgpBaseUrl;
        const token = integrations.apiToken || integrations.token || details.apiToken || data.apiToken;
        const appName = integrations.appName || details.appName || data.appName;

        console.log("\n📋 Configurações Encontradas:");
        console.log(`URL SGP: ${sgpUrl || '❌ NÃO DEFINIDA'}`);
        console.log(`Token: ${token ? '✅ DEFINIDO (' + token.substring(0, 5) + '...)' : '❌ NÃO DEFINIDO'}`);
        console.log(`App Name: ${appName || '❌ NÃO DEFINIDO'}`);

        if (!sgpUrl || !token) {
            console.log("\n⚠️  ATENÇÃO: Faltam credenciais para sincronizar data real.");
        } else {
            console.log("\n✅ Credenciais parecem estar presentes.");
        }

    } catch (e) {
        console.error("Erro:", e);
    }
}

checkConfig();
