const nav = document.querySelector('.site-header .site-nav');

// Old browsers keep the complete navigation visible, without a JS dependency.
if (nav && 'popover' in HTMLElement.prototype) {
  nav.querySelectorAll('.site-dropdown').forEach(item => {
    const trigger = item.querySelector('button');
    const submenu = item.querySelector('.site-submenu');
    // Without script, the native menu opens with every nested link available.
    submenu.hidden = true;
    trigger.setAttribute('aria-expanded', 'false');
    trigger.addEventListener('click', () => {
      submenu.hidden = !submenu.hidden;
      trigger.setAttribute('aria-expanded', String(!submenu.hidden));
    });
  });
}

// Normalize extensionless Jekyll paths, trailing slashes, and index pages alike.
const normalizePath = path => path.replace(/\/index\.html$/, '/').replace(/\.html$/, '').replace(/\/$/, '') || '/';
const currentPath = normalizePath(location.pathname);
nav?.querySelectorAll('a[href]').forEach(link => {
  const url = new URL(link.href);
  if (url.origin === location.origin && normalizePath(url.pathname) === currentPath) {
    link.setAttribute('aria-current', 'page');
  }
});
