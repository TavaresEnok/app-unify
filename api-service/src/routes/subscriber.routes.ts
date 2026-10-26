import { Router, type Request } from "express";
import { URLSearchParams } from "node:url";
import { env } from "../config/env";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter } from "../middlewares/rateLimits";
import {
  createSgpSession,
  externalErrorMessage,
  requireSgpCredentials,
  resolveContractCredentials,
} from "../services/sgpClient";

export const subscriberRouter = Router();
subscriberRouter.use(sgpLimiter);
// Todas as rotas de assinante exigem autenticação (verifyToken por rota — o
// router é montado na raiz, então middleware de router-level rodaria também em
// rotas não correspondentes como /health e 404). Sem isto, qualquer anônimo
// poderia colher PII e instrumentos de pagamento (linha digitável/PIX) e até
// disparar promessas de pagamento informando um CPF arbitrário no corpo.

// O uid do token de assinante é o CPF/CNPJ (somente dígitos). Admins
// (superAdmin/providerAdmin) podem consultar qualquer CPF do seu escopo; um
// assinante só pode acessar o próprio CPF.
function cpfFrom(req: Request): string {
  const cpf = typeof req.body?.cpfCnpj === "string" ? req.body.cpfCnpj.trim() : "";
  if (!cpf) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");
  const isAdmin = req.user?.superAdmin === true || typeof req.user?.providerId === "string";
  if (!isAdmin && req.user?.uid !== cpf.replace(/\D/g, "")) {
    throw new ApiError(403, "Você só pode acessar os seus próprios dados.", "permission-denied");
  }
  return cpf;
}

// Loga o detalhe do erro upstream no servidor e devolve uma mensagem genérica —
// sem vazar texto/estruturas internas do SGP para o cliente (M5).
function upstreamError(req: Request, message: string, error: unknown): ApiError {
  console.warn(JSON.stringify({
    severity: "WARNING",
    message,
    correlationId: req.correlationId,
    error: externalErrorMessage(error, "SGP indisponível"),
  }));
  return new ApiError(502, message, "upstream-error");
}

subscriberRouter.post("/getClientData", verifyToken, asyncRoute(async (req, res) => {
  requireSgpCredentials();
  const cpfCnpj = cpfFrom(req);
  const session = createSgpSession();
  try {
    const { contrato, contratoId, senhaCentral } = await resolveContractCredentials(session, cpfCnpj);
    let connectionStatus = "Offline";
    if (senhaCentral) {
      try {
        const response = await session.post(`${env.sgpBaseUrl}/api/central/verificaacesso/`, {
          cpfcnpj: cpfCnpj.replace(/\D/g, ""), senha: senhaCentral, contrato: contratoId,
        });
        const data = response.data;
        if (data?.online === true || data?.online === 1 || data?.online === "1" ||
          ["online", "ativo"].includes(String(data?.status || "").toLowerCase()) ||
          data?.disponivel === true || data?.disponivel === 1 || data?.ativo === true || data?.ativo === 1) {
          connectionStatus = "Online";
        }
      } catch (error) {
        console.warn(JSON.stringify({ severity: "WARNING", message: "Falha ao consultar status do contrato", correlationId: req.correlationId, error: externalErrorMessage(error, "SGP indisponível") }));
      }
    }
    const now = new Date();
    res.json({ data: {
      cpfCnpj: contrato.cpfCnpj || cpfCnpj,
      userName: contrato.razaoSocial || contrato.nome || "Cliente",
      userPlan: contrato.servico_plano || contrato.plano || "Plano não informado",
      userStatus: connectionStatus,
      billValue: `R$ ${Number(contrato.contratoValorAberto || 0).toFixed(2).replace(".", ",")}`,
      billDueDate: `Vence em ${contrato.cobVencimento || "-"}/${now.getMonth() + 1}/${now.getFullYear()}`,
      contratoId,
    } });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar dados do cliente.", error);
  }
}));

subscriberRouter.post("/getConsumptionData", verifyToken, asyncRoute(async (req, res) => {
  requireSgpCredentials();
  const cpfCnpj = cpfFrom(req);
  const session = createSgpSession();
  try {
    const { contratoId, senhaCentral } = await resolveContractCredentials(session, cpfCnpj);
    const senha = senhaCentral;
    if (!senha) throw new ApiError(503, "Credencial do contrato indisponível para consulta de consumo.", "service-unavailable");
    const now = new Date();
    const form = new URLSearchParams({
      cpfcnpj: cpfCnpj,
      senha,
      contrato: String(contratoId),
      mes: String(now.getMonth() + 1),
      ano: String(now.getFullYear()),
    });
    const response = await session.post(`${env.sgpBaseUrl}/api/central/extratouso/`, form);
    const bytes = Number(response.data?.total || 0);
    const plan = String(response.data?.plano || "Plano não informado");
    const quota = plan.match(/(\d+)/);
    res.json({ data: {
      totalGb: quota ? Number(quota[1]) : 1000,
      usedGb: bytes / (1024 ** 3),
      averageSpeed: "N/A",
      period: `${String(now.getMonth() + 1).padStart(2, "0")}/${now.getFullYear()}`,
    } });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar consumo.", error);
  }
}));

subscriberRouter.post("/getInvoices", verifyToken, asyncRoute(async (req, res) => {
  requireSgpCredentials();
  const cpfCnpj = cpfFrom(req);
  const session = createSgpSession();
  const payload = { token: env.sgpToken, app: env.sgpAppName, cpfcnpj: cpfCnpj };
  try {
    const [open, paid] = await Promise.all([
      session.post(`${env.sgpBaseUrl}/api/ura/titulos/`, { ...payload, status: "abertos" }),
      session.post(`${env.sgpBaseUrl}/api/ura/titulos/`, { ...payload, status: "pagos" }),
    ]);
    const format = (invoice: any, pago: boolean) => ({
      pago,
      vencimento: invoice.dataVencimento,
      valor: Number(invoice.valor || 0).toFixed(2).replace(".", ","),
      linha_digitavel: invoice.linhaDigitavel,
      linha_digitavel_pix: invoice.codigoPix,
      link: invoice.link,
      id: invoice.id,
      numero_documento: invoice.numeroDocumento,
    });
    const opens = Array.isArray(open.data?.titulos) ? open.data.titulos.map((item: any) => format(item, false)) : [];
    const paids = Array.isArray(paid.data?.titulos) ? paid.data.titulos.map((item: any) => format(item, true)) : [];
    res.json({ data: [...opens, ...paids] });
  } catch (error) {
    throw upstreamError(req, "Erro ao buscar faturas.", error);
  }
}));

subscriberRouter.post("/makePaymentPromise", verifyToken, asyncRoute(async (req, res) => {
  requireSgpCredentials();
  const cpfCnpj = cpfFrom(req);
  const session = createSgpSession();
  try {
    const { contratoId } = await resolveContractCredentials(session, cpfCnpj);
    const response = await session.post(`${env.sgpBaseUrl}/api/ura/liberacaopromessa/`, {
      token: env.sgpToken, app: env.sgpAppName, contrato: contratoId,
    });
    if (response.data?.status === false) throw new ApiError(409, response.data.msg || "Não foi possível realizar a promessa.", "upstream-rejected");
    res.json({ success: true, message: response.data?.msg || "Promessa de pagamento realizada com sucesso!" });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao realizar promessa.", error);
  }
}));
