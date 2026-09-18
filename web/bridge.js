/* Yandex SDK boundary. No analytics, login, purchases or third-party assets. */
(() => {
  'use strict';
  const storageKey = 'kinetic_lab_v1';
  const reasons = new Set();
  let sdk = null;
  let listener = null;
  let assetsReady = false;
  let loaderHidden = false;
  let notifiedReady = false;
  let wantsGameplay = false;
  let reportedGameplay = false;
  let adPending = false;
  function storedLanguage() {
    // The player's own choice is kept inside the saved progress blob.
    try {
      const saved = JSON.parse(localStorage.getItem(storageKey) || '{}').lang;
      return saved === 'ru' || saved === 'en' ? saved : '';
    } catch (_) { return ''; }
  }
  let chosen = storedLanguage();
  let language = chosen || ((navigator.language || 'ru').startsWith('ru') ? 'ru' : 'en');

  const state = (event = '') => ({language, paused: reasons.size > 0, event});
  const emit = (event = '') => { if (listener) listener(JSON.stringify(state(event))); };
  function syncGameplay() {
    const running = wantsGameplay && reasons.size === 0 && notifiedReady;
    if (!sdk || running === reportedGameplay) return;
    reportedGameplay = running;
    try { sdk.features.GameplayAPI?.[running ? 'start' : 'stop'](); } catch (_) { /* SDK may be unavailable offline. */ }
  }
  function pause(reason, value) {
    if (value) reasons.add(reason); else reasons.delete(reason);
    emit();
    syncGameplay();
  }
  function ready() {
    if (!sdk || !assetsReady || !loaderHidden || notifiedReady) return;
    sdk.features.LoadingAPI.ready();
    notifiedReady = true;
    syncGameplay();
  }
  function localizePage() {
    document.documentElement.lang = language;
    const ru = language === 'ru';
    const title = document.getElementById('loading-label');
    if (title) title.textContent = ru ? 'Собираем лабораторию' : 'Preparing the laboratory';
    const rotate = document.getElementById('rotate-label');
    if (rotate) rotate.textContent = ru ? 'Поверни устройство горизонтально' : 'Rotate your device to landscape';
    const detail = document.getElementById('rotate-detail');
    if (detail) detail.textContent = ru ? 'Для экспериментов нужно чуть больше места' : 'Experiments need a little more room';
  }

  window.KineticBridge = {
    async init() {
      try {
        sdk = await YaGames.init();
        language = chosen || (sdk.environment.i18n.lang === 'ru' ? 'ru' : 'en');
        sdk.on('game_api_pause', () => pause('sdk', true));
        sdk.on('game_api_resume', () => pause('sdk', false));
        localizePage();
        emit();
        ready();
      } catch (_) {
        // The same build remains playable offline and outside the portal.
        localizePage();
        emit();
      }
    },
    subscribe(callback) { listener = callback; emit(); },
    localizePage,
    setLanguage(value) {
      chosen = value === 'ru' || value === 'en' ? value : '';
      if (chosen) language = chosen;
      localizePage();
      emit();
    },
    isMobile() { return matchMedia('(pointer: coarse)').matches || /Android|iPhone|iPad/i.test(navigator.userAgent); },
    gameReady() { assetsReady = true; ready(); },
    loaderHidden() { loaderHidden = true; ready(); },
    gameplay(value) { wantsGameplay = Boolean(value); syncGameplay(); },
    load() {
      try { return localStorage.getItem(storageKey) || ''; } catch (_) { return ''; }
    },
    save(json) {
      try { localStorage.setItem(storageKey, json); return true; } catch (_) { return false; }
    },
    fullscreen() {
      if (!this.isMobile()) return;
      try {
        const request = sdk?.screen?.fullscreen?.request();
        if (request?.catch) request.catch(() => {});
      } catch (_) { /* Unsupported or denied fullscreen does not prevent play. */ }
    },
    interstitial() {
      if (adPending) return;
      if (!sdk || !notifiedReady) { emit('ad_closed'); return; }
      adPending = true;
      pause('ad', true);
      let finished = false;
      const watchdog = typeof setTimeout === 'function' ? setTimeout(() => finish(), 25000) : null;
      const finish = () => {
        if (finished) return;
        finished = true;
        if (watchdog) clearTimeout(watchdog);
        adPending = false;
        reasons.delete('ad');
        emit('ad_closed');
        syncGameplay();
      };
      try {
        sdk.adv.showFullscreenAdv({callbacks: {
          onOpen: () => pause('ad', true),
          onClose: finish,
          onError: finish
        }});
      } catch (_) { finish(); }
    },
    state: () => state()
  };

  document.addEventListener('visibilitychange', () => pause('hidden', document.hidden));
  window.addEventListener('blur', () => pause('focus', true));
  window.addEventListener('focus', () => pause('focus', false));
  window.addEventListener('pagehide', () => pause('page', true));
  window.addEventListener('pageshow', () => pause('page', false));
  document.addEventListener('contextmenu', event => event.preventDefault());
  document.addEventListener('selectstart', event => event.preventDefault());
  window.addEventListener('keydown', event => {
    if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Tab', 'Backspace'].includes(event.code)) event.preventDefault();
  });
  const orientation = () => {
    const portrait = window.KineticBridge.isMobile() && innerHeight > innerWidth;
    document.documentElement.classList.toggle('portrait', portrait);
    pause('orientation', portrait);
  };
  window.addEventListener('resize', orientation);
  document.addEventListener('DOMContentLoaded', () => { localizePage(); orientation(); });
})();
