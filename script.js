document.addEventListener('DOMContentLoaded', () => {
    const themeToggleButton = document.getElementById('theme-toggle');
    const screenshotImg = document.getElementById('screenshot-img');
    const sunIcon = document.querySelector('.sun-icon');
    const moonIcon = document.querySelector('.moon-icon');
    
    // Check localStorage or System Preference
    const savedTheme = localStorage.getItem('theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    function applyTheme(isDark) {
        if (isDark) {
            document.body.classList.add('dark-mode');
            sunIcon.style.display = 'block';
            moonIcon.style.display = 'none';
            setScreenshot('dark-mode');
        } else {
            document.body.classList.remove('dark-mode');
            sunIcon.style.display = 'none';
            moonIcon.style.display = 'block';
            setScreenshot('light-mode');
        }
    }

    // Initial Theme Set
    if (savedTheme) {
        applyTheme(savedTheme === 'dark-mode');
    } else {
        applyTheme(systemPrefersDark);
    }

    function setScreenshot(theme) {
        if (!screenshotImg) return;
        screenshotImg.style.opacity = '0.6';
        const newSrc = theme === 'dark-mode' ? 'assets/ss_dark.png' : 'assets/ss_light.png';
        
        // Preload image to prevent flickering
        const imgLoader = new Image();
        imgLoader.src = newSrc;
        imgLoader.onload = () => {
            screenshotImg.src = newSrc;
            screenshotImg.style.opacity = '1';
        };
    }

    themeToggleButton.addEventListener('click', () => {
        const isDark = !document.body.classList.contains('dark-mode');
        applyTheme(isDark);
        localStorage.setItem('theme', isDark ? 'dark-mode' : 'light-mode');
    });

    // --- Intersection Observer (Scroll Reveal) ---
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, { threshold: 0.1, rootMargin: "0px 0px -50px 0px" });

    document.querySelectorAll('.card').forEach(card => {
        observer.observe(card);
    });

    // --- High Performance Spotlight Effect ---
    const cardsContainer = document.getElementById('cards-container');
    const installGrid = document.querySelector('.install-grid');
    
    function updateSpotlight(e, container) {
        if(!container) return;
        const cards = container.getElementsByClassName("card");
        
        for(const card of cards) {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            // Updates CSS variables that control the glow position
            card.style.setProperty("--mouse-x", `${x}px`);
            card.style.setProperty("--mouse-y", `${y}px`);
        }
    }

    // Optimization: Use requestAnimationFrame to throttle mousemove events
    let ticking = false;

    window.addEventListener('mousemove', (e) => {
        if (!ticking) {
            window.requestAnimationFrame(() => {
                updateSpotlight(e, cardsContainer);
                updateSpotlight(e, installGrid);
                ticking = false;
            });
            ticking = true;
        }
    });
});
