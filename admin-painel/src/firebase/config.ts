// ARQUIVO: src/firebase/config.ts

import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore, enableIndexedDbPersistence } from "firebase/firestore";
import { getFunctions } from "firebase/functions";
// O getAnalytics é opcional, mas vamos mantê-lo como está na sua configuração.
import { getAnalytics } from "firebase/analytics";

// Your web app's Firebase configuration - COPIADO DO SEU CONSOLE
const firebaseConfig = {
  apiKey: "AIzaSyCMySTH49MgYk2TyuGxnLd0zOQ-Cah2l5A",
  authDomain: "app-ajust-provedor.firebaseapp.com",
  projectId: "app-ajust-provedor",
  storageBucket: "app-ajust-provedor.appspot.com", // Corrigido de .firebasestorage.app
  messagingSenderId: "2735150999",
  appId: "1:2735150999:web:20a6ba508b510ce90a56d2",
  measurementId: "G-2W0E4E1KLB"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const FUNCTIONS_REGION = "southamerica-east1";
const functions = getFunctions(app, FUNCTIONS_REGION);
const analytics = getAnalytics(app); // Inicializa o Analytics

// Enable Offline Persistence
enableIndexedDbPersistence(db, { forceOwnership: false })
  .catch((err) => {
    if (err.code == 'failed-precondition') {
      console.warn("Firestore Persistence: Múltiplas abas abertas. Persistência habilitada apenas em uma.");
    } else if (err.code == 'unimplemented') {
      console.warn("Firestore Persistence: Browser não suporta.");
    }
  });

// Initialize Firebase Storage
import { getStorage } from "firebase/storage";
const storage = getStorage(app);

export { auth, db, functions, analytics, storage };
