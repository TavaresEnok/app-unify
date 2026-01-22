const https = require('https');

const postData = new URLSearchParams();
postData.append('token', '4b6aae35-219a-4580-8c5c-dfb4efdbfae3');
postData.append('app', 'APP-PROVEDOR');
postData.append('pagina', '1');
postData.append('limit', '5');

const options = {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
};

const req = https.request('https://vibetelecom.sgp.net.br/api/ura/clientes/', options, (res) => {
    let data = '';
    res.on('data', c => data += c);
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            if (json.clientes && json.clientes.length > 0) {
                console.log("Client Keys:", Object.keys(json.clientes[0]));
                console.log("First Client:", JSON.stringify(json.clientes[0], null, 2));
            } else {
                console.log("No clients found or unexpected structure:", Object.keys(json));
            }
        } catch (e) {
            console.error(e);
        }
    });
});
req.write(postData.toString());
req.end();
