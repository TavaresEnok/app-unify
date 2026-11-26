'use strict';
const fs = require('node:fs');
const path = require('node:path');

// Mantém só os builds mais recentes de cada formato por provedor, para o disco
// não encher com apps antigos. Layout publicado:
//   <output>/<providerId>/<versionCode>/<buildId>/app.<apk|aab>
// "Mais recente" = maior versionCode; empate decide pela data do arquivo.
const DEFAULT_KEEP = 3;
const SAFE_SEGMENT = /^[A-Za-z0-9_-]{1,100}$/;

function listReleases(providerDir) {
    const releases = [];
    let versions;
    try { versions = fs.readdirSync(providerDir, { withFileTypes: true }); } catch { return releases; }
    for (const version of versions) {
        if (!version.isDirectory() || !/^\d{1,12}$/.test(version.name)) continue;
        const versionDir = path.join(providerDir, version.name);
        let builds;
        try { builds = fs.readdirSync(versionDir, { withFileTypes: true }); } catch { continue; }
        for (const build of builds) {
            if (!build.isDirectory() || !SAFE_SEGMENT.test(build.name)) continue;
            const buildDir = path.join(versionDir, build.name);
            for (const format of ['apk', 'aab']) {
                const file = path.join(buildDir, `app.${format}`);
                let stat;
                try { stat = fs.lstatSync(file); } catch { continue; }
                if (!stat.isFile()) continue;
                releases.push({ format, versionCode: Number(version.name), mtimeMs: stat.mtimeMs,
                    buildId: build.name, file, buildDir, versionDir });
            }
        }
    }
    return releases;
}

function removeIfEmpty(dir) {
    try { if (fs.readdirSync(dir).length === 0) fs.rmdirSync(dir); } catch { /* ignora */ }
}

/**
 * Apaga os builds além dos [keep] mais recentes de cada formato. Nunca apaga
 * o build [protectBuildId] (o que acabou de ser publicado). Devolve o que foi
 * removido. Falhas são ignoradas: limpeza nunca derruba uma publicação.
 */
function pruneProviderReleases(output, providerId, { keep = DEFAULT_KEEP, protectBuildId, stagingRoot } = {}) {
    if (!SAFE_SEGMENT.test(String(providerId || ''))) return [];
    const limit = Math.max(1, Math.floor(Number(keep)) || DEFAULT_KEEP);
    const providerDir = path.join(output, providerId);
    const removed = [];
    const releases = listReleases(providerDir);
    for (const format of ['apk', 'aab']) {
        const ordered = releases.filter(r => r.format === format)
            .sort((a, b) => b.versionCode - a.versionCode || b.mtimeMs - a.mtimeMs);
        let kept = 0;
        for (const release of ordered) {
            if (release.buildId === protectBuildId || kept < limit) { kept += 1; continue; }
            try {
                fs.rmSync(release.file, { force: true });
                removed.push({ format, versionCode: release.versionCode, buildId: release.buildId });
            } catch { continue; }
            removeIfEmpty(release.buildDir);
            removeIfEmpty(release.versionDir);
        }
    }
    if (stagingRoot) pruneStaging(path.join(stagingRoot, providerId), providerDir, protectBuildId, removed);
    return removed;
}

/**
 * A pasta privada de staging guarda a saída de cada build (artefato e
 * mapping). Fica só a dos builds ainda publicados; as demais (apagados pela
 * retenção ou builds que falharam) saem junto.
 */
function pruneStaging(providerStaging, providerDir, protectBuildId, removed) {
    const published = new Set(listReleases(providerDir).map(r => r.buildId));
    if (protectBuildId) published.add(protectBuildId);
    let versions;
    try { versions = fs.readdirSync(providerStaging, { withFileTypes: true }); } catch { return; }
    for (const version of versions) {
        if (!version.isDirectory() || !/^\d{1,12}$/.test(version.name)) continue;
        const versionDir = path.join(providerStaging, version.name);
        let builds;
        try { builds = fs.readdirSync(versionDir, { withFileTypes: true }); } catch { continue; }
        for (const build of builds) {
            if (!build.isDirectory() || !SAFE_SEGMENT.test(build.name) || published.has(build.name)) continue;
            try {
                fs.rmSync(path.join(versionDir, build.name), { recursive: true, force: true });
                removed.push({ format: 'staging', versionCode: Number(version.name), buildId: build.name });
            } catch { /* ignora */ }
        }
        removeIfEmpty(versionDir);
    }
}

module.exports = { pruneProviderReleases, DEFAULT_KEEP };
