// ARQUIVO: src/firebase/config.ts

import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
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
const analytics = getAnalytics(app); // Inicializa o Analytics

export { auth, db, analytics };
