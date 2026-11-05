import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyCMySTH49MgYk2TyuGxnLd0zOQ-Cah2l5A",
  authDomain: "app-ajust-provedor.firebaseapp.com",
  projectId: "app-ajust-provedor",
  storageBucket: "app-ajust-provedor.appspot.com", // Corrigido de .firebasestorage.app
  messagingSenderId: "2735150999",
  appId: "1:2735150999:web:20a6ba508b510ce90a56d2",
  measurementId: "G-2W0E4E1KLB"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export { app, auth };
