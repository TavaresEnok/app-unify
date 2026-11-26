'use strict';
// Traduz erros internos/ERP em respostas claras para o assinante e o suporte.
// Nunca expõe detalhes técnicos; só repassa a mensagem do próprio ERP (4xx).

const UNREACHABLE = 'Não conseguimos falar com o sistema do provedor agora. Tente novamente em instantes.';
const CONTRACT_NOT_FOUND = 'Contrato não encontrado para este CPF/CNPJ.';

function publicError(error, fallback = 'Erro interno.') {
    if (!error) return { status: 502, message: fallback };
    if (error.dnsFailure || error.code === 'dns-unavailable') return { status: 503, message: UNREACHABLE };
    if (error.publicMessage) return { status: error.status || 502, message: error.publicMessage };
    const upstreamStatus = error.response && error.response.status;
    if (error.sgpMessage && upstreamStatus >= 400 && upstreamStatus < 500) return { status: 422, message: error.sgpMessage };
    if (error.status === 404 || error.notFound) return { status: 404, message: CONTRACT_NOT_FOUND };
    if (error.status === 409 || error.status === 400 || error.status === 429) return { status: error.status, message: error.message || fallback };
    if (error.status === 503 || error.connectionFailure || upstreamStatus >= 500) return { status: 503, message: UNREACHABLE };
    return { status: error.status || 502, message: fallback };
}

function sendPublicError(res, error, fallback) {
    const mapped = publicError(error, fallback);
    return res.status(mapped.status).json({ error: { message: mapped.message } });
}

module.exports = { publicError, sendPublicError, UNREACHABLE, CONTRACT_NOT_FOUND };
