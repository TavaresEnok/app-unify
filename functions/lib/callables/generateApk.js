"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateApk = void 0;
const node_child_process_1 = require("node:child_process");
const node_fs_1 = require("node:fs");
const os = __importStar(require("node:os"));
const path = __importStar(require("node:path"));
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
const config_1 = require("../app/config");
const audit_1 = require("../app/audit");
async function downloadLogo(url, target) {
    const parsed = new URL(url);
    if (parsed.protocol !== "https:")
        throw new https_1.HttpsError("invalid-argument", "A logo deve usar HTTPS.");
    const response = await fetch(parsed, { redirect: "follow" });
    if (!response.ok)
        throw new https_1.HttpsError("invalid-argument", "Não foi possível baixar a logo.");
    const buffer = Buffer.from(await response.arrayBuffer());
    if (!buffer.length || buffer.length > 5 * 1024 * 1024)
        throw new https_1.HttpsError("invalid-argument", "Logo inválida ou maior que 5 MB.");
    await node_fs_1.promises.writeFile(target, buffer);
}
exports.generateApk = (0, https_1.onCall)({
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "southamerica-east1",
}, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.token.superAdmin))
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admin pode gerar aplicativos.");
    const providerId = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.providerId) === "string" ? request.data.providerId : "";
    const appName = typeof ((_c = request.data) === null || _c === void 0 ? void 0 : _c.appName) === "string" ? request.data.appName : "";
    const logoUrl = typeof ((_d = request.data) === null || _d === void 0 ? void 0 : _d.logoUrl) === "string" ? request.data.logoUrl : "";
    const format = ((_e = request.data) === null || _e === void 0 ? void 0 : _e.format) === "aab" ? "aab" : "apk";
    if (!providerId || !appName || !logoUrl)
        throw new https_1.HttpsError("invalid-argument", "ProviderID, nome e logo são obrigatórios.");
    if (!/^[a-z0-9_-]+$/i.test(providerId))
        throw new https_1.HttpsError("invalid-argument", "ProviderID inválido.");
    const script = config_1.apkScriptPath.value();
    const root = config_1.apkProjectRoot.value();
    if (!script || !root)
        throw new https_1.HttpsError("failed-precondition", "Gerador de aplicativo não configurado.");
    const logoPath = path.join(os.tmpdir(), `unify-logo-${providerId}-${Date.now()}.png`);
    try {
        await downloadLogo(logoUrl, logoPath);
        const packageName = `br.com.provedores.${providerId.replace(/[^a-z0-9]/gi, "").toLowerCase()}`;
        const args = [script, "--id", providerId, "--nome", appName, "--logo", logoPath, "--package", packageName];
        if (format === "aab")
            args.push("--format", "aab", "--obfuscate");
        const logs = await new Promise((resolve, reject) => {
            const process = (0, node_child_process_1.spawn)("python3", args, { cwd: root });
            let stdout = "";
            let stderr = "";
            process.stdout.on("data", (chunk) => { stdout += String(chunk); });
            process.stderr.on("data", (chunk) => { stderr += String(chunk); });
            process.on("error", reject);
            process.on("close", (code) => code === 0 ? resolve(stdout) : reject(new Error(`Gerador encerrou com código ${code}: ${stderr.slice(-2000)}`)));
        });
        await (0, audit_1.recordAudit)({
            requestId: `callable-generate-apk-${Date.now()}`,
            type: "GENERATE_APK",
            requesterUid: request.auth.uid,
            providerId,
            payload: { appName, format },
            outcome: "success",
        }).catch((error) => logger.error("Audit write failed", { providerId, error: String(error) }));
        return { success: true, message: "Aplicativo gerado com sucesso.", logs };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : "Falha ao gerar aplicativo.";
        logger.error("APK generation failed", { providerId, requesterUid: request.auth.uid, error: message });
        if (error instanceof https_1.HttpsError)
            throw error;
        throw new https_1.HttpsError("internal", message);
    }
    finally {
        await node_fs_1.promises.unlink(logoPath).catch(() => undefined);
    }
});
//# sourceMappingURL=generateApk.js.map