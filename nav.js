document.querySelectorAll('.dropdown').forEach(function (dd) {
  var btn = dd.querySelector('.dropdown-toggle');
  function set(open) {
    dd.classList.toggle('open', open);
    btn.setAttribute('aria-expanded', open);
  }
  btn.addEventListener('click', function () { set(!dd.classList.contains('open')); });
  document.addEventListener('click', function (e) { if (!dd.contains(e.target)) set(false); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') set(false); });
});

/* ---------- Sheet frames ----------
   Every .page (index drawing sheet) gets its own border and ruler bands. */
document.querySelectorAll('.page').forEach(function (page) {
  var f = document.createElement('div');
  f.className = 'page-frame local';
  f.setAttribute('aria-hidden', 'true');
  f.innerHTML = ['top', 'bottom', 'left', 'right'].map(function (side) {
    return '<div class="ruler ruler-' + side + '"><div class="ruler-track"></div></div>';
  }).join('');
  page.insertBefore(f, page.firstChild);
});

/* ---------- Page-frame rulers ----------
   Zone width is chosen so exactly 12 zones (6 on phones) fit between the
   inner borders; the background grid is sized from the same --zone value,
   so one zone = two 5x5 grid blocks. Numbers run across the top/bottom,
   letters down the sides; side tracks are long enough for the tallest sheet. */
(function () {
  var frames = document.querySelectorAll('.page-frame.local');
  if (!frames.length) return;
  var root = document.documentElement;
  var narrow = window.matchMedia('(max-width: 720px)');

  function letters(n) {
    var s = '';
    for (n += 1; n > 0; n = Math.floor((n - 1) / 26)) s = String.fromCharCode(65 + (n - 1) % 26) + s;
    return s;
  }
  function fill(selector, count, label) {
    document.querySelectorAll(selector).forEach(function (track) {
      var html = '';
      for (var i = 0; i < count; i++) html += '<span>' + label(i) + '</span>';
      track.innerHTML = html;
    });
  }
  function build() {
    var cols = narrow.matches ? 6 : 12;
    var border = parseFloat(getComputedStyle(document.body).getPropertyValue('--frame')) || 0;
    var w = root.clientWidth, h = root.clientHeight;
    var zone = (w - 2 * border) / cols;
    root.style.setProperty('--zone', zone + 'px');
    var span = h;
    frames.forEach(function (f) { span = Math.max(span, f.parentElement.offsetHeight); });
    fill('.ruler-top .ruler-track, .ruler-bottom .ruler-track', cols, function (i) { return i + 1; });
    fill('.ruler-left .ruler-track, .ruler-right .ruler-track', Math.ceil(span / zone) + 1, letters);
    track();
  }
  // Each sheet's grid moves 1:1 with the sheet, so its side letters are offset
  // by how far the sheet has scrolled past its pinned border
  function track() {
    frames.forEach(function (f) {
      var y = f.parentElement.getBoundingClientRect().top - f.getBoundingClientRect().top;
      f.style.setProperty('--track-y', y + 'px');
    });
  }
  build();
  window.addEventListener('resize', build);
  window.addEventListener('load', build);
  window.addEventListener('scroll', track, { passive: true });
})();

/* ---------- Sheet stack pin ----------
   Each sheet pins just below the fixed header, or once its bottom reaches the
   bottom of the window if it is taller, so all of it, title block included,
   is seen before the next sheet covers it. Also publishes the header height. */
(function () {
  var pages = document.querySelectorAll('.page');
  if (!pages.length) return;
  var nav = document.querySelector('nav');
  function pin() {
    var navH = nav ? nav.offsetHeight : 0;
    document.documentElement.style.setProperty('--nav-h', navH + 'px');
    var h = document.documentElement.clientHeight;
    pages.forEach(function (p) { p.style.top = Math.min(navH, h - p.offsetHeight) + 'px'; });
  }
  pin();
  window.addEventListener('resize', pin);
  window.addEventListener('load', pin);
})();

/* ---------- In-page links on the sheet stack ----------
   Sheets are sticky, so the browser sees a pinned sheet as already in view and
   won't scroll to it. Work out each sheet's real place in the page instead:
   the stack's top plus the heights (and hold margins) of the sheets before it. */
(function () {
  var stack = document.querySelector('.sheet-stack');
  if (!stack) return;
  var pages = Array.prototype.slice.call(stack.querySelectorAll('.page'));
  var nav = document.querySelector('nav');

  function pageTop(page) {
    var y = stack.getBoundingClientRect().top + window.scrollY;
    for (var i = 0; i < pages.length && pages[i] !== page; i++) {
      y += pages[i].offsetHeight + parseFloat(getComputedStyle(pages[i]).marginBottom);
    }
    return y;
  }

  document.addEventListener('click', function (e) {
    var link = e.target.closest('a[href^="#"]');
    if (!link) return;
    var target = document.getElementById(link.getAttribute('href').slice(1));
    var page = target && target.closest('.page');
    if (!page) return;
    e.preventDefault();
    var within = target === page ? 0 : target.getBoundingClientRect().top - page.getBoundingClientRect().top;
    var navH = nav ? nav.offsetHeight : 0;
    window.scrollTo({ top: Math.max(0, pageTop(page) + within - navH) });
  });

  /* Snap: if scrolling stops while one sheet is sliding over another, ease to
     whichever sheet is closer, so you never rest half-way between two pages.
     Snaps land on the top of a sheet (just under the header). Scrolling inside
     a sheet, including a tall one, never snaps: only the stretch where the next
     sheet is sliding in, from one window-height before its top, does. */
  var timer, raf, animating = false;
  var root = document.documentElement;

  // Quick spring to y: fast ease-out that overshoots slightly, then settles
  function springTo(target) {
    var from = window.scrollY, dist = target - from, t0 = null, dur = 500;
    var max = root.scrollHeight - root.clientHeight;
    animating = true;
    root.style.scrollBehavior = 'auto';       // we drive the motion ourselves
    function stop() {
      animating = false;
      root.style.scrollBehavior = '';
      ['wheel', 'touchstart', 'keydown'].forEach(function (ev) { window.removeEventListener(ev, cancel); });
    }
    function cancel() { cancelAnimationFrame(raf); stop(); }
    ['wheel', 'touchstart', 'keydown'].forEach(function (ev) { window.addEventListener(ev, cancel, { passive: true }); });
    function frame(now) {
      if (t0 === null) t0 = now;
      var p = Math.min(1, (now - t0) / dur), c1 = 0.6;
      var e = 1 + (c1 + 1) * Math.pow(p - 1, 3) + c1 * Math.pow(p - 1, 2);   // easeOutBack
      window.scrollTo(0, Math.max(0, Math.min(max, from + dist * e)));
      if (p < 1) raf = requestAnimationFrame(frame);
      else stop();
    }
    raf = requestAnimationFrame(frame);
  }

  function snap() {
    if (animating) return;
    var navH = nav ? nav.offsetHeight : 0;
    var h = root.clientHeight;
    var y = window.scrollY;
    for (var i = 1; i < pages.length; i++) {
      var end = pageTop(pages[i]) - navH;     // top of sheet i, just under the header
      var start = pageTop(pages[i]) - h;      // sheet i just peeking in
      if (y > start + 1 && y < end - 1) {
        var target = y - start < end - y ? start : end;
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) window.scrollTo(0, target);
        else springTo(target);
        return;
      }
    }
  }
  window.addEventListener('scroll', function () {
    if (animating) return;
    clearTimeout(timer);
    timer = setTimeout(snap, 150);
  }, { passive: true });
})();

/* ---------- Scroll motion ---------- */
(function () {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  var root = document.documentElement;

  // Progress bar along the bottom edge of the nav (framed pages use the moving rulers instead)
  var nav = document.querySelector('nav');
  var bar = document.createElement('div');
  bar.className = 'scroll-progress';
  if (nav && !document.body.classList.contains('framed')) nav.appendChild(bar);

  // Reveal-on-scroll: elements fade and slide up when they enter the viewport
  var targets = document.querySelectorAll([
    '.sheet-body > *', '.tb-cell',
    '.section h2', '.skill-group', '.chips li', '.job', '.card',
    'main.project > *:not(.figure-pair):not(.skills)', '.figure-pair > *', 'main.project ul.skills li'
  ].join(','));

  // Stagger siblings (chips, cards, groups) so they cascade in
  targets.forEach(function (el) {
    var i = Array.prototype.indexOf.call(el.parentNode.children, el);
    el.style.setProperty('--i', Math.min(i, 10));
    el.classList.add('reveal');
  });

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add('in');
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.1 });
  targets.forEach(function (el) { io.observe(el); });

  // Scroll-linked values: gear rotation, grid parallax, progress bar, timeline drawing
  var timelines = document.querySelectorAll('.timeline');
  var pages = document.querySelectorAll('.page');
  var ticking = false;
  function update() {
    ticking = false;
    var y = window.scrollY;
    var max = root.scrollHeight - window.innerHeight;
    root.style.setProperty('--scroll', y);
    bar.style.transform = 'scaleX(' + (max > 0 ? y / max : 0) + ')';
    timelines.forEach(function (t) {
      var r = t.getBoundingClientRect();
      var p = (window.innerHeight * 0.75 - r.top) / r.height;
      t.style.setProperty('--draw', Math.max(0, Math.min(1, p)));
    });
    // How far each sheet has slid in over the previous one (0 = just entering, 1 = fully over).
    // The covered sheet darkens by it; the incoming sheet starts fading in once it is
    // a third of the way up the window and is fully opaque when it covers the whole window.
    for (var i = 0; i < pages.length - 1; i++) {
      var navH = nav ? nav.offsetHeight : 0;
      var c = (pages[i + 1].getBoundingClientRect().top - navH) / (window.innerHeight - navH);
      c = Math.max(0, Math.min(1, 1 - c));
      pages[i].style.setProperty('--cover', c);
      var enter = Math.max(0, (c - 1 / 3) * 1.5);
      pages[i + 1].style.setProperty('--enter', enter);
      // While still invisible, let clicks reach the sheet underneath
      pages[i + 1].style.pointerEvents = enter === 0 ? 'none' : '';
    }
  }
  window.addEventListener('scroll', function () {
    if (!ticking) { ticking = true; requestAnimationFrame(update); }
  }, { passive: true });
  window.addEventListener('resize', update);
  update();
})();
