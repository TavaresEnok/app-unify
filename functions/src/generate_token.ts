
import * as admin from 'firebase-admin';

// Initialize with default creds (Google Cloud)
if (!admin.apps.length) {
    admin.initializeApp();
}

async function generateToken() {
    try {
        const user = await admin.auth().getUserByEmail('vibe@gmail.com');
        await admin.auth().createCustomToken(user.uid, { providerId: 'vibe' }); // Add claim explicitly just in case
        console.log("CUSTOM_TOKEN generated successfully for uid:", user.uid);
    } catch (e) {
        console.error("Error generating token:", e);
    }
}

generateToken();
