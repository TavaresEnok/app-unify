const admin = require('firebase-admin');

// Verificar se já foi inicializado
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://app-ajust-provedor.firebaseio.com"
  });
}

const db = admin.firestore();

async function fixProvider() {
  console.log('🔧 Corrigindo provedor Vibe...\n');
  
  try {
    // 1. Ler documento original
    console.log('📖 Lendo documento original...');
    const sourceDoc = await db.collection('provedores').doc('3kdrQFcCkRga234iB1YX').get();
    
    if (!sourceDoc.exists) {
      console.error('❌ Documento 3kdrQFcCkRga234iB1YX não existe!');
      process.exit(1);
    }
    
    const data = sourceDoc.data();
    console.log(`✅ Documento lido: ${data.name || 'Sem nome'}`);
    console.log(`   Campos: ${Object.keys(data).length}`);
    
    // 2. Deletar documento vazio se existir
    console.log('\n🗑️  Verificando documento vazio...');
    const emptyDoc = await db.collection('provedores').doc('32354591000191').get();
    if (emptyDoc.exists) {
      await db.collection('provedores').doc('32354591000191').delete();
      console.log('✅ Documento vazio deletado');
    }
    
    // 3. Criar documento completo com ID "vibe" (mais simples)
    console.log('\n📝 Criando documento com ID "vibe"...');
    await db.collection('provedores').doc('vibe').set(data);
    console.log('✅ Documento criado: provedores/vibe');
    
    // 4. Verificar se usuário existe e atualizar token
    console.log('\n🔐 Atualizando token do usuário...');
    try {
      const user = await admin.auth().getUserByEmail('vibe@gmail.com');
      await admin.auth().setCustomUserClaims(user.uid, { providerId: 'vibe' });
      console.log(`✅ Token atualizado: ${user.email} → providerId: "vibe"`);
    } catch (authError) {
      console.error('⚠️  Erro ao atualizar token:', authError.message);
    }
    
    console.log('\n🎉 CONCLUÍDO!');
    console.log('⚠️  IMPORTANTE: Faça LOGOUT e LOGIN novamente no painel.');
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ ERRO:', error);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

fixProvider();
