
const admin = require('firebase-admin');
const serviceAccount = require('/home/app/painel-provedores-projeto/admin-script/serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateProviderUrl() {
    const providerId = 'vibe';
    const newUrl = 'http://168.194.13.18:3002';

    try {
        console.log(`Checking provider '${providerId}'...`);
        const docRef = db.collection('provedores').doc(providerId);
        const doc = await docRef.get();

        if (!doc.exists) {
            console.error('Provider not found!');
            return;
        }

        const data = doc.data();
        console.log('Current URL:', data.apiUrl);

        if (data.apiUrl === newUrl) {
            console.log('URL is already correct. No update needed.');
        } else {
            console.log(`Updating URL to ${newUrl}...`);
            // We update BOTH the root apiUrl and the config.apiUrl (legacy mirror) just in case
            await docRef.update({
                apiUrl: newUrl,
                'config.apiUrl': newUrl
            });
            console.log('✅ Update success!');
        }

    } catch (error) {
        console.error('Error updating provider:', error);
    }
}

updateProviderUrl();
