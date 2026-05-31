// Mobile nav toggle
const burger = document.getElementById('burger');
const navLinks = document.querySelector('.nav__links');
burger?.addEventListener('click', () => navLinks?.classList.toggle('open'));

// Animate bars on scroll
const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) e.target.style.opacity = '1';
  });
}, { threshold: 0.1 });

document.querySelectorAll('.feature-card, .stack-item').forEach(el => {
  el.style.opacity = '0';
  el.style.transition = 'opacity .5s ease, transform .5s ease, box-shadow .25s';
  observer.observe(el);
});

// Smooth active nav link
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const id = a.getAttribute('href');
    if (id === '#') return;
    const el = document.querySelector(id);
    if (el) { e.preventDefault(); el.scrollIntoView({ behavior: 'smooth' }); }
    navLinks?.classList.remove('open');
  });
});
