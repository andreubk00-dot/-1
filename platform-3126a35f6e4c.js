/* Platform boundary: no network/authentication is required for standalone play. */
(() => {
  'use strict';
  const slots = 'quiet-valley:v1:';
  const query = new URLSearchParams(location.search);
  const hosts = /(^|\.)(yandex\.(ru|net|com)|ya\.ru)$/;
  const onYandex = query.get('platform') === 'yandex' || hosts.test(location.hostname) || (() => {
    try { return hosts.test(new URL(document.referrer).hostname); } catch { return false; }
  })();
  let sdk = null, started = false, ready = false, hidden = document.hidden;
  let blurred = false, adPaused = false, gameplay = false, desiredGameplay = false;
  let actions = 0;
  let saveCallback = null;
  function saveNow() { if (saveCallback) saveCallback(); }
  const touches = new Map();
  function refresh() {
    const active = desiredGameplay && started && !hidden && !blurred && !adPaused;
    if (active === gameplay) return;
    gameplay = active;
    const api = sdk?.features?.GameplayAPI;
    if (active) api?.start(); else api?.stop();
  }
  function clearInput() { touches.clear(); actions = 0; }
  const platform = {
    setSaveCallback(callback) { saveCallback = callback; },
    get paused() { return !started || hidden || blurred || adPaused; },
    get x() { return Math.max(-1, Math.min(1, [...touches.values()].reduce((s, v) => s + v[0], 0))); },
    get y() { return Math.max(-1, Math.min(1, [...touches.values()].reduce((s, v) => s + v[1], 0))); },
    takeAction() { const result = actions > 0; actions = 0; return result; },
    gameplay(active) { desiredGameplay = Boolean(active); refresh(); },
    ready() {
      if (ready) return;
      ready = true;
      sdk?.features?.LoadingAPI?.ready();
      document.getElementById('loading').hidden = true;
      document.getElementById('welcome').hidden = false;
    },
    save(slot, json) {
      try { localStorage.setItem(slots + slot, json); return true; }
      catch { return false; }
    },
    load(slot) {
      try { return localStorage.getItem(slots + slot) || ''; }
      catch { return ''; }
    },
    start() {
      if (!ready) return;
      started = true; blurred = false;
      document.getElementById('welcome').hidden = true;
      document.getElementById('canvas').focus();
      refresh();
    },
    async init() {
      if (!onYandex) return;
      await new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = '/sdk.js';
        const timer = setTimeout(() => reject(new Error("Превышено время ожидания SDK")), 15000);
        script.onload = () => { clearTimeout(timer); resolve(); };
        script.onerror = () => { clearTimeout(timer); reject(new Error('Не удалось загрузить SDK платформы. Проверьте соединение.')); };
        document.head.appendChild(script);
      });
      let initTimer;
      try {
        sdk = await Promise.race([window.YaGames.init(), new Promise((_, reject) => {
          initTimer = setTimeout(() => reject(new Error('Не удалось дождаться инициализации SDK')), 15000);
        })]);
      } finally { clearTimeout(initTimer); }
      sdk.on('game_api_pause', () => { adPaused = true; clearInput(); refresh(); });
      sdk.on('game_api_resume', () => { adPaused = false; refresh(); });
    }
  };
  window.ValleyPlatform = platform;
  document.addEventListener('visibilitychange', () => {
    hidden = document.hidden;
    if (hidden) { clearInput(); saveNow(); }
    refresh();
  });
  window.addEventListener('blur', () => { blurred = true; clearInput(); saveNow(); refresh(); });
  window.addEventListener('focus', () => { blurred = false; refresh(); });
  window.addEventListener('pagehide', () => { hidden = true; clearInput(); saveNow(); refresh(); });
  window.addEventListener('pageshow', () => { hidden = document.hidden; refresh(); });
  window.addEventListener('keydown', event => {
    if (started && ['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'F5'].includes(event.code)) event.preventDefault();
  });
  document.addEventListener('contextmenu', event => event.preventDefault());
  document.querySelectorAll('[data-move]').forEach(button => {
    button.addEventListener('pointerdown', event => {
      event.preventDefault(); button.setPointerCapture(event.pointerId);
      touches.set(event.pointerId, button.dataset.move.split(',').map(Number));
    });
    for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
      button.addEventListener(type, event => touches.delete(event.pointerId));
    }
  });
  document.getElementById('action').addEventListener('pointerdown', event => {
    event.preventDefault(); actions++;
  });
  document.getElementById('play').addEventListener('click', () => platform.start());
})();
