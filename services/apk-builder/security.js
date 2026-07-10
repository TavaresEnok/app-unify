const fs = require('fs');

const MAX_LOGO_BYTES = 5 * 1024 * 1024;

function createLogoPolicy(hosts) {
    const allowedHosts = new Set(hosts.map(value => value.trim().toLowerCase()).filter(Boolean));

    function validate(value) {
        const parsed = new URL(value);
        if (parsed.protocol !== 'https:' || !allowedHosts.has(parsed.hostname.toLowerCase())) {
            throw new Error('A logo deve usar HTTPS em um host autorizado.');
        }
        return parsed;
    }

    async function download(value, outputPath) {
        let currentUrl = validate(value);
        for (let redirects = 0; redirects <= 3; redirects += 1) {
            const response = await fetch(currentUrl, {
                redirect: 'manual',
                signal: AbortSignal.timeout(15_000),
            });
            if ([301, 302, 303, 307, 308].includes(response.status)) {
                const location = response.headers.get('location');
                if (!location || redirects === 3) throw new Error('Redirecionamento de logo inválido.');
                currentUrl = validate(new URL(location, currentUrl).toString());
                continue;
            }
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const declaredSize = Number(response.headers.get('content-length') || 0);
            if (declaredSize > MAX_LOGO_BYTES) throw new Error('Logo maior que 5 MB.');
            const bytes = Buffer.from(await response.arrayBuffer());
            if (bytes.length > MAX_LOGO_BYTES) throw new Error('Logo maior que 5 MB.');
            fs.writeFileSync(outputPath, bytes);
            return bytes.length;
        }
        throw new Error('Falha ao baixar logo.');
    }

    return { download, validate };
}

module.exports = { createLogoPolicy, MAX_LOGO_BYTES };
