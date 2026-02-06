const https = require('https');

// Credenciais (Verificadas)
const config = {
    url: 'https://vibetelecom.sgp.net.br/api/fttx/onu/list/',
    token: '4b6aae35-219a-4580-8c5c-dfb4efdbfae3',
    app: 'APP-PROVEDOR'
};

const TARGET_CPF = '62558340425';

async function fetchOnuData() {
    console.log(`🔍 Buscando ONU para CPF: ${TARGET_CPF}`);

    // Construir Query String para GET
    const params = new URLSearchParams({
        token: config.token,
        app: config.app,
        cpfcnpj: TARGET_CPF,
        signal: '1',
        connection: '1',
        address: '1'
    });

    const fullUrl = `${config.url}?${params.toString()}`;
    console.log(`🔌 URL: ${fullUrl}`);

    const options = {
        method: 'GET',
    };

    const req = https.request(fullUrl, options, (res) => {
        console.log(`📡 Status Code: ${res.statusCode}`);

        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
            try {
                // Tentar parsear o JSON mesmo se status != 200, para ver erro
                const json = JSON.parse(data);
                console.log('\n✅ JSON Parseado com sucesso!');

                // O endpoint list costuma retornar array puro ou objeto com chave data
                // Baseado no documento e no padrão SGP

                let onus = [];
                if (Array.isArray(json)) {
                    onus = json;
                } else if (json.data && Array.isArray(json.data)) {
                    onus = json.data;
                } else if (json.onus && Array.isArray(json.onus)) {
                    onus = json.onus;
                } else {
                    // Se for objeto único, poe na lista
                    if (json.id) onus = [json];
                }

                if (onus.length > 0) {
                    console.log(`📊 ONUs Encontradas: ${onus.length}`);
                    onus.forEach((onu, idx) => {
                        console.log(`\n📡 ONU #${idx + 1} - ID: ${onu.id}`);
                        console.log(`   📝 Modelo: ${onu.model}`);
                        console.log(`   🔌 Serial: ${onu.phy_addr || onu.serial_number}`);
                        console.log(`   🌡️ Temperatura: ${onu.temperature || 'N/A'}`);
                        console.log(`   📶 Sinal RX: ${onu.rx_power || onu.signal || 'N/A'}`);
                        console.log(`   📶 Sinal TX: ${onu.tx_power || 'N/A'}`);
                        console.log(`   🟢 Status Conexão: ${onu.status_connection || onu.connection || 'N/A'}`);
                        console.log(`   📍 Endereço: ${onu.address || 'N/A'}`);
                    });

                    console.log('\n📦 Dump Completo (Primeira ONU):');
                    console.log(JSON.stringify(onus[0], null, 2));
                } else {
                    console.log('⚠️ Nenhuma ONU encontrada para este CPF.');
                    console.log('Resposta completa:', JSON.stringify(json, null, 2));
                }

            } catch (e) {
                console.error('❌ Erro no parse ou resposta sem JSON:', e);
                console.log('Raw Data:', data);
            }
        });
    });

    req.on('error', (e) => {
        console.error('❌ Erro na requisição:', e);
    });

    req.end();
}

fetchOnuData();
