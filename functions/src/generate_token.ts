
import * as admin from 'firebase-admin';

// Initialize with default creds (Google Cloud)
if (!admin.apps.length) {
    admin.initializeApp();
}

async function generateToken() {
    try {
        const user = await admin.auth().getUserByEmail('vibe@gmail.com');
        const token = await admin.auth().createCustomToken(user.uid, { providerId: 'vibe' }); // Add claim explicitly just in case
        console.log("CUSTOM_TOKEN:", token);
    } catch (e) {
        console.error("Error generating token:", e);
    }
}

generateToken();
