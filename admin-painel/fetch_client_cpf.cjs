const https = require('https');

// Credenciais (Verificadas anteriormente)
const config = {
    url: 'https://vibetelecom.sgp.net.br/api/ura/clientes/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

const TARGET_CPF = '62558340425';

async function fetchClient() {
    console.log(`🔍 Buscando cliente com CPF: ${TARGET_CPF}`);
    console.log(`🔌 URL: ${config.url}`);

    const postData = new URLSearchParams();
    postData.append('token', config.token);
    postData.append('app', config.app);
    postData.append('cpfcnpj', TARGET_CPF);

    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': Buffer.byteLength(postData.toString())
        }
    };

    const req = https.request(config.url, options, (res) => {
        console.log(`📡 Status Code: ${res.statusCode}`);

        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
            try {
                const json = JSON.parse(data);
                console.log('\n✅ Resposta Recebida:');

                // Formatação bonita para o log
                if (json.clientes && json.clientes.length > 0) {
                    const c = json.clientes[0];
                    console.log('------------------------------------------------');
                    console.log(`👤 Nome: ${c.nome}`);
                    console.log(`🆔 ID: ${c.id}`);
                    console.log(`📅 Contratos: ${c.contratos?.length || 0}`);
                    if (c.contratos && c.contratos.length > 0) {
                        c.contratos.forEach((ct, idx) => {
                            console.log(`   📝 Contrato #${idx + 1}: ID ${ct.id} - Plano: ${ct.plano} - Status: ${ct.status_internet}`);
                        });
                    }
                    console.log('------------------------------------------------');
                    console.log('\n📦 JSON Completo (Primeiro Cliente):');
                    console.log(JSON.stringify(c, null, 2));
                } else {
                    console.log('⚠️ Nenhum cliente encontrado com este CPF.');
                    console.log('Resposta bruta:', JSON.stringify(json, null, 2));
                }

            } catch (e) {
                console.error('❌ Erro no parse:', e);
                console.log('Raw Data:', data);
            }
        });
    });

    req.on('error', (e) => {
        console.error('❌ Erro na requisição:', e);
    });

    req.write(postData.toString());
    req.end();
}

fetchClient();
