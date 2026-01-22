const https = require('https');

const config = {
    host: 'vibetelecom.sgp.net.br',
    path: '/api/ura/clientes/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

/**
 * Fetch a page of clients using 'pagina' parameter
 */
async function fetchPage(page, limit) {
    const postData = new URLSearchParams();
    postData.append('token', config.token);
    postData.append('app', config.app);
    postData.append('limit', limit.toString());
    postData.append('pagina', page.toString()); // Using 'pagina' as verified in check_keys_v2

    const options = {
        hostname: config.host,
        path: config.path,
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': Buffer.byteLength(postData.toString()),
            'User-Agent': 'NodeJS/Test',
            'Connection': 'keep-alive'
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => {
                if (res.statusCode !== 200) {
                    console.error(`❌ Error ${res.statusCode}: ${data}`);
                    return resolve(null);
                }

                try {
                    const json = JSON.parse(data);
                    resolve(json);
                } catch (e) {
                    console.error("❌ JSON Parse Error:", e.message);
                    console.error("DEBUG:", data.substring(0, 100)); // Debug data start
                    resolve(null);
                }
            });
        });
        req.on('error', (e) => {
            console.error("❌ Network Error:", e.message);
            reject(e);
        });
        req.write(postData.toString());
        req.end();
    });
}

async function runValidator() {
    console.log("🚀 Iniciando busca completa de clientes via CLI (Modo Pagina)...");
    let totalClientes = 0;
    const limit = 50;
    let page = 1;
    const maxPages = 20; // Try 20 pages (1000 clients max for test)

    while (true) {
        console.log(`\n📄 Buscando Página ${page} (Limit: ${limit})...`);
        const response = await fetchPage(page, limit);

        if (!response) {
            console.log("🛑 Falha na requisiçãoou resposta inválida. Abortando.");
            break;
        }

        let clientes = [];
        if (Array.isArray(response)) {
            clientes = response;
        } else if (response.clientes && Array.isArray(response.clientes)) {
            clientes = response.clientes;
        }

        const count = clientes.length;
        console.log(`✅ Encontrados: ${count} clientes nesta página.`);

        if (count > 0) {
            console.log(`   - Primeiro: ${clientes[0].nome} (ID: ${clientes[0].id})`);
            console.log(`   - Último:   ${clientes[count - 1].nome} (ID: ${clientes[count - 1].id})`);
            totalClientes += count;
        }

        if (count < limit) {
            console.log("\n🏁 Fim da paginação (menos itens que o limite retornados).");
            break;
        }

        if (page >= maxPages) {
            console.log(`🛑 Limite de segurança de ${maxPages} páginas atingido.`);
            break;
        }

        page++;

        // Small delay to prevent rate limiting
        await new Promise(r => setTimeout(r, 500));
    }

    console.log(`\n🎉 Total de Clientes Sincronizados (Simulação): ${totalClientes}`);
}

runValidator();
