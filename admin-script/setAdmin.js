const admin = require('firebase-admin');

// --- IMPORTANTE: Altere para o seu email aqui ---
const USER_EMAIL_TO_MAKE_ADMIN = "tavares.enok@gmail.com";

try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    console.log("A procurar utilizador:", USER_EMAIL_TO_MAKE_ADMIN);

    admin.auth().getUserByEmail(USER_EMAIL_TO_MAKE_ADMIN)
        .then((user) => {
            const currentClaims = user.customClaims || {};
            console.log("Permissões atuais:", currentClaims);

            return admin.auth().setCustomUserClaims(user.uid, { ...currentClaims, superAdmin: true });
        })
        .then(() => {
            console.log(`\nSUCESSO! A permissão 'superAdmin: true' foi definida para ${USER_EMAIL_TO_MAKE_ADMIN}.`);
            console.log("Por favor, saia e faça login novamente no painel.");
            process.exit(0);
        })
        .catch((error) => {
            console.error("\nERRO ao definir a permissão:", error.message);
            process.exit(1);
        });

} catch (e) {
    if (e.code === 'MODULE_NOT_FOUND') {
        console.error("\nERRO: Arquivo 'serviceAccountKey.json' não encontrado.");
        console.error("Por favor, crie o arquivo e cole o conteúdo da sua chave privada nele.");
    } else {
        console.error("\nUm erro inesperado ocorreu:", e.message);
    }
    process.exit(1);
}
