/* ============================================================
   HOSTEL MANAGEMENT SYSTEM — MAIN JAVASCRIPT
   ============================================================ */

/* ── Navbar scroll effect ─────────────────────────────────── */
window.addEventListener('scroll', () => {
  const nav = document.getElementById('navbar');
  if (nav) nav.classList.toggle('scrolled', window.scrollY > 40);
});

/* ── Hamburger / Mobile Nav ───────────────────────────────── */
function toggleNav() {
  const menu = document.getElementById('mobileNav');
  const ham  = document.getElementById('hamburger');
  if (!menu) return;
  const isOpen = menu.style.display === 'flex';
  menu.style.display = isOpen ? 'none' : 'flex';
  if (ham) ham.classList.toggle('open', !isOpen);
}

/* ── Active nav link on scroll ────────────────────────────── */
function trackNavLinks() {
  const links    = document.querySelectorAll('.nav-link[href^="#"]');
  const sections = [...links].map(l => document.querySelector(l.getAttribute('href'))).filter(Boolean);
  const onScroll = () => {
    const scrollY = window.scrollY + 100;
    let current = '';
    sections.forEach(s => { if (scrollY >= s.offsetTop) current = '#' + s.id; });
    links.forEach(l => {
      l.classList.toggle('active', l.getAttribute('href') === current);
    });
  };
  window.addEventListener('scroll', onScroll);
}

/* ── Intersection Observer — fade-up ─────────────────────── */
function initFadeUp() {
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); } });
  }, { threshold: 0.12 });
  document.querySelectorAll('.fade-up').forEach(el => obs.observe(el));
}

/* ── Toast Notifications ──────────────────────────────────── */
function showToast(message, type = 'info', duration = 3500) {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const icons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
  const toast  = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span class="toast-icon">${icons[type] || 'ℹ️'}</span>
    <span class="toast-msg">${message}</span>
    <span class="toast-close" onclick="this.parentElement.remove()">✕</span>
  `;
  container.appendChild(toast);
  setTimeout(() => { toast.style.animation = 'none'; toast.style.opacity = '0'; toast.style.transform = 'translateX(120%)'; setTimeout(() => toast.remove(), 300); }, duration);
}

/* ── Smooth scroll for anchor links ──────────────────────── */
document.addEventListener('click', (e) => {
  const a = e.target.closest('a[href^="#"]');
  if (!a) return;
  const target = document.querySelector(a.getAttribute('href'));
  if (target) { e.preventDefault(); target.scrollIntoView({ behavior: 'smooth', block: 'start' }); }
});

/* ── Initialize ───────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  initFadeUp();
  trackNavLinks();
});
