const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Inicializar com configuração explícita
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
});

const db = admin.firestore();

async function copyDocument() {
    try {
        console.log('🔍 Buscando documento original 3kdrQFcCkRga234iB1YX...');

        const sourceRef = db.collection('provedores').doc('3kdrQFcCkRga234iB1YX');
        const sourceDoc = await sourceRef.get();

        if (!sourceDoc.exists) {
            console.error('❌ Documento original não encontrado!');
            process.exit(1);
        }

        const data = sourceDoc.data();
        console.log('✅ Documento original encontrado!');
        console.log(`📊 Total de campos: ${Object.keys(data).length}`);

        console.log('\n✍️  Criando documento vibe...');
        const targetRef = db.collection('provedores').doc('vibe');
        await targetRef.set(data);

        console.log('✅ Documento vibe criado com sucesso!');

        // Verificar se foi criado
        const verify = await targetRef.get();
        if (verify.exists) {
            console.log('✅ Verificação: documento vibe existe!');
            console.log(`📊 Total de campos copiados: ${Object.keys(verify.data()).length}`);
        }

        console.log('\n🎉 CONCLUÍDO!');
        console.log('⚠️  Agora faça LOGOUT e LOGIN novamente no painel admin.');

        process.exit(0);
    } catch (error) {
        console.error('❌ Erro:', error.message);
        console.error('\n🔍 Detalhes do erro:');
        console.error(error);
        process.exit(1);
    }
}

copyDocument();
