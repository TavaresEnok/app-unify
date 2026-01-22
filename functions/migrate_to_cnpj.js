const admin = require('firebase-admin');
const serviceAccount = require('../admin-script/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrate() {
  try {
    console.log('📋 Migrando provedor para CNPJ...\n');
    
    // 1. Ler documento original
    const originalDoc = await db.collection('provedores').doc('3kdrQFcCkRga234iB1YX').get();
    
    if (!originalDoc.exists) {
      console.error('❌ Documento original não encontrado!');
      process.exit(1);
    }
    
    const data = originalDoc.data();
    console.log('✅ Documento lido:', data.name);
    
    // 2. Criar cópia com CNPJ
    await db.collection('provedores').doc('32354591000191').set(data);
    console.log('✅ Criado: provedores/32354591000191');
    
    // 3. Atualizar token
    const user = await admin.auth().getUserByEmail('vibe@gmail.com');
    await admin.auth().setCustomUserClaims(user.uid, { providerId: '32354591000191' });
    console.log('✅ Token atualizado para vibe@gmail.com');
    
    console.log('\n🎉 Concluído! Faça logout e login novamente.');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

migrate();
