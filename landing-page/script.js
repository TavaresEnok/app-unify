// ===================================
// App Unify Premium Landing Page
// Advanced Interactions & Effects
// ===================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize all modules
    initCursorGlow();
    initMobileMenu();
    initSmoothScroll();
    initNavbarScroll();
    initStatsCounter();
    initFeatureTabs();
    initPricingToggle();
    initFAQ();
    initScrollAnimations();
    initContactForm();
    initTestimonialSlider();

    console.log('🚀 App Unify Premium Landing loaded!');
});

// ===================================
// Cursor Glow Effect
// ===================================
function initCursorGlow() {
    const cursorGlow = document.getElementById('cursorGlow');
    if (!cursorGlow || window.innerWidth < 768) return;

    let mouseX = 0, mouseY = 0;
    let currentX = 0, currentY = 0;

    document.addEventListener('mousemove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
    });

    function animate() {
        // Smooth follow
        currentX += (mouseX - currentX) * 0.1;
        currentY += (mouseY - currentY) * 0.1;

        cursorGlow.style.left = currentX + 'px';
        cursorGlow.style.top = currentY + 'px';

        requestAnimationFrame(animate);
    }

    animate();
}

// ===================================
// Mobile Menu
// ===================================
function initMobileMenu() {
    const toggle = document.getElementById('mobileToggle');
    const navLinks = document.getElementById('navLinks');

    if (!toggle || !navLinks) return;

    toggle.addEventListener('click', () => {
        navLinks.classList.toggle('active');
        toggle.classList.toggle('active');
    });

    // Close on link click
    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            navLinks.classList.remove('active');
            toggle.classList.remove('active');
        });
    });

    // Add mobile menu styles dynamically
    const style = document.createElement('style');
    style.textContent = `
        @media (max-width: 768px) {
            .nav-links.active {
                display: flex;
                flex-direction: column;
                position: absolute;
                top: 100%;
                left: 0;
                right: 0;
                background: rgba(10, 10, 15, 0.98);
                backdrop-filter: blur(20px);
                padding: 24px;
                gap: 16px;
                border-bottom: 1px solid rgba(255,255,255,0.1);
            }
            .mobile-toggle.active span:nth-child(1) {
                transform: rotate(45deg) translate(5px, 5px);
            }
            .mobile-toggle.active span:nth-child(2) {
                opacity: 0;
            }
            .mobile-toggle.active span:nth-child(3) {
                transform: rotate(-45deg) translate(5px, -5px);
            }
        }
    `;
    document.head.appendChild(style);
}

// ===================================
// Smooth Scroll
// ===================================
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const offset = 80; // Navbar height
                const top = target.getBoundingClientRect().top + window.pageYOffset - offset;
                window.scrollTo({ top, behavior: 'smooth' });
            }
        });
    });
}

// ===================================
// Navbar Scroll Effect
// ===================================
function initNavbarScroll() {
    const navbar = document.querySelector('.navbar');
    if (!navbar) return;

    let lastScroll = 0;

    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;

        if (currentScroll > 100) {
            navbar.style.background = 'rgba(10, 10, 15, 0.95)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.3)';
        } else {
            navbar.style.background = 'rgba(10, 10, 15, 0.8)';
            navbar.style.boxShadow = 'none';
        }

        lastScroll = currentScroll;
    });
}

// ===================================
// Stats Counter Animation
// ===================================
function initStatsCounter() {
    const stats = document.querySelectorAll('.stat-number[data-count]');
    if (!stats.length) return;

    const animateCounter = (el) => {
        const target = parseInt(el.dataset.count);
        const duration = 2000;
        const start = performance.now();

        const animate = (currentTime) => {
            const elapsed = currentTime - start;
            const progress = Math.min(elapsed / duration, 1);

            // Easing function for smooth animation
            const easeOutQuart = 1 - Math.pow(1 - progress, 4);
            const current = Math.floor(target * easeOutQuart);

            el.textContent = current.toLocaleString('pt-BR');

            if (progress < 1) {
                requestAnimationFrame(animate);
            } else {
                el.textContent = target.toLocaleString('pt-BR');
            }
        };

        requestAnimationFrame(animate);
    };

    // Intersection Observer for triggering animation
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    stats.forEach(stat => observer.observe(stat));
}

// ===================================
// Feature Tabs
// ===================================
function initFeatureTabs() {
    const tabs = document.querySelectorAll('.feature-tab');
    const panels = document.querySelectorAll('.feature-panel');

    if (!tabs.length || !panels.length) return;

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const tabId = tab.dataset.tab;

            // Update tabs
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');

            // Update panels with fade effect
            panels.forEach(panel => {
                panel.classList.remove('active');
                if (panel.id === `panel-${tabId}`) {
                    panel.classList.add('active');
                    // Trigger animations in panel
                    triggerPanelAnimations(panel);
                }
            });
        });
    });
}

