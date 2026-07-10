import { defineSecret, defineString } from "firebase-functions/params";

export const proxyUrlSecret = defineSecret("PROXY_URL");
export const proxySecretParam = defineSecret("PROXY_SECRET");
export const apkScriptPath = defineString("APK_SCRIPT_PATH", { default: "" });
export const apkProjectRoot = defineString("APK_PROJECT_ROOT", { default: "" });
