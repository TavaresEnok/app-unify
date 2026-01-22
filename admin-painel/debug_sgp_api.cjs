const https = require('https');

// Credenciais extraídas do banco
const config = {
    url: 'https://vibetelecom.sgp.net.br/api/ura/clientes/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

async function testSgp() {
    console.log(`🔌 Testando conexão com SGP: ${config.url}`);

    // Construir corpo do POST (x-www-form-urlencoded)
    const postData = new URLSearchParams();
    postData.append('token', config.token);
    postData.append('app', config.app);
    postData.append('pagina', '1');
    postData.append('limit', '10'); // Vamos pedir 10 pra ver

    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': Buffer.byteLength(postData.toString())
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(config.url, options, (res) => {
            console.log(`📡 Status Code: ${res.statusCode}`);

            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    console.log('📦 Resposta Raw (primeiros 500 chars):');
                    console.log(data.substring(0, 500));

                    const json = JSON.parse(data);
                    console.log('\n✅ JSON Parseado com sucesso!');

                    if (json.clientes && Array.isArray(json.clientes)) {
                        console.log(`📊 Clientes retornados: ${json.clientes.length}`);
                        if (json.clientes.length > 0) {
                            console.log('👤 Primeiro Cliente:', JSON.stringify(json.clientes[0], null, 2));
                        }
                    } else if (Array.isArray(json)) {
                        console.log(`📊 Array retornado: ${json.length}`);
                        if (json.length > 0) {
                            console.log('👤 Primeiro Item:', JSON.stringify(json[0], null, 2));
                        }
                    } else {
                        console.log('⚠️  Estrutura inesperada:', Object.keys(json));
                    }
                } catch (e) {
                    console.error('❌ Erro no parse:', e);
                }
                resolve();
            });
        });

        req.on('error', (e) => {
            console.error('❌ Erro na requisição:', e);
            reject(e);
        });

        req.write(postData.toString());
        req.end();
    });
}

testSgp();
