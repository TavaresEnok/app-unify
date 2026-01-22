const https = require('https');

const config = {
    host: 'vibetelecom.sgp.net.br',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

const endpoints = [
    '/api/ura/clientes/',
    '/api/integracao/clientes/',
    '/api/clientes/',
    '/api/ura/login/' // check auth
];

async function post(path) {
    return new Promise((resolve) => {
        const postData = new URLSearchParams();
        postData.append('token', config.token);
        postData.append('app', config.app);

        // Add minimal params often required
        postData.append('pagina', '1');
        postData.append('limit', '5');

        const options = {
            hostname: config.host,
            path: path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(postData.toString()),
                'User-Agent': 'NodeJS/Test'
            },
            timeout: 8000
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => {
                try {
                    // Try parse
                    const json = JSON.parse(data);
                    const isArray = Array.isArray(json);
                    let sampleClient = null;

                    if (isArray && json.length > 0) sampleClient = json[0];
                    else if (json.clientes && json.clientes.length > 0) sampleClient = json.clientes[0];

                    let keysInfo = "";
                    if (sampleClient) {
                        keysInfo = "Client Keys: " + Object.keys(sampleClient).join(', ');
                        // Print values for distinct ID fields
                        console.log("Client Dump:", JSON.stringify(sampleClient, null, 2));
                    }

                    resolve({ path, status: res.statusCode, keys: isArray ? "Array" : "Object", keysInfo });
                } catch (e) {
                    resolve({ path, status: res.statusCode, error: 'JSON Parse Error', raw: data.substring(0, 100) });
                }
            });
        });

        req.on('timeout', () => {
            req.destroy();
            resolve({ path, status: 'TIMEOUT' });
        });

        req.on('error', (e) => resolve({ path, error: e.message }));
        req.write(postData.toString());
        req.end();
    });
}

async function run() {
    console.log("🔍 Sondando Endpoints SGP...");
    for (const ep of endpoints) {
        const res = await post(ep);
        console.log(`\n👉 ${ep}`);
        console.log(`   Status: ${res.status}`);
        if (res.keys) console.log(`   Keys/Type: ${res.keys}`);
        if (res.sample) console.log(`   Sample: ${res.sample}`);
        if (res.error) console.log(`   Error: ${res.error}`);
        if (res.raw) console.log(`   Raw: ${res.raw}`);
    }
}

run();
