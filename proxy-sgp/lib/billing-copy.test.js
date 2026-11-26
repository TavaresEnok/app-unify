const test = require('node:test');
const assert = require('node:assert/strict');
const { billingPushMessage } = require('./billing-copy');

test('sem texto do provedor usa o automático', () => {
    assert.match(billingPushMessage(1, '99,90').body, /vence amanhã/);
});

test('texto do provedor troca {valor} e {quando}', () => {
    const copy = billingPushMessage(3, '99,90', 'Olá! Sua fatura de {valor} vence {quando}. Equipe Vibe');
    assert.equal(copy.title, 'Fatura vence em 3 dias');
    assert.equal(copy.body, 'Olá! Sua fatura de R$ 99,90 vence em 3 dias. Equipe Vibe');
    assert.equal(billingPushMessage(-2, '10,00', 'Atraso {quando}').body, 'Atraso há 2 dias');
});

test('o texto de exemplo antigo do painel não substitui o automático', () => {
    assert.match(billingPushMessage(0, '50,00', 'Lembrete: Sua fatura está próxima do vencimento.').body, /vence hoje/);
});
