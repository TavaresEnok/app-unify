"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.apkProjectRoot = exports.apkScriptPath = exports.proxySecretParam = exports.proxyUrlSecret = void 0;
const params_1 = require("firebase-functions/params");
exports.proxyUrlSecret = (0, params_1.defineSecret)("PROXY_URL");
exports.proxySecretParam = (0, params_1.defineSecret)("PROXY_SECRET");
exports.apkScriptPath = (0, params_1.defineString)("APK_SCRIPT_PATH", { default: "" });
exports.apkProjectRoot = (0, params_1.defineString)("APK_PROJECT_ROOT", { default: "" });
//# sourceMappingURL=config.js.map