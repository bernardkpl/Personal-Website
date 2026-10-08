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
