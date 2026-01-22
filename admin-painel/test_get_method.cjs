const https = require('https');

const config = {
    host: 'vibetelecom.sgp.net.br',
    path: '/api/ura/clientes/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

async function checkGetArgs() {
    const params = new URLSearchParams();
    params.append('token', config.token);
    params.append('app', config.app);
    params.append('limit', '5');
    params.append('pagina', '1');

    const options = {
        hostname: config.host,
        path: `${config.path}?${params.toString()}`,
        method: 'GET',
        headers: {
            'User-Agent': 'NodeJS/Test',
            'Connection': 'keep-alive',
            'Accept': '*/*'
        }
    };

    console.log(`🚀 Testing GET request to: ${options.path}`);

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => {
                console.log(`Status: ${res.statusCode}`);
                if (res.statusCode === 200) {
                    try {
                        const json = JSON.parse(data);
                        if (json.clientes) {
                            console.log("✅ GET works! Clients found:", json.clientes.length);
                        } else {
                            console.log("⚠️ GET 200 but no clients:", Object.keys(json));
                        }
                    } catch (e) {
                        console.log("❌ GET 200 but parse error.", data);
                    }
                } else {
                    console.log(`❌ GET Failed: ${data}`);
                }
                resolve();
            });
        });
        req.on('error', (e) => {
            console.error("❌ Network Error:", e.message);
            reject(e);
        });
        req.end();
    });
}

checkGetArgs();
