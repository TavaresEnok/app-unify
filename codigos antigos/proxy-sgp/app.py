from flask import Flask, request, jsonify
import requests
import math

app = Flask(__name__)

PROXY_SECRET_KEY = "CHAVE_SECRETA_MUITO_FORTE_12345"

def fetch_sgp_page(params):
    """Função para fazer uma única chamada à API do SGP."""
    SGP_API_URL = "https://vibetelecom.sgp.net.br/api/ura/clientes/"
    try:
        # A biblioteca requests monta o body x-www-form-urlencoded a partir de um dicionário
        response = requests.post(SGP_API_URL, data=params, headers={'Content-Type': 'application/x-www-form-urlencoded'})
        response.raise_for_status() # Lança um erro para status 4xx ou 5xx

        data = response.json()
        if data.get("erro"):
            raise Exception(f"API do SGP retornou um erro: {data['erro']}")

        return data
    except requests.exceptions.RequestException as e:
        # Captura erros de rede, timeout, etc.
        print(f"Erro na chamada para o SGP: {e}")
        raise Exception(f"Erro de comunicação com a API do SGP: {e.response.status_code if e.response else 'N/A'}")


@app.route('/sgp-proxy', methods=['POST'])
def sgp_proxy():
    print("Recebido pedido no /sgp-proxy (versão Python)")

    req_data = request.get_json()
    secret = req_data.get('secret')
    params = req_data.get('params')

    if secret != PROXY_SECRET_KEY:
        print("Erro: Chave secreta inválida!")
        return jsonify({"error": "Acesso não autorizado."}), 403

    try:
        print("Buscando a primeira página de clientes via Python...")
        first_page_data = fetch_sgp_page(params)

        if not first_page_data.get("paginacao") or not first_page_data.get("clientes"):
            raise Exception("Resposta da API do SGP não contém 'paginacao' ou 'clientes'.")

        total_clients = first_page_data["paginacao"]["total"]
        limit = int(params.get("limit", 100))
        all_clients = first_page_data["clientes"]

        print(f"Total de clientes encontrado: {total_clients}. Limite por página: {limit}.")

        total_pages = math.ceil(total_clients / limit)
        if total_pages > 1:
            print(f"Iniciando busca sequencial de {total_pages - 1} páginas restantes...")
            for page in range(2, total_pages + 1):
                offset = (page - 1) * limit
                print(f"Buscando página {page} de {total_pages} (offset: {offset})...")
                page_params = params.copy()
                page_params['offset'] = str(offset)

                page_data = fetch_sgp_page(page_params)
                if page_data.get("clientes"):
                    all_clients.extend(page_data["clientes"])

        print(f"Busca concluída. Total de {len(all_clients)} clientes retornados.")
        return jsonify({"clientes": all_clients})

    except Exception as e:
        print(f"Erro no processo de busca: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Escuta em todas as interfaces de rede na porta 3000
    app.run(host='0.0.0.0', port=3000)
