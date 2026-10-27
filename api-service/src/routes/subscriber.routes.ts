import { Router, type Request } from "express";
import { URLSearchParams } from "node:url";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter } from "../middlewares/rateLimits";
import {
  createSgpSession,
  externalErrorMessage,
  listContracts,
  pickContracts,
  resolveSgpCredentials,
  type SgpContract,
} from "../services/sgpClient";
import { providerOfCpf } from "../services/tenantScope";

export const subscriberRouter = Router();
subscriberRouter.use(sgpLimiter);
// Todas as rotas de assinante exigem autenticação (verifyToken por rota — o
// router é montado na raiz, então middleware de router-level rodaria também em
// rotas não correspondentes como /health e 404). Sem isto, qualquer anônimo
// poderia colher PII e instrumentos de pagamento (linha digitável/PIX) e até
// disparar promessas de pagamento informando um CPF arbitrário no corpo.

interface SubscriberContext {
  cpfCnpj: string;
  providerId?: string;
}

/**
 * Resolve o CPF alvo e o provedor dono dele, cujo SGP será consultado.
 *
 * - assinante (uid = CPF em dígitos): só o próprio CPF; provedor do claim do
 *   token ou, para tokens legados, de `clientes/{cpf}`.
 * - providerAdmin: só CPFs cujo `clientes/{cpf}.providerId` seja o seu.
 * - superAdmin: qualquer CPF; `providerId` do corpo ou de `clientes/{cpf}`.
 */
async function subscriberContext(req: Request): Promise<SubscriberContext> {
  const cpfCnpj = typeof req.body?.cpfCnpj === "string" ? req.body.cpfCnpj.trim() : "";
  if (!cpfCnpj) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");
  const digits = cpfCnpj.replace(/\D/g, "");
  const user = req.user;

  if (user?.superAdmin === true) {
    const fromBody = typeof req.body?.providerId === "string" && req.body.providerId ? req.body.providerId : undefined;
    return { cpfCnpj, providerId: fromBody || await providerOfCpf(digits) };
  }
  if (user && user.uid === digits) {
    const claim = typeof user.providerId === "string" && user.providerId ? user.providerId : undefined;
    return { cpfCnpj, providerId: claim || await providerOfCpf(digits) };
  }
  if (typeof user?.providerId === "string") {
    const owner = await providerOfCpf(digits);
    if (!owner || owner !== user.providerId) {
      throw new ApiError(403, "Este cliente não pertence ao seu provedor.", "permission-denied");
    }
    return { cpfCnpj, providerId: owner };
  }
  throw new ApiError(403, "Você só pode acessar os seus próprios dados.", "permission-denied");
}

async function sgpForRequest(req: Request) {
  const context = await subscriberContext(req);
  const credentials = await resolveSgpCredentials(context.providerId);
  if (!credentials.providerId) {
    console.warn(JSON.stringify({ severity: "WARNING", message: "Provedor do CPF não identificado; usando SGP global", correlationId: req.correlationId }));
  }
  return { ...context, credentials, session: createSgpSession() };
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

function money(value: unknown): string {
  return `R$ ${Number(value || 0).toFixed(2).replace(".", ",")}`;
}

function openValue(item: SgpContract): number {
  return Number(item.contrato.contratoValorAberto || 0);
}

function contractSummary(item: SgpContract) {
  return {
    contratoId: item.contratoId,
    plano: item.contrato.servico_plano || item.contrato.plano || "Plano não informado",
    status: item.contrato.contratoStatusDisplay || item.contrato.contratoStatus || null,
    valorAberto: money(openValue(item)),
    vencimento: item.contrato.cobVencimento || null,
  };
}

subscriberRouter.post("/getClientData", verifyToken, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  try {
    const contracts = await listContracts(session, credentials, cpfCnpj);
    // Campos de topo descrevem o contrato pedido (ou o primeiro), como antes;
    // `contratos` traz todos para o app oferecer a troca.
    const [selected] = pickContracts(contracts, req.body?.contratoId);
    const { contrato, contratoId, senhaCentral } = selected;
    let connectionStatus = "Offline";
    if (senhaCentral) {
      try {
        const response = await session.post(`${credentials.baseUrl}/api/central/verificaacesso/`, {
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
      billValue: money(contrato.contratoValorAberto),
      billDueDate: `Vence em ${contrato.cobVencimento || "-"}/${now.getMonth() + 1}/${now.getFullYear()}`,
      contratoId,
      totalAberto: money(contracts.reduce((sum, item) => sum + openValue(item), 0)),
      contratos: contracts.map(contractSummary),
    } });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar dados do cliente.", error);
  }
}));

