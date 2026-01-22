const https = require('https');

const config = {
    host: 'vibetelecom.sgp.net.br',
    path: '/api/ura/clientes/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

async function check() {
    const postData = new URLSearchParams();
    postData.append('token', config.token);
    postData.append('app', config.app);
    postData.append('pagina', '1');
    postData.append('limit', '5');

    const options = {
        hostname: config.host,
        path: config.path,
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': Buffer.byteLength(postData.toString()),
            'User-Agent': 'NodeJS/Test'
        }
    };

    return new Promise((resolve) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    if (json.clientes && json.clientes.length > 0) {
                        const client = json.clientes[0];
                        console.log("✅ Success! Client Keys Found:");
                        console.log(Object.keys(client).join(', '));
                        console.log("\n📋 Sample Values:");
                        console.log(`ID: ${client.id}`);
                        console.log(`Nome: ${client.nome}`);
                        console.log(`CPF/CNPJ (Raw): ${client.cpf_cnpj || client.cpfcnpj || client.doc || 'MISSING'}`);
                    } else {
                        console.log("⚠️ No clients in list or different structure:", Object.keys(json));
                    }
                } catch (e) {
                    console.error("❌ JSON Parse Error:", e.message);
                    console.log("Raw Start:", data.substring(0, 100));
                }
                resolve();
            });
        });
        req.on('error', console.error);
        req.write(postData.toString());
        req.end();
    });
}

check();
