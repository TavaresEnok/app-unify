import { defineSecret, defineString } from "firebase-functions/params";

export const proxyUrlSecret = defineSecret("PROXY_URL");
export const proxySecretParam = defineSecret("PROXY_SECRET");
export const apkBuilderUrl = defineString("APK_BUILDER_URL", { default: "" });
