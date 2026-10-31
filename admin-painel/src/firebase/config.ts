// ARQUIVO: src/firebase/config.ts

import {
  initializeFirestore,
  persistentLocalCache,
  persistentMultipleTabManager,
} from "firebase/firestore";
import { getFunctions } from "firebase/functions";
import { app, auth } from "./auth";

const db = initializeFirestore(app, {
  localCache: persistentLocalCache({
    tabManager: persistentMultipleTabManager(),
  }),
});
const FUNCTIONS_REGION = "southamerica-east1";
const functions = getFunctions(app, FUNCTIONS_REGION);

// Initialize Firebase Storage
import { getStorage } from "firebase/storage";
const storage = getStorage(app);

export { auth, db, functions, storage };
