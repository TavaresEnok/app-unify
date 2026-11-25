# Integração IXC Provedor

O app e o backend falam o contrato SGP (URA/Central/FTTX). Para provedores com IXC, o
gateway [`shared/runtime/ixc-gateway.js`](../shared/runtime/ixc-gateway.js) traduz cada rota
SGP em chamadas ao webservice IXC (`POST /webservice/v1/<tabela>`) e devolve o mesmo formato.
O app Flutter **não muda**.

## Cadastro

Painel Admin → Configurações → Integrações (Super Admin): escolha **IXC Provedor**, informe a URL
do IXC (sem `/webservice/v1`) e o token do usuário de API. Não há "app". A credencial fica em
`provedores/{id}/secrets/sgp.integrations` com `erp: "ixc"`; provedores SGP mantêm o formato antigo.

## Tabelas e permissões do token (somente leitura)

| Função do app | Tabelas IXC |
|---|---|
| Login, contratos, plano, endereço | `cliente`, `cliente_contrato`, `vd_contratos`, `cidade` |
| Faturas, 2ª via, valor em aberto | `fn_areceber` |
| Online/offline e consumo mensal | `radusuarios`, `radacct` |
| Sinal da ONU / diagnóstico | `radpop_radio_cliente_fibra`, `radpop_radio` |
| Sincronização de clientes | `cliente`, `cliente_contrato` |
| Liberação em confiança (escrita) | `desbloqueio_confianca` |

Sem acesso a `fn_areceber` o login continua; valor e vencimento ficam desconhecidos (`null`) e a
lista de faturas devolve erro claro. `IXC_DISABLE_WRITES=true` desliga a liberação em confiança.

## Particularidades do IXC tratadas

- `cliente.cnpj_cpf` é gravado **formatado**; a busca tenta formatado e depois só dígitos.
- Datas misturam `YYYY-MM-DD` e `DD/MM/YYYY`; zero-dates (`0000-00-00`) viram `null`.
- `status_internet`: `A` ativo, `CM` bloqueio manual, `CA` bloqueio automático, `FA` atraso
  financeiro, `AA` aguardando assinatura, `D` desativado. `status` do contrato: `I`/`D` não entram no app.
- Consumo vem de `radacct` (Output = download, Input = upload) filtrado por mês.
- Todo contrato usado é conferido contra o CPF do assinante antes de qualquer consulta.

## Limitações conhecidas

- **PIX copia e cola:** o IXC não expõe o payload EMV em `fn_areceber` (só `pix_txid`); o app mostra
  boleto (`linha_digitavel`) e `gateway_link` quando o provedor usa gateway.
- **Wi-Fi/CPE e TR-069:** retornam 501 para IXC (fora do escopo desta entrega).
- **Liberação em confiança:** implementada e coberta por teste com IXC simulado; não foi executada
  em IXC real para não alterar contrato de cliente.
