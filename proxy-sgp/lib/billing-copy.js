'use strict';

// Texto padrão que o painel salvava antes: não conta como personalizado.
const PANEL_PLACEHOLDER = 'lembrete: sua fatura está próxima do vencimento.';

function whenLabel(offsetDays) {
    if (offsetDays > 1) return `em ${offsetDays} dias`;
    if (offsetDays === 1) return 'amanhã';
    if (offsetDays === 0) return 'hoje';
    const overdue = Math.abs(offsetDays);
    return `há ${overdue} ${overdue === 1 ? 'dia' : 'dias'}`;
}

/**
 * Texto do lembrete de fatura. O título é sempre o automático (diz quando
 * vence); o corpo usa o texto do provedor (Mensagens → Lembrete de fatura)
 * quando ele escreveu um, trocando {valor} e {quando}.
 */
function billingPushMessage(offsetDays, formattedValue, customBody) {
    const when = whenLabel(offsetDays);
    let copy;
    if (offsetDays > 1) {
        copy = { title: `Fatura vence em ${offsetDays} dias`,
            body: `Sua fatura de R$ ${formattedValue} vence em ${offsetDays} dias. Pague via PIX ou boleto pelo app.` };
    } else if (offsetDays === 1) {
        copy = { title: 'Fatura vencendo amanhã',
            body: `Sua fatura de R$ ${formattedValue} vence amanhã. Toque para pagar com PIX ou boleto.` };
    } else if (offsetDays === 0) {
        copy = { title: 'Sua fatura vence hoje',
            body: `Evite bloqueio: sua fatura de R$ ${formattedValue} vence hoje. Pague em segundos pelo app.` };
    } else {
        const overdue = Math.abs(offsetDays);
        copy = { title: `Fatura em aberto há ${overdue} ${overdue === 1 ? 'dia' : 'dias'}`,
            body: `Identificamos uma fatura de R$ ${formattedValue} em aberto. Regularize ou faça promessa de pagamento no app.` };
    }
    const custom = typeof customBody === 'string' ? customBody.replace(/\s+/g, ' ').trim().slice(0, 200) : '';
    if (custom && custom.toLowerCase() !== PANEL_PLACEHOLDER) {
        copy.body = custom.replace(/\{valor\}/gi, `R$ ${formattedValue}`).replace(/\{quando\}/gi, when);
    }
    return copy;
}

module.exports = { billingPushMessage };
