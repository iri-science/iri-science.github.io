const header = document.querySelector('.site-header');
const nav = header?.querySelector('.site-nav');

// Old browsers keep the complete navigation visible, without a JS dependency.
if (nav && 'popover' in HTMLElement.prototype) {
  const menu = nav.querySelector('.site-menu');
  const menuButton = nav.querySelector('.menu-button');
  const dropdowns = [...nav.querySelectorAll('.site-dropdown')].map(item => ({
    item,
    trigger: item.querySelector('button'),
    submenu: item.querySelector('.site-submenu'),
    preview: false,
  }));
  const anchorPositioning = CSS.supports('position-area', 'block-end');
  let wide;
  let previousWidth = 0;
  let pending = false;

  function positionSubmenu({ trigger, submenu }) {
    if (anchorPositioning || !submenu.matches(':popover-open')) return;
    const anchor = trigger.getBoundingClientRect();
    const box = submenu.getBoundingClientRect();
    const top = anchor.bottom + box.height <= innerHeight
      ? anchor.bottom : Math.max(0, anchor.top - box.height);
    submenu.style.top = `${top}px`;
    submenu.style.left = `${Math.max(0, Math.min(anchor.left, innerWidth - box.width))}px`;
  }

  function updateLayout() {
    pending = false;
    const width = nav.clientWidth;
    // A collapsed row only needs remeasuring when more space becomes available.
    if (wide === false && width <= previousWidth) {
      previousWidth = width;
      return;
    }
    previousWidth = width;
    const wasOpen = menu.matches(':popover-open');
    const focused = document.activeElement;
    const wasWide = wide;
    header.classList.add('is-measuring', 'is-wide');
    menu.removeAttribute('popover');
    wide = nav.scrollWidth <= nav.clientWidth;
    header.classList.toggle('is-wide', wide);

    if (wasWide !== wide) {
      dropdowns.forEach(({ trigger, submenu }) => {
        if (wide) submenu.setAttribute('popover', 'auto');
        else submenu.removeAttribute('popover');
        submenu.hidden = !wide;
        trigger.setAttribute('aria-expanded', 'false');
      });
      if (!wide && menu.contains(focused)) menuButton.focus();
      else if (wide && focused === menuButton) dropdowns[0].trigger.focus();
      else if (wide && menu.contains(focused)) {
        const dropdown = dropdowns.find(({ submenu }) => submenu.contains(focused));
        dropdown?.trigger.focus();
      }
    }
    if (!wide) {
      menu.setAttribute('popover', 'auto');
      if (wasOpen) {
        menu.showPopover({ source: menuButton });
        if (menu.contains(focused)) focused.focus();
      }
    }
    requestAnimationFrame(() => header.classList.remove('is-measuring'));
  }

  function scheduleLayout() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(updateLayout);
  }

  dropdowns.forEach(dropdown => {
    const { item, trigger, submenu } = dropdown;
    trigger.addEventListener('click', event => {
      if (!wide) {
        submenu.hidden = !submenu.hidden;
        trigger.setAttribute('aria-expanded', String(!submenu.hidden));
      } else if (dropdown.preview) {
        // Clicking a hover preview pins it open instead of toggling it closed.
        dropdown.preview = false;
        event.preventDefault();
      }
    });
    submenu.addEventListener('toggle', event => {
      if (!wide) return;
      trigger.setAttribute('aria-expanded', String(event.newState === 'open'));
      if (event.newState === 'closed') dropdown.preview = false;
      else positionSubmenu(dropdown);
    });
    item.addEventListener('pointerenter', event => {
      if (!wide || event.pointerType === 'touch' || !matchMedia('(hover: hover)').matches) return;
      if (!submenu.matches(':popover-open')) {
        dropdown.preview = true;
        submenu.showPopover({ source: trigger });
      }
    });
    item.addEventListener('pointerleave', () => {
      if (dropdown.preview && submenu.matches(':popover-open')) submenu.hidePopover();
      dropdown.preview = false;
    });
    item.addEventListener('focusout', event => {
      if (wide && event.relatedTarget && !item.contains(event.relatedTarget)
          && submenu.matches(':popover-open')) submenu.hidePopover();
    });
  });

  updateLayout();
  const observer = new ResizeObserver(scheduleLayout);
  observer.observe(nav);
  observer.observe(menu);
  if (!anchorPositioning) {
    // Keep the fixed-position fallback attached while scrolling or resizing.
    addEventListener('scroll', () => dropdowns.forEach(positionSubmenu), { passive: true });
    addEventListener('resize', () => dropdowns.forEach(positionSubmenu));
  }
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
