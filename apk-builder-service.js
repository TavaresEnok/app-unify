const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Firebase Admin for token verification
const admin = require('firebase-admin');
const serviceAccount = require('./admin-script/serviceAccountKey.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const app = express();
const PORT = Number(process.env.APK_BUILDER_PORT || process.env.PORT || 8035); // Dedicated port for APK builder
const PYTHON_BIN = process.env.PYTHON_BIN || '/usr/bin/python3';
const LOG_DIR = path.join(__dirname, 'apk', 'logs');
if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
}

app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Middleware to verify superAdmin
const verifySuperAdmin = async (req, res, next) => {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) return res.status(401).json({ error: 'Token não fornecido' });

    try {
        const decoded = await admin.auth().verifyIdToken(token);
        if (decoded.superAdmin !== true) {
            return res.status(403).json({ error: 'Apenas Super Admin pode gerar APKs' });
        }
        req.user = decoded;
        next();
    } catch (error) {
        console.error('Token verification error:', error.message);
        return res.status(403).json({ error: 'Token inválido' });
    }
};

app.post('/generate-apk', verifySuperAdmin, async (req, res) => {
    const { providerId, appName, logoUrl, format = 'apk' } = req.body;

    if (!providerId || !appName || !logoUrl) {
        return res.status(400).json({
            success: false,
            error: 'providerId, appName e logoUrl são obrigatórios.'
        });
    }

    const safeProviderId = providerId.replace(/[^a-z0-9]/gi, '').toLowerCase();
    const logId = `${Date.now()}_${safeProviderId || 'provider'}`;
    const logFile = path.join(LOG_DIR, `apk_${logId}.log`);
    const logStream = fs.createWriteStream(logFile, { flags: 'a' });
    const log = (msg) => {
        const line = `[${new Date().toISOString()}] ${msg}`;
        console.log(line);
        logStream.write(line + '\n');
    };

    log(`[APK Gen] Starting for ${providerId} (${appName}). Format: ${format}`);

    // Convert Firebase Storage URL to public download URL
    // From: https://storage.googleapis.com/bucket-name/path/to/file
    // To: https://firebasestorage.googleapis.com/v0/b/bucket-name/o/path%2Fto%2Ffile?alt=media
    let downloadUrl = logoUrl;
    if (logoUrl.includes('storage.googleapis.com') && !logoUrl.includes('alt=media')) {
        try {
            const url = new URL(logoUrl);
            const pathParts = url.pathname.split('/').filter(p => p);
            if (pathParts.length >= 2) {
                const bucket = pathParts[0];
                const objectPath = pathParts.slice(1).join('/');
                const encodedPath = encodeURIComponent(objectPath);
                downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodedPath}?alt=media`;
                log(`[APK Gen] Converted URL: ${downloadUrl}`);
            }
        } catch (e) {
            log(`[APK Gen Warning] Could not convert URL: ${e.message}`);
        }
    }
    log(`[APK Gen] Logo URL: ${downloadUrl}`);

    // 1. Download logo to temp file using curl (follows redirects properly)
    const tempLogoPath = path.join(os.tmpdir(), `logo_${providerId}_${Date.now()}.png`);

    try {
        // Use curl to download (follows redirects, handles SSL properly)
        const { execSync } = require('child_process');
        execSync(`curl -sL "${downloadUrl}" -o "${tempLogoPath}"`, { timeout: 30000 });

        // Validate downloaded file
        const stats = fs.statSync(tempLogoPath);
        log(`[APK Gen] Downloaded logo: ${stats.size} bytes`);

        if (stats.size < 1000) {
            // File too small, probably an error page
            const content = fs.readFileSync(tempLogoPath, 'utf8').substring(0, 200);
            log(`[APK Gen Error] Logo file too small. Content: ${content}`);
            fs.unlinkSync(tempLogoPath);
            return res.status(400).json({
                success: false,
                error: `Logo inválida (${stats.size} bytes). Verifique se a URL está correta.`,
                logFile
            });
        }
    } catch (downloadErr) {
        log(`[APK Gen Error] Download failed: ${downloadErr.message}`);
        return res.status(400).json({
            success: false,
            error: `Falha ao baixar logo: ${downloadErr.message}`,
            logFile
        });
    }

    // 2. Build Python command
    const scriptPath = '/home/app/projects/painel_provedores/admin-script/gerar_apk.py';
    const projectRoot = '/home/app/projects/painel_provedores';

    // Generate package name
    const packageName = `br.com.provedores.${safeProviderId}`;

    const pythonArgs = [
        scriptPath,
        '--id', providerId,
        '--nome', appName,
        '--logo', tempLogoPath,
        '--output', '/home/app/projects/painel_provedores/public_apks',
        '--package', packageName
    ];

    // Generate Version Code based on Unix Timestamp (Seconds)
    // Fits in Java Integer (Max 2,147,483,647). Current timestamp is ~1,770,000,000. Good until 2038.
    const versionCode = Math.floor(Date.now() / 1000).toString();

    pythonArgs.push('--version-code', versionCode);
    pythonArgs.push('--version-name', `1.0.${versionCode}`);

    if (format === 'aab') {
        pythonArgs.push('--format', 'aab');
        pythonArgs.push('--obfuscate');
        // AABs are automatically optimized by Google Play, but we can enforce optimization to be safe
        pythonArgs.push('--arm64');
    } else {
        // For APKs, user specifically asked for "recent processors" optimization to reduce size
        pythonArgs.push('--arm64');
    }

    // 3. Execute Python script with Flutter in PATH
    const androidSdkCandidate = '/home/app/Android/Sdk';
    const androidSdkFallback = '/home/app/Android';
    const androidSdkPath = fs.existsSync(androidSdkCandidate)
        ? androidSdkCandidate
        : (fs.existsSync(androidSdkFallback) ? androidSdkFallback : androidSdkCandidate);

    const env = {
        ...process.env,
        PATH: `/home/app/flutter/bin:/usr/local/bin:/usr/bin:/bin:${process.env.PATH || ''}`,
        ANDROID_HOME: process.env.ANDROID_HOME || androidSdkPath,
        ANDROID_SDK_ROOT: process.env.ANDROID_SDK_ROOT || androidSdkPath,
        // Force Pub Cache to user directory to allow patching
        PUB_CACHE: '/home/app/.pub-cache',
        // Container limit increased to 4GB. Using 3GB for Gradle.
        GRADLE_OPTS: '-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs="-Xmx3072m -XX:MaxMetaspaceSize=768m -XX:+HeapDumpOnOutOfMemoryError"'
    };

    const pythonCmd = fs.existsSync(PYTHON_BIN) ? PYTHON_BIN : 'python3';

    const pythonProcess = spawn(pythonCmd, pythonArgs, {
        cwd: projectRoot,
        env: env
    });

    let stdout = '';
    let stderr = '';

    pythonProcess.stdout.on('data', (data) => {
        const str = data.toString();
        stdout += str;
        log(`[APK Gen]: ${str.trimEnd()}`);
    });

    pythonProcess.stderr.on('data', (data) => {
        const str = data.toString();
        stderr += str;
        log(`[APK Gen Error]: ${str.trimEnd()}`);
    });

    pythonProcess.on('close', (code) => {
        // Cleanup temp logo
        fs.unlink(tempLogoPath, () => { });
        logStream.end();

        if (code === 0) {
            const safeAppName = appName.replace(/[^a-zA-Z0-9]/g, '_');
            const extension = format === 'aab' ? 'aab' : 'apk';
            const apkPath = `/public_apks/app_${safeAppName}.${extension}`;

            res.json({
                success: true,
                message: `${format.toUpperCase()} gerado com sucesso! Versão: 1.0.${versionCode}`,
                downloadUrl: apkPath,
                versionCode: versionCode,
                versionName: `1.0.${versionCode}`,
                logs: stdout,
                logFile
            });
        } else {
            const stderrSnippet = stderr.trim().slice(-2000);
            res.status(500).json({
                success: false,
                error: `Falha no script (Exit ${code})${stderrSnippet ? ` | ${stderrSnippet}` : ''}`,
                logs: stdout,
                errorLogs: stderr,
                logFile
            });
        }
    });

    pythonProcess.on('error', (err) => {
        fs.unlink(tempLogoPath, () => { });
        log(`[APK Gen Error]: ${err.message}`);
        logStream.end();
        if (err.code === 'ENOENT') {
            return res.status(500).json({
                success: false,
                error: `Python não encontrado. Configure PYTHON_BIN ou instale python3 no host. PATH atual: ${env.PATH}`,
                logFile
            });
        }
        res.status(500).json({
            success: false,
            error: `Erro ao executar script: ${err.message}`,
            logFile
        });
    });
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'apk-builder' });
});

app.listen(PORT, () => {
    console.log(`✅ APK Builder Service running on port ${PORT}`);
});
