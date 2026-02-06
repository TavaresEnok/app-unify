"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("firebase-admin/app");
const storage_1 = require("firebase-admin/storage");
const firestore_1 = require("firebase-admin/firestore");
(0, app_1.initializeApp)({
    storageBucket: "app-ajust-provedor.appspot.com"
});
const storage = (0, storage_1.getStorage)();
const db = (0, firestore_1.getFirestore)();
const providerId = "vibe";
const logoPathLocal = "/home/app/.gemini/antigravity/brain/061ec0e6-e052-453b-aca6-2627ad89e1bf/uploaded_media_1769785854969.png";
async function manualAction() {
    console.log("Iniciando upload manual da logo...");
    // 1. Upload Logo
    const bucket = storage.bucket();
    const destPath = `providers/${providerId}/logo.png`;
    try {
        await bucket.upload(logoPathLocal, {
            destination: destPath,
            metadata: { contentType: 'image/png' },
            public: true
        });
        console.log("Logo enviada para o Storage.");
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${destPath}`;
        console.log("URL Pública:", publicUrl);
        // 2. Update Firestore
        await db.collection('provedores').doc(providerId).set({
            logoUrl: publicUrl,
            details: { logoUrl: publicUrl } // Ensure consistency
        }, { merge: true });
        console.log("Firestore atualizado.");
    }
    catch (e) {
        console.error("Erro no upload:", e);
        return;
    }
    // 3. Trigger APK Build (Simulated or via HTTP if external, but here we assume we can call the function logic or just print instructions)
    // Since we cannot easily invoke the 'onCall' function from here without a client, 
    // and the user wants the APK *generated*, we essentially need to trigger the build pipeline.
    // Looking at the grep results, generateApk seems to be an onCall function.
    // We will assume the build script is available or we can invoke the same logic.
    console.log("Logo configurada com sucesso. Agora execute o comando de build do APK se houver um script manual, ou use a função cloud.");
}
manualAction();
//# sourceMappingURL=manual_fix_vibe.js.map