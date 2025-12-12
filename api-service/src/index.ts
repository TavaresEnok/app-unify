import express from 'express';
import cors from 'cors';
import axios from 'axios';
import * as https from 'https';

const app = express();
// <-- MUDANÇA: Porta alterada para 9136 para corresponder ao seu ambiente.
const port = 9136; 

app.use(cors());
app.use(express.json());

// ATENÇÃO: Configure estas variáveis no seu ambiente de servidor!
const SGP_TOKEN = process.env.SGP_TOKEN || "SEU_TOKEN_AQUI";
const SGP_APP_NAME = process.env.SGP_APP_NAME || "SEU_APP_NAME_AQUI";

// Endpoint para dados do cliente (Login) - Sem alterações
app.post('/getClientData', async (req, res) => {
  try {
    const { cpfCnpj } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }
    if (!SGP_TOKEN || !SGP_APP_NAME) {
      throw new Error("Credenciais do SGP não configuradas no servidor.");
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' }
    });

    const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
    });

    if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
      throw new Error("Nenhum contrato encontrado para este cliente.");
    }
    
    const contrato = consultaResponse.data.contratos[0];
    const hoje = new Date();
    const mesAtual = hoje.getMonth() + 1;
    const anoAtual = hoje.getFullYear();

    const clientData = {
        cpfCnpj: contrato.cpfCnpj,
        senha: contrato.contratoCentralSenha,
        userName: contrato.razaoSocial,
        userPlan: contrato.servico_plano,
        userStatus: contrato.contratoStatusDisplay,
        billValue: `R$ ${parseFloat(contrato.contratoValorAberto || 0).toFixed(2).replace('.', ',')}`,
        billDueDate: `Vence em ${contrato.cobVencimento}/${mesAtual}/${anoAtual}`,
    };

    res.json({ data: clientData });

  } catch (error: any) {
    console.error("Erro detalhado na getClientData:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao buscar dados do cliente: ${errorMessage}` } });
  }
});


// =========================================================================
// CORREÇÃO APLICADA AQUI
// =========================================================================
app.post('/getConsumptionData', async (req, res) => {
    try {
        const { cpfCnpj, senha } = req.body;
        if (!cpfCnpj || !senha) {
            return res.status(400).json({ error: { message: "CPF/CNPJ e Senha da Central são obrigatórios." } });
        }

        const baseUrl = "https://vibetelecom.sgp.net.br";
        const session = axios.create({
            httpsAgent: new https.Agent({ rejectUnauthorized: false }),
            headers: { 'User-Agent': 'Mozilla/5.0' }
        });
      
        // --- ETAPA 1: USAR O MÉTODO CONFIÁVEL PARA OBTER O ID DO CONTRATO ---
        // Em vez de usar /api/central/contratos, usamos o mesmo endpoint do login, que é mais robusto.
        const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
            token: SGP_TOKEN,
            app: SGP_APP_NAME,
            cpfcnpj: cpfCnpj,
        });

        if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
            throw new Error("Nenhum contrato encontrado para este cliente.");
        }
        
        // Agora pegamos o ID do contrato de forma confiável
        const contratoId = consultaResponse.data.contratos[0].contratoId;

        // --- ETAPA 2: CONTINUAR COM A BUSCA DO EXTRATO, AGORA COM O ID CORRETO ---
        const hoje = new Date();
        const mes = hoje.getMonth() + 1;
        const ano = hoje.getFullYear();

        const extratoPayload = new URLSearchParams();
        extratoPayload.append('cpfcnpj', cpfCnpj);
        extratoPayload.append('senha', senha);
        extratoPayload.append('contrato', contratoId.toString()); // Garantir que é string
        extratoPayload.append('mes', mes.toString());
        extratoPayload.append('ano', ano.toString());

        const extratoResponse = await session.post(`${baseUrl}/api/central/extratouso/`, extratoPayload);
        
        const consumoData = extratoResponse.data;

        const totalBytes = consumoData.total as number || 0;
        const usedGb = totalBytes / (1024 * 1024 * 1024);

        const planoCliente = consumoData.plano || "Plano não informado";
        // Lógica para extrair o total de GB do nome do plano (ex: "VIBE 500 MEGA")
        const match = planoCliente.match(/(\d+)/);
        // Se não encontrar um número, assume um valor alto para o gráfico não quebrar.
        const totalGb = match ? parseFloat(match[1]) : 1000; 

        const realData = {
            totalGb: totalGb,
            usedGb: usedGb,
            averageSpeed: "N/A", // API não fornece essa informação
            period: `${mes.toString().padStart(2, '0')}/${ano}`,
        };

        res.json({ data: realData });

    } catch (error: any) {
        console.error("Erro detalhado na getConsumptionData:", error.response?.data || error.message);
        const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
        res.status(500).json({ error: { message: `Erro ao buscar dados de consumo: ${errorMessage}` } });
    }
});


// Endpoint de Faturas
app.post('/getInvoices', async (req, res) => {
  try {
    const { cpfCnpj } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' }
    });
    
    const responseAbertos = await session.post(`${baseUrl}/api/ura/titulos/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
      status: 'abertos'
    });

    const titulos = responseAbertos.data?.titulos;
    let formattedInvoices: any[] = [];

    if (titulos && Array.isArray(titulos)) {
        formattedInvoices = titulos.map((invoice: any) => ({
            pago: invoice.dataPagamento !== null && invoice.dataPagamento !== "",
            vencimento: invoice.dataVencimento,
            valor: parseFloat(invoice.valor || 0).toFixed(2).replace('.', ','),
            linha_digitavel: invoice.linhaDigitavel,
            linha_digitavel_pix: invoice.codigoPix,
            link: invoice.link,
            id: invoice.id,
            numero_documento: invoice.numeroDocumento,
        }));
    }

    const responsePagos = await session.post(`${baseUrl}/api/ura/titulos/`, {
        token: SGP_TOKEN,
        app: SGP_APP_NAME,
        cpfcnpj: cpfCnpj,
        status: 'pagos'
      });
    
    const titulosPagos = responsePagos.data?.titulos;
    if (titulosPagos && Array.isArray(titulosPagos)) {
        const formattedPagos = titulosPagos.map((invoice: any) => ({
            pago: true,
            vencimento: invoice.dataVencimento,
            valor: parseFloat(invoice.valor || 0).toFixed(2).replace('.', ','),
            linha_digitavel: invoice.linhaDigitavel,
            linha_digitavel_pix: invoice.codigoPix,
            link: invoice.link,
            id: invoice.id,
            numero_documento: invoice.numeroDocumento,
        }));
        formattedInvoices.push(...formattedPagos);
    }

    res.json({ data: formattedInvoices });

  } catch (error: any) {
    console.error("Erro detalhado na getInvoices:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao buscar faturas: ${errorMessage}` } });
  }
});

// Endpoint para Promessa de Pagamento
app.post('/makePaymentPromise', async (req, res) => {
  try {
    const { cpfCnpj } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }

    if (!SGP_TOKEN || !SGP_APP_NAME) {
      throw new Error("Credenciais do SGP não configuradas no servidor.");
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' }
    });

    const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
    });

    if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
      throw new Error("Contrato não encontrado para este cliente.");
    }
    const contratoId = consultaResponse.data.contratos[0].contratoId;

    const promessaResponse = await session.post(`${baseUrl}/api/ura/liberacaopromessa/`, {
        token: SGP_TOKEN,
        app: SGP_APP_NAME,
        contrato: contratoId
    });

    if (promessaResponse.data?.status === false) {
        throw new Error(promessaResponse.data.msg || "O SGP retornou um erro ao tentar realizar a promessa.");
    }

    res.json({ 
        success: true, 
        message: promessaResponse.data.msg || "Promessa de pagamento realizada com sucesso!" 
    });

  } catch (error: any) {
    console.error("Erro detalhado na makePaymentPromise:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao realizar promessa: ${errorMessage}` } });
  }
});


app.listen(port, () => {
  console.log(`✅ API Service a rodar na porta ${port}`);
});
