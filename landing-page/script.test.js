const test = require('node:test');
const assert = require('node:assert/strict');
const { whatsappLink } = require('./script.js');

test('monta o link do WhatsApp só com número válido', () => {
    assert.equal(whatsappLink('+55 (88) 99999-0000', 'Olá! Quero conhecer'),
        'https://wa.me/5588999990000?text=Ol%C3%A1!%20Quero%20conhecer');
    assert.equal(whatsappLink('5588999990000'), 'https://wa.me/5588999990000');
});

test('sem número, ou com número impossível, não gera link', () => {
    for (const value of ['', undefined, '123', 'javascript:alert(1)', '9'.repeat(16)]) {
        assert.equal(whatsappLink(value, 'x'), null);
    }
});