subscriberRouter.post("/getConsumptionData", verifyToken, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  try {
    const contracts = pickContracts(await listContracts(session, credentials, cpfCnpj), req.body?.contratoId)
      .filter((item) => item.senhaCentral);
    if (!contracts.length) throw new ApiError(503, "Credencial do contrato indisponível para consulta de consumo.", "service-unavailable");
    const now = new Date();
    const usage = await Promise.all(contracts.map(async (item) => {
      const form = new URLSearchParams({
        cpfcnpj: cpfCnpj,
        senha: item.senhaCentral,
        contrato: item.contratoId,
        mes: String(now.getMonth() + 1),
        ano: String(now.getFullYear()),
      });
      const response = await session.post(`${credentials.baseUrl}/api/central/extratouso/`, form);
      const quota = String(response.data?.plano || "").match(/(\d+)/);
      return {
        contratoId: item.contratoId,
        totalGb: quota ? Number(quota[1]) : 1000,
        usedGb: Number(response.data?.total || 0) / (1024 ** 3),
      };
    }));
    res.json({ data: {
      totalGb: usage.reduce((sum, item) => sum + item.totalGb, 0),
      usedGb: usage.reduce((sum, item) => sum + item.usedGb, 0),
      averageSpeed: "N/A",
      period: `${String(now.getMonth() + 1).padStart(2, "0")}/${now.getFullYear()}`,
      contratos: usage,
    } });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar consumo.", error);
  }
}));

subscriberRouter.post("/getInvoices", verifyToken, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  // Sem `contratoId`, o SGP devolve os títulos de todos os contratos do CPF.
  const payload: Record<string, string> = { token: credentials.token, app: credentials.app, cpfcnpj: cpfCnpj };
  try {
    if (req.body?.contratoId) {
      const [selected] = pickContracts(await listContracts(session, credentials, cpfCnpj), req.body.contratoId);
      payload.contrato = selected.contratoId;
    }
    const [open, paid] = await Promise.all([
      session.post(`${credentials.baseUrl}/api/ura/titulos/`, { ...payload, status: "abertos" }),
      session.post(`${credentials.baseUrl}/api/ura/titulos/`, { ...payload, status: "pagos" }),
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
      contratoId: invoice.contrato ?? invoice.contratoId ?? null,
    });
    const opens = Array.isArray(open.data?.titulos) ? open.data.titulos.map((item: any) => format(item, false)) : [];
    const paids = Array.isArray(paid.data?.titulos) ? paid.data.titulos.map((item: any) => format(item, true)) : [];
    res.json({ data: [...opens, ...paids] });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar faturas.", error);
  }
}));

subscriberRouter.post("/makePaymentPromise", verifyToken, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  try {
    const contracts = await listContracts(session, credentials, cpfCnpj);
    // Sem contrato informado: todos os contratos com valor em aberto (antes só
    // o primeiro era liberado, e o assinante seguia bloqueado nos demais).
    let targets = pickContracts(contracts, req.body?.contratoId);
    if (!req.body?.contratoId) {
      const withDebt = targets.filter((item) => openValue(item) > 0);
      if (withDebt.length) targets = withDebt;
    }
    const resultados: Array<{ contratoId: string; success: boolean; message: string }> = [];
    for (const item of targets) {
      const response = await session.post(`${credentials.baseUrl}/api/ura/liberacaopromessa/`, {
        token: credentials.token, app: credentials.app, contrato: item.contratoId,
      });
      const success = response.data?.status !== false;
      resultados.push({
        contratoId: item.contratoId,
        success,
        message: response.data?.msg || (success ? "Promessa de pagamento realizada com sucesso!" : "Não foi possível realizar a promessa."),
      });
    }
    if (!resultados.some((item) => item.success)) throw new ApiError(409, resultados[0].message, "upstream-rejected");
    res.json({ success: true, message: resultados.find((item) => item.success)!.message, resultados });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao realizar promessa.", error);
  }
}));
