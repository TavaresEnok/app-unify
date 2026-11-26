'use strict';
// Regras de segurança da sincronização de clientes e dos reenvios de jobs.

// Só apaga clientes "sumidos" quando a sincronização parece completa: trouxe
// pelo menos 80% do que o ERP diz ter e 80% da última contagem boa. Uma
// resposta curta ou com paginação quebrada nunca apaga a base inteira.
function shouldPrune({ count, fetched, erpTotal, previousCount, ratio = 0.8 }) {
    if (!(count > 0)) return { prune: false, reason: 'empty-sync' };
    const total = Number(erpTotal);
    if (Number.isFinite(total) && total > 0 && Number(fetched || 0) < total * ratio) {
        return { prune: false, reason: 'below-erp-total' };
    }
    const previous = Number(previousCount);
    if (Number.isFinite(previous) && previous > 0 && count < previous * ratio) {
        return { prune: false, reason: 'below-previous-count' };
    }
    return { prune: true, reason: 'complete' };
}

function transientError(error) {
    if (!error) return false;
    if (error.response && error.response.status >= 400 && error.response.status < 500) return false;
    return error.status === 503 || error.dnsFailure === true || error.connectionFailure === true || !error.response;
}

// Repete a mesma página até 3 vezes em falhas de rede/ERP antes de desistir,
// em vez de gastar as tentativas do job inteiro (dezenas de páginas).
async function withPageRetry(operation, { attempts = 3, delays = [1000, 3000], sleep = ms => new Promise(r => setTimeout(r, ms)) } = {}) {
    let lastError;
    for (let attempt = 0; attempt < attempts; attempt++) {
        try { return await operation(); } catch (error) {
            lastError = error;
            if (!transientError(error) || attempt === attempts - 1) throw error;
            await sleep(delays[Math.min(attempt, delays.length - 1)]);
        }
    }
    throw lastError;
}

// Reagendamento de jobs em 503: espera crescente e um limite. Depois de
// ~30 min tentando, o job falha de verdade em vez de girar para sempre.
const MAX_DELAYS = 25;
function nextDelay(delayedCount, random = Math.random) {
    const n = Math.max(0, Number(delayedCount) || 0);
    if (n >= MAX_DELAYS) return null;
    return Math.min(90000, 1500 * 2 ** Math.min(n, 6)) + Math.floor(random() * 1000);
}

// Falha de sync fica visível no log sem dados do ERP: só job, provedor e HTTP.
function syncFailureLog(job, error) {
    const status = Number(error?.response?.status || error?.status) || null;
    return JSON.stringify({ event: 'sync.failed', id: job?.id ?? null, providerId: job?.data?.providerId ?? null, status });
}

module.exports = { shouldPrune, withPageRetry, transientError, nextDelay, syncFailureLog, MAX_DELAYS };
