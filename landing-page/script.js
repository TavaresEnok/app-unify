(function (root) {
    'use strict';

    // Só aceita um número com DDI + DDD (10 a 15 dígitos). O texto vai codificado
    // na URL; nada do visitante é coletado, guardado ou enviado por esta página.
    function whatsappLink(raw, text) {
        const digits = String(raw || '').replace(/\D/g, '');
        if (digits.length < 10 || digits.length > 15) return null;
        return 'https://wa.me/' + digits + (text ? '?text=' + encodeURIComponent(text) : '');
    }

    function initContact(doc) {
        const link = whatsappLink(doc.body.dataset.whatsapp,
            'Olá! Quero conhecer o app Unify para o meu provedor.');
        const buttons = doc.querySelectorAll('[data-whatsapp-link]');
        if (link) {
            buttons.forEach(function (button) {
                button.href = link;
                button.target = '_blank';
                button.rel = 'noopener';
            });
            return;
        }
        // Sem canal configurado: não finge um contato que não existe.
        const notice = doc.getElementById('contato-aviso');
        if (notice) notice.hidden = false;
        const main = doc.querySelector('.contato [data-whatsapp-link]');
        if (main) {
            main.setAttribute('aria-disabled', 'true');
            main.textContent = 'WhatsApp em configuração';
            main.addEventListener('click', function (event) { event.preventDefault(); });
        }
    }

    function initPanelTabs(doc) {
        const tabs = Array.from(doc.querySelectorAll('.painel-abas [role="tab"]'));
        const image = doc.getElementById('painel-imagem');
        const panel = doc.getElementById('tela-painel');
        if (!tabs.length || !image || !panel) return;

        function select(tab, focus) {
            tabs.forEach(function (other) {
                const active = other === tab;
                other.setAttribute('aria-selected', String(active));
                other.tabIndex = active ? 0 : -1;
            });
            image.src = tab.dataset.img;
            image.alt = tab.dataset.alt;
            panel.setAttribute('aria-labelledby', tab.id);
            if (focus) tab.focus();
        }

        tabs.forEach(function (tab, index) {
            tab.addEventListener('click', function () { select(tab, false); });
            tab.addEventListener('keydown', function (event) {
                const step = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[event.key];
                if (!step) return;
                event.preventDefault();
                select(tabs[(index + step + tabs.length) % tabs.length], true);
            });
        });
    }

    if (typeof module === 'object' && module.exports) {
        module.exports = { whatsappLink };
        return;
    }

    initContact(root.document);
    initPanelTabs(root.document);
    const year = root.document.getElementById('ano');
    if (year) year.textContent = String(new Date().getFullYear());
})(typeof window === 'undefined' ? globalThis : window);
