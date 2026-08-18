/*
 * Store network / logo marquee.
 *
 * Wires up any element carrying [data-sn-root]:
 *   - city buttons that filter the cards, and
 *   - a continuous moving row.
 *
 * The moving row holds the real group plus enough aria-hidden clones to cover
 * the viewport twice. The group is measured at runtime so the shift distance
 * is exact whatever the card count is, which is what keeps the loop seamless
 * after a filter changes how many cards are on screen.
 */
(function () {
  'use strict';

  function initRoot(root) {
    if (!root || root.dataset.snReady) return;
    root.dataset.snReady = '1';

    var bar = root.querySelector('[data-store-net-filter]');
    var empty = root.querySelector('[data-store-net-empty]');
    var marquee = root.querySelector('[data-sn-marquee]');
    var track = root.querySelector('[data-sn-track]');
    var group = root.querySelector('[data-sn-group]');
    var speed = parseFloat(root.getAttribute('data-sn-speed')) || 40;

    function sourceCards() {
      return (group || root).querySelectorAll('.t4s-store-net__card');
    }

    function buildLoop() {
      if (!marquee || !track || !group) return;

      track.querySelectorAll('[data-sn-clone]').forEach(function (n) {
        n.remove();
      });
      track.classList.remove('is--anim');
      track.style.removeProperty('--sn-shift');
      track.style.removeProperty('--sn-dur');

      var visible = group.querySelectorAll('.t4s-store-net__card:not(.is--hidden)').length;
      if (!visible) return;

      var groupWidth = group.getBoundingClientRect().width;
      if (!groupWidth) return;

      var gap = parseFloat(getComputedStyle(track).columnGap) || 0;
      var shift = groupWidth + gap;
      var copies = Math.max(1, Math.ceil((marquee.offsetWidth * 2) / shift));

      for (var i = 0; i < copies; i++) {
        var copy = group.cloneNode(true);
        copy.setAttribute('data-sn-clone', '');
        copy.setAttribute('aria-hidden', 'true');
        copy.removeAttribute('data-sn-group');
        copy.querySelectorAll('[data-shopify-editor-block]').forEach(function (n) {
          n.removeAttribute('data-shopify-editor-block');
        });
        track.appendChild(copy);
      }

      track.style.setProperty('--sn-shift', shift + 'px');
      track.style.setProperty('--sn-dur', shift / speed + 's');
      track.classList.add('is--anim');
    }

    if (bar) {
      bar.addEventListener('click', function (e) {
        var btn = e.target.closest('.t4s-store-net__city');
        if (!btn || btn.classList.contains('is--static')) return;

        bar.querySelectorAll('.t4s-store-net__city').forEach(function (b) {
          b.classList.toggle('is--active', b === btn);
        });

        var want = btn.getAttribute('data-city');
        var shown = 0;
        sourceCards().forEach(function (card) {
          var city = card.getAttribute('data-city');
          var show = want === '__all' || city === want || city === '__all';
          card.classList.toggle('is--hidden', !show);
          if (show) shown++;
        });
        if (empty) empty.hidden = shown > 0;
        buildLoop();
      });
    }

    if (marquee) {
      buildLoop();
      // Logos settle late, so measure again once they are in.
      window.addEventListener('load', buildLoop);
      var t;
      window.addEventListener('resize', function () {
        clearTimeout(t);
        t = setTimeout(buildLoop, 200);
      });
    }
  }

  function initAll(scope) {
    (scope || document).querySelectorAll('[data-sn-root]').forEach(initRoot);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      initAll();
    });
  } else {
    initAll();
  }

  // The theme editor re-renders a section on every change, which drops the
  // ready flag with it, so the fresh copy needs wiring again.
  document.addEventListener('shopify:section:load', function (e) {
    initAll(e.target);
  });
})();
