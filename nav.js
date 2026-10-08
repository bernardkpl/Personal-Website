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

/* ---------- Page-frame rulers ----------
   Zone width is chosen so exactly 12 zones (6 on phones) fit between the
   inner borders; the background grid is sized from the same --zone value,
   so one zone = two 5x5 grid blocks. Numbers run across the top/bottom,
   letters down the sides; side tracks cover the viewport plus the grid's
   parallax travel. */
(function () {
  var frame = document.querySelector('.page-frame');
  if (!frame) return;
  var root = document.documentElement;
  var PARALLAX = 0.25; // must match the grid's background-position factor in style.css
  var narrow = window.matchMedia('(max-width: 720px)');

  function letters(n) {
    var s = '';
    for (n += 1; n > 0; n = Math.floor((n - 1) / 26)) s = String.fromCharCode(65 + (n - 1) % 26) + s;
    return s;
  }
  function fill(selector, count, label) {
    frame.querySelectorAll(selector).forEach(function (track) {
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
    var travel = Math.max(0, root.scrollHeight - h) * PARALLAX;
    fill('.ruler-top .ruler-track, .ruler-bottom .ruler-track', cols, function (i) { return i + 1; });
    fill('.ruler-left .ruler-track, .ruler-right .ruler-track', Math.ceil((h + travel) / zone) + 1, letters);
  }
  build();
  window.addEventListener('resize', build);
  window.addEventListener('load', build);
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
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.1 });
  targets.forEach(function (el) { io.observe(el); });

  // Scroll-linked values: gear rotation, grid parallax, progress bar, timeline drawing
  var timelines = document.querySelectorAll('.timeline');
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
  }
  window.addEventListener('scroll', function () {
    if (!ticking) { ticking = true; requestAnimationFrame(update); }
  }, { passive: true });
  window.addEventListener('resize', update);
  update();
})();
