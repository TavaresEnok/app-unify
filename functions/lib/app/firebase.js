"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.storage = exports.messaging = exports.auth = exports.db = void 0;
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const storage_1 = require("firebase-admin/storage");
const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || process.env.PROJECT_ID || "";
const storageBucket = process.env.STORAGE_BUCKET || process.env.FIREBASE_STORAGE_BUCKET ||
    (projectId ? `${projectId}.appspot.com` : "");
if (!(0, app_1.getApps)().length) {
    (0, app_1.initializeApp)(storageBucket ? { storageBucket } : undefined);
}
exports.db = (0, firestore_1.getFirestore)();
exports.auth = (0, auth_1.getAuth)();
exports.messaging = (0, messaging_1.getMessaging)();
exports.storage = (0, storage_1.getStorage)();
//# sourceMappingURL=firebase.js.map