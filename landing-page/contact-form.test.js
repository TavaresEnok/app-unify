const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const { initContactForm, contactDestination } = require('./contact-form');

// EventTarget harness executes the actual submit listener with cancelable browser
// events; no timers, network, persistence or fake success handler are substituted.
function harness(destination = '', open = () => { throw new Error('Unexpected open'); }) {
    const form = new EventTarget();
    const field = { value: 'synthetic@example.test' };
    const button = { textContent: '' };
    const status = { textContent: '' };
    form.dataset = { contactUrl: destination };
    form.querySelector = selector => selector === 'button' ? button : field;
    form.reset = () => { throw new Error('Must preserve field'); };
    const document = { getElementById: id => id === 'contactForm' ? form : status };
    initContactForm(document, open);
    return { form, field, button, status, submit() {
        const event = new Event('submit', { cancelable: true });
        form.dispatchEvent(event); assert.equal(event.defaultPrevented, true);
    } };
}
test('absent or invalid destination stays unavailable and preserves field', () => {
    for (const url of ['', 'bad', 'javascript:alert(1)', 'http://commercial.example.test', 'https://u:p@commercial.example.test', 'https://commercial.example.test/?email=x', 'https://127.0.0.1', 'https://localhost']) {
        assert.equal(contactDestination(url), null);
        const ui = harness(url); ui.submit();
        assert.match(ui.status.textContent, /indisponível/);
        assert.equal(ui.field.value, 'synthetic@example.test');
        assert.doesNotMatch(ui.status.textContent, /Enviado!|Obrigado|agendad/);
    }
});
test('external opening success or failure never claims a message was sent, and never forwards email', () => {
    for (const outcome of ['allowed', 'blocked', 'throw']) {
        const calls = [], popup = { opener: {} };
        const ui = harness('https://commercial.example.test/contact', (...args) => {
            calls.push(args); if (outcome === 'throw') throw new Error('synthetic');
            return outcome === 'allowed' ? popup : null;
        });
        ui.submit();
        assert.deepEqual(calls, [['https://commercial.example.test/contact', '_blank']]);
        assert.equal(ui.field.value, 'synthetic@example.test');
        assert.ok(!JSON.stringify(calls).includes(ui.field.value));
        if (outcome === 'allowed') {
            assert.equal(popup.opener, null);
            assert.match(ui.status.textContent, /Nenhuma mensagem foi enviada/);
        } else assert.match(ui.status.textContent, /Não foi possível abrir/);
    }
});
test('HTML loads the browser contact module before the landing initializer, without a configured channel', () => {
    const html = readFileSync(__dirname + '/index.html', 'utf8');
    assert.match(html, /data-contact-url=""/);
    assert.ok(html.indexOf('src="contact-form.js"') < html.indexOf('src="script.js"'));
    const window = {};
    vm.runInNewContext(readFileSync(__dirname + '/contact-form.js', 'utf8'), { window, URL });
    assert.equal(typeof window.initContactForm, 'function');
});
