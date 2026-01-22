const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function copyProviderDocument() {
  try {
    console.log('📋 Copiando documento do provedor...');
    
    // 1. Ler documento original
    const originalDoc = await db.collection('provedores').doc('3kdrQFcCkRga234iB1YX').get();
    
    if (!originalDoc.exists) {
      console.error('❌ Documento original não encontrado!');
      return;
    }
    
    const data = originalDoc.data();
    console.log('✅ Documento original lido:', data.name);
    
    // 2. Criar cópia com CNPJ como ID
    await db.collection('provedores').doc('32354591000191').set(data);
    console.log('✅ Documento copiado para: provedores/32354591000191');
    
    // 3. Atualizar custom claim do usuário
    const user = await admin.auth().getUserByEmail('vibe@gmail.com');
    await admin.auth().setCustomUserClaims(user.uid, {
      providerId: '32354591000191'
    });
    console.log('✅ Token atualizado: vibe@gmail.com → providerId: 32354591000191');
    
    console.log('\n🎉 Concluído! Faça logout e login novamente no painel.');
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  }
  
  process.exit(0);
}

copyProviderDocument();