function triggerPanelAnimations(panel) {
    // Reset and replay speed animation
    const speedProgress = panel.querySelector('.speed-progress');
    if (speedProgress) {
        speedProgress.style.animation = 'none';
        speedProgress.offsetHeight; // Trigger reflow
        speedProgress.style.animation = 'speedAnim 2s ease-out forwards';
    }

    // Animate chat bubbles
    const chatBubbles = panel.querySelectorAll('.chat-bubble');
    chatBubbles.forEach((bubble, i) => {
        bubble.style.opacity = '0';
        bubble.style.transform = 'translateY(20px)';
        setTimeout(() => {
            bubble.style.transition = 'all 0.4s ease';
            bubble.style.opacity = '1';
            bubble.style.transform = 'translateY(0)';
        }, i * 200);
    });
}

// ===================================
// Pricing Toggle
// ===================================
function initPricingToggle() {
    const toggle = document.getElementById('pricingToggle');
    const amounts = document.querySelectorAll('.price-amount');

    if (!toggle || !amounts.length) return;

    toggle.addEventListener('change', () => {
        const isYearly = toggle.checked;

        amounts.forEach(amount => {
            const monthly = amount.dataset.monthly;
            const yearly = amount.dataset.yearly;

            // Animate the number change
            const current = parseInt(amount.textContent);
            const target = isYearly ? parseInt(yearly) : parseInt(monthly);

            animateNumber(amount, current, target, 300);
        });
    });
}

function animateNumber(el, from, to, duration) {
    const start = performance.now();

    const animate = (currentTime) => {
        const elapsed = currentTime - start;
        const progress = Math.min(elapsed / duration, 1);

        const current = Math.floor(from + (to - from) * progress);
        el.textContent = current;

        if (progress < 1) {
            requestAnimationFrame(animate);
        } else {
            el.textContent = to;
        }
    };

    requestAnimationFrame(animate);
}

// ===================================
// FAQ Accordion
// ===================================
function initFAQ() {
    const items = document.querySelectorAll('.faq-item');

    items.forEach(item => {
        const question = item.querySelector('.faq-question');

        question.addEventListener('click', () => {
            const isActive = item.classList.contains('active');

            // Close all others
            items.forEach(other => {
                if (other !== item) {
                    other.classList.remove('active');
                }
            });

            // Toggle current
            item.classList.toggle('active', !isActive);
        });
    });
}

// ===================================
// Scroll Animations
// ===================================
function initScrollAnimations() {
    const elements = document.querySelectorAll(
        '.feature-card, .pricing-card, .testimonial-card, .demo-feature, .step, .cta-form-container'
    );

    elements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(40px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    });

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.classList.add('animate-in');
                }, index * 50);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1, rootMargin: '-50px' });

    elements.forEach(el => observer.observe(el));

    // Stagger animation for grid items
    document.querySelectorAll('.pricing-cards .pricing-card').forEach((card, i) => {
        card.style.transitionDelay = `${i * 0.1}s`;
    });

    document.querySelectorAll('.demo-features .demo-feature').forEach((feature, i) => {
        feature.style.transitionDelay = `${i * 0.1}s`;
    });
}

// ===================================
// Contact Form
// ===================================
function initContactForm() {
    const form = document.getElementById('contactForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const submitBtn = form.querySelector('button[type="submit"]');
        const originalHTML = submitBtn.innerHTML;

        // Get form data
        const formData = {
            nome: document.getElementById('nome').value,
            provedor: document.getElementById('provedor').value,
            email: document.getElementById('email').value,
            whatsapp: document.getElementById('whatsapp').value
        };

        // Loading state
        submitBtn.innerHTML = `
            <svg class="spinner" width="20" height="20" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" fill="none" stroke-dasharray="60" stroke-linecap="round">
                    <animateTransform attributeName="transform" type="rotate" from="0 12 12" to="360 12 12" dur="1s" repeatCount="indefinite"/>
                </circle>
            </svg>
            <span>Enviando...</span>
        `;
        submitBtn.disabled = true;

        try {
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 2000));

            // Success state
            submitBtn.innerHTML = `
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 6L9 17l-5-5"/>
                </svg>
                <span>Enviado com sucesso!</span>
            `;
            submitBtn.style.background = 'linear-gradient(135deg, #10B981, #34D399)';

            // Reset form
            form.reset();

            // Show success message
            showToast('success', `Obrigado, ${formData.nome}! Entraremos em contato em breve.`);

            // Reset button after delay
            setTimeout(() => {
                submitBtn.innerHTML = originalHTML;
                submitBtn.style.background = '';
                submitBtn.disabled = false;
            }, 3000);

        } catch (error) {
            submitBtn.innerHTML = `
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M15 9l-6 6M9 9l6 6"/>
                </svg>
                <span>Erro ao enviar</span>
            `;
            submitBtn.style.background = '#EF4444';

            showToast('error', 'Ocorreu um erro. Tente novamente.');

            setTimeout(() => {
                submitBtn.innerHTML = originalHTML;
                submitBtn.style.background = '';
                submitBtn.disabled = false;
            }, 3000);
        }
    });
}

