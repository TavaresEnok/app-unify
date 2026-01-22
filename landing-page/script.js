// ===================================
// App Unify Premium Hybrid
// Script.js
// ===================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize Core Modules
    initCursorGlow();
    initMobileMenu();
    initSmoothScroll();
    initNavbarScroll();
    initStatsCounter();
    initPricingToggle();
    initScrollAnimations();
    initTestimonialSlider();
    initContactForm(); // Keep form logic

    console.log('🚀 App Unify Hybrid Premium loaded!');
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

    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            navLinks.classList.remove('active');
            toggle.classList.remove('active');
        });
    });

    // Add CSS for mobile menu if not present
    if (!document.getElementById('mobileMenuStyles')) {
        const style = document.createElement('style');
        style.id = 'mobileMenuStyles';
        style.textContent = `
            @media (max-width: 768px) {
                .nav-links.active {
                    display: flex;
                    flex-direction: column;
                    position: absolute;
                    top: 100%;
                    left: 0;
                    right: 0;
                    background: rgba(5, 5, 10, 0.95);
                    backdrop-filter: blur(20px);
                    padding: 30px;
                    gap: 20px;
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
                const offset = 90;
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

    window.addEventListener('scroll', () => {
        if (window.pageYOffset > 50) {
            navbar.style.background = 'rgba(5, 5, 10, 0.9)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.3)';
        } else {
            navbar.style.background = 'rgba(5, 5, 10, 0.8)';
            navbar.style.boxShadow = 'none';
        }
    });
}

// ===================================
// Stats Counter (Updated Selector)
// ===================================
function initStatsCounter() {
    // Selects elements with data-count attribute
    const stats = document.querySelectorAll('[data-count]');

    if (!stats.length) return;

    const animateCounter = (el) => {
        const rawTarget = el.dataset.count;
        const isFloat = rawTarget.includes('.');
        const target = parseFloat(rawTarget);

        const duration = 2000; // ms
        const start = performance.now();

        const animate = (currentTime) => {
            const elapsed = currentTime - start;
            const progress = Math.min(elapsed / duration, 1);

            // EaseOutExpo
            const ease = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);

            let current = target * ease;

            // Format number
            if (isFloat) {
                el.innerText = current.toFixed(1) + (rawTarget.includes('%') ? '%' : '/5');
            } else {
                el.innerText = '+' + Math.floor(current).toLocaleString('pt-BR') + 'k';
            }

            // Special fix for specific formats based on original text
            // (Simpler: just reset to original text at end)
            if (progress < 1) {
                requestAnimationFrame(animate);
            } else {
                // Restore original format from parsing
                if (el.dataset.count === '50000') el.innerText = '+50k';
                if (el.dataset.count === '4.9') el.innerText = '4.9/5';
                if (el.dataset.count === '99.9') el.innerText = '99.9%';
            }
        };

        requestAnimationFrame(animate);
    };

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
// Pricing Toggle
// ===================================
function initPricingToggle() {
    const toggle = document.getElementById('billingToggle');
    const amounts = document.querySelectorAll('.amount');

    if (!toggle || !amounts.length) return;

    toggle.addEventListener('change', () => {
        const isYearly = toggle.checked;

        amounts.forEach(amount => {
            const monthly = amount.dataset.m;
            const yearly = amount.dataset.y;
            const target = isYearly ? yearly : monthly;

            // Simple fade text swap
            amount.style.opacity = '0';
            setTimeout(() => {
                amount.textContent = target;
                amount.style.opacity = '1';
            }, 200);
        });

        // Toggle active text class
        document.querySelectorAll('.toggle-text').forEach(el => el.classList.toggle('active'));
    });
}

// ===================================
// Scroll Animations (Updated)
// ===================================
function initScrollAnimations() {
    // Elements to reveal
    const elements = document.querySelectorAll(
        '.feature-row, .pricing-card-minimal, .testimonial-card-clean, .cta-box'
    );

    elements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(40px)';
        el.style.transition = 'opacity 0.8s ease, transform 0.8s cubic-bezier(0.2, 0.8, 0.2, 1)';
    });

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.15 });

    elements.forEach(el => observer.observe(el));
}

// ===================================
// Testimonials Slider (Basic Infinite)
// ===================================
function initTestimonialSlider() {
    // Clone items for infinite effect
    const track = document.querySelector('.slider-track');
    if (!track) return;

    // Copy content for smooth loop if needed, or stick to CSS scroll
    // The clean version often uses simple CSS overflow-x which we did in styles.
    // So this might just be for drag behavior?
    // Let's keep it simple: Mouse Drag support

    let isDown = false;
    let startX;
    let scrollLeft;

    const wrapper = document.querySelector('.slider-wrapper');
    if (!wrapper) return;

    wrapper.addEventListener('mousedown', (e) => {
        isDown = true;
        wrapper.style.cursor = 'grabbing';
        startX = e.pageX - wrapper.offsetLeft;
        scrollLeft = wrapper.scrollLeft;
    });

    wrapper.addEventListener('mouseleave', () => {
        isDown = false;
        wrapper.style.cursor = 'grab';
    });

    wrapper.addEventListener('mouseup', () => {
        isDown = false;
        wrapper.style.cursor = 'grab';
    });

    wrapper.addEventListener('mousemove', (e) => {
        if (!isDown) return;
        e.preventDefault();
        const x = e.pageX - wrapper.offsetLeft;
        const walk = (x - startX) * 2; // scroll-fast
        wrapper.scrollLeft = scrollLeft - walk;
    });
}

// ===================================
// Contact Form (Mock)
// ===================================
function initContactForm() {
    const form = document.getElementById('contactForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = form.querySelector('button');
        const originalText = btn.innerText;

        btn.disabled = true;
        btn.innerText = 'Enviando...';

        // Mock delay
        await new Promise(r => setTimeout(r, 1500));

        btn.style.background = '#10B981';
        btn.innerText = 'Enviado!';

        // Show success
        alert('Obrigado! Entraremos em contato em breve.');

        setTimeout(() => {
            form.reset();
            btn.style.background = ''; // reset
            btn.innerText = originalText;
            btn.disabled = false;
        }, 3000);
    });
}
