const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrate() {
  console.log('🔄 Migrando provedor para CNPJ...\n');
  
  try {
    // 1. Copiar documento
    const doc = await db.collection('provedores').doc('3kdrQFcCkRga234iB1YX').get();
    if (!doc.exists) {
      console.error('❌ Documento não encontrado!');
      process.exit(1);
    }
    
    const data = doc.data();
    console.log('✅ Lido:', data.name);
    
    await db.collection('provedores').doc('32354591000191').set(data);
    console.log('✅ Criado: provedores/32354591000191');
    
    // 2. Atualizar token
    const user = await admin.auth().getUserByEmail('vibe@gmail.com');
    await admin.auth().setCustomUserClaims(user.uid, { providerId: '32354591000191' });
    console.log('✅ Token atualizado');
    
    console.log('\n🎉 Concluído! Faça LOGOUT e LOGIN novamente.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

migrate();