function showToast(type, message) {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <span class="toast-icon">${type === 'success' ? '✓' : '✕'}</span>
        <span class="toast-message">${message}</span>
    `;

    // Add toast styles if not exists
    if (!document.getElementById('toastStyles')) {
        const style = document.createElement('style');
        style.id = 'toastStyles';
        style.textContent = `
            .toast {
                position: fixed;
                bottom: 24px;
                right: 24px;
                display: flex;
                align-items: center;
                gap: 12px;
                padding: 16px 24px;
                background: #1E1E2A;
                border: 1px solid rgba(255,255,255,0.1);
                border-radius: 12px;
                color: white;
                font-size: 0.95rem;
                box-shadow: 0 10px 40px rgba(0,0,0,0.3);
                animation: slideIn 0.4s ease, slideOut 0.4s ease forwards 4s;
                z-index: 10000;
            }
            .toast-success { border-left: 4px solid #10B981; }
            .toast-error { border-left: 4px solid #EF4444; }
            .toast-icon {
                width: 24px;
                height: 24px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 0.8rem;
            }
            .toast-success .toast-icon { background: rgba(16,185,129,0.2); color: #10B981; }
            .toast-error .toast-icon { background: rgba(239,68,68,0.2); color: #EF4444; }
            @keyframes slideIn {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            @keyframes slideOut {
                from { transform: translateX(0); opacity: 1; }
                to { transform: translateX(100%); opacity: 0; }
            }
        `;
        document.head.appendChild(style);
    }

    document.body.appendChild(toast);

    setTimeout(() => {
        toast.remove();
    }, 4500);
}

// ===================================
// Testimonial Slider
// ===================================
function initTestimonialSlider() {
    const track = document.getElementById('testimonialTrack');
    if (!track) return;

    // Clone cards for infinite scroll effect
    const cards = track.querySelectorAll('.testimonial-card');
    cards.forEach(card => {
        const clone = card.cloneNode(true);
        track.appendChild(clone);
    });

    let scrollAmount = 0;
    const cardWidth = 404; // card width + gap
    const totalWidth = cardWidth * cards.length;

    function autoScroll() {
        scrollAmount += 0.5;
        if (scrollAmount >= totalWidth) {
            scrollAmount = 0;
        }
        track.style.transform = `translateX(-${scrollAmount}px)`;
        requestAnimationFrame(autoScroll);
    }

    // Start auto scroll
    autoScroll();

    // Pause on hover
    track.addEventListener('mouseenter', () => {
        track.style.animationPlayState = 'paused';
    });

    track.addEventListener('mouseleave', () => {
        track.style.animationPlayState = 'running';
    });
}

// ===================================
// Parallax Effects
// ===================================
window.addEventListener('scroll', () => {
    const scrollY = window.pageYOffset;

    // Parallax for orbs
    const orbs = document.querySelectorAll('.gradient-orb');
    orbs.forEach((orb, i) => {
        const speed = 0.05 * (i + 1);
        orb.style.transform = `translateY(${scrollY * speed}px)`;
    });

    // Parallax for phone
    const phone = document.querySelector('.phone');
    if (phone && scrollY < window.innerHeight) {
        phone.style.transform = `translateY(${scrollY * 0.1}px)`;
    }
});

// ===================================
// Phone Demo Animations
// ===================================
(function initPhoneDemo() {
    // Animate speed gauge on load
    setTimeout(() => {
        const gaugeFill = document.querySelector('.gauge-fill');
        if (gaugeFill) {
            gaugeFill.style.strokeDashoffset = '30';
        }
    }, 1500);

    // Random notification effect
    const floatCards = document.querySelectorAll('.float-card');

    function showNotification(card) {
        card.style.opacity = '0';
        card.style.transform = 'translateX(30px)';

        setTimeout(() => {
            card.style.transition = 'all 0.5s ease';
            card.style.opacity = '1';
            card.style.transform = 'translateX(0)';
        }, Math.random() * 2000);
    }

    floatCards.forEach(card => {
        showNotification(card);
        setInterval(() => showNotification(card), 8000);
    });
})();
