(function (root) {
    'use strict';
    // Only an explicitly configured HTTPS contact page may be opened. The email
    // stays in the field and is never added to the URL, stored or logged.
    function contactDestination(raw) {
        try {
            const url = new URL(raw);
            if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) return null;
            if (!url.hostname.includes('.') || /^(localhost|127\.|0\.|\[)/i.test(url.hostname)) return null;
            return url.href;
        } catch { return null; }
    }
    function initContactForm(doc = root.document, open = (...args) => root.open(...args)) {
        const form = doc.getElementById('contactForm');
        if (!form) return;
        const status = doc.getElementById('contactStatus');
        const button = form.querySelector('button');
        const destination = contactDestination(form.dataset.contactUrl || '');
        const unavailable = 'Contato indisponível: canal comercial ainda não validado.';
        status.textContent = destination ? 'Abrir contato externo não comprova envio ou recebimento.' : unavailable;
        button.textContent = destination ? 'Abrir contato externo' : 'Contato indisponível';
        form.addEventListener('submit', event => {
            event.preventDefault();
            if (!destination) { status.textContent = unavailable; return; }
            try {
                const opened = open(destination, '_blank');
                if (!opened) throw new Error('blocked');
                opened.opener = null;
                status.textContent = 'Contato externo aberto. Nenhuma mensagem foi enviada por este formulário; confirme o envio e recebimento no canal externo.';
            } catch {
                status.textContent = 'Não foi possível abrir o contato externo. Seu campo foi preservado.';
            }
        });
    }
    if (typeof module !== 'undefined' && module.exports) module.exports = { initContactForm, contactDestination };
    else root.initContactForm = initContactForm;
})(typeof window === 'undefined' ? globalThis : window);
