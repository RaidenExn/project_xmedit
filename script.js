document.addEventListener('DOMContentLoaded', () => {
    const themeToggleButton = document.getElementById('theme-toggle');
    const screenshotImg = document.getElementById('screenshot-img');
    const currentTheme = localStorage.getItem('theme');

    function setScreenshot(theme) {
        if (!screenshotImg) return;
        if (theme === 'dark-mode') {
            screenshotImg.src = 'assets/ss_dark.png';
        } else {
            screenshotImg.src = 'assets/ss_light.png';
        }
    }

    if (currentTheme) {
        document.body.classList.add(currentTheme);
        if (currentTheme === 'dark-mode') {
            themeToggleButton.textContent = '☀️';
        }
        setScreenshot(currentTheme);
    } else {
        document.body.classList.add('light-mode');
        setScreenshot('light-mode');
    }

    themeToggleButton.addEventListener('click', () => {
        document.body.classList.toggle('dark-mode');
        
        let theme = 'light-mode';
        if (document.body.classList.contains('dark-mode')) {
            theme = 'dark-mode';
            themeToggleButton.textContent = '☀️';
        } else {
            themeToggleButton.textContent = '🌙';
        }
        localStorage.setItem('theme', theme);
        setScreenshot(theme);
    });

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, { threshold: 0.1 });

    const cards = document.querySelectorAll('.features .card, .installation .card');
    cards.forEach(card => {
        observer.observe(card);
    });
});