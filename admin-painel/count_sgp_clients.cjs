const https = require('https');

const config = {
    url: 'https://vibetelecom.sgp.net.br/api/ura/clientes/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

async function testSgpClientes() {
    console.log(`🔌 Testando LISTAGEM DE CLIENTES: ${config.url}`);

    // Testa Pagina 1, Limite 100
    const postData = new URLSearchParams();
    postData.append('token', config.token);
    postData.append('app', config.app);
    postData.append('pagina', '1');
    postData.append('limit', '100');

    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': Buffer.byteLength(postData.toString())
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(config.url, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);

                    // Análise da Estrutura
                    console.log('--- ANÁLISE DA RESPOSTA ---');
                    const keys = Object.keys(json);
                    console.log(`Chaves na raiz: ${keys.join(', ')}`);

                    let clientesList = [];
                    if (Array.isArray(json)) {
                        clientesList = json;
                        console.log(`Tipo: ARRAY direto.`);
                    } else if (json.clientes) {
                        clientesList = json.clientes;
                        console.log(`Tipo: Objeto com chave 'clientes'.`);
                    }

                    console.log(`\n📊 Total de Clientes Recebidos (Página 1, Limit 100): ${clientesList.length}`);

                    if (clientesList.length > 0) {
                        console.log(`\n👤 Exemplo do Cliente 1:`);
                        console.log(`ID: ${clientesList[0].id}`);
                        console.log(`Nome: ${clientesList[0].nome || clientesList[0].razaoSocial}`);
                    }

                    // Checar Paginação
                    if (json.paginacao) {
                        console.log('\n📄 Metadados de Paginação:', JSON.stringify(json.paginacao));
                    } else {
                        console.log('\n⚠️  Sem campo de paginação explícito.');
                    }

                } catch (e) {
                    console.error('❌ Erro parse:', e);
                    console.log('Raw data start:', data.substring(0, 200));
                }
                resolve();
            });
        });
        req.on('error', console.error);
        req.write(postData.toString());
        req.end();
    });
}

testSgpClientes();
