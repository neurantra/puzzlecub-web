/* Shared by Next pages and the same-origin Flutter game documents. */
(() => {
  if (window.puzzlecubAds) return;
  let ready = false, h5Ready = false, busy = false, lastBreak = 0, played = false;
  const started = Date.now();
  const disabled = {enabled:false, slots:{}};
  const settings = fetch('/api/ads/config', {credentials:'same-origin'})
    .then(r => r.ok ? r.json() : disabled).catch(() => disabled);
  let config = disabled;
  const ads = window.puzzlecubAds = {
    settings,
    markPlayed: () => { played = true; },
    display(element, slot) {
      if (!ready || !config.enabled || !slot || !element.isConnected || element.dataset.requested) return;
      element.dataset.requested = 'true';
      try { window.adsbygoogle.push({}); } catch { element.closest('.ad-placement')?.setAttribute('hidden', ''); }
    },
    between: async () => {
      // Only natural breaks. No preroll, forced retry, or ad on the first game.
      if (!played || !h5Ready || busy || Date.now() - started < 60000 || Date.now() - lastBreak < 180000) return;
      played = false;
      busy = true;
      lastBreak = Date.now();
      await new Promise(resolve => {
        let finished = false;
        const done = () => {
          if (finished) return;
          finished = true; busy = false;
          document.documentElement.classList.remove('ad-break-active');
          window.dispatchEvent(new Event('puzzlecub:ad-end'));
          if(window.parent !== window) window.parent.postMessage({type:'puzzlecub:ad-state',active:false},location.origin);
          resolve();
        };
        try {
          window.adBreak({type:'next', name:'between-games',
            beforeAd: () => {
              document.documentElement.classList.add('ad-break-active');
              window.dispatchEvent(new Event('puzzlecub:ad-start'));
              if(window.parent !== window) window.parent.postMessage({type:'puzzlecub:ad-state',active:true},location.origin);
            },
            afterAd: done,
            adBreakDone: done,
          });
        } catch { done(); }
      });
    },
  };
  window.puzzlecubBetweenGames = () => ads.between();
  settings.then(value => {
    config = value;
    if (!config.enabled || navigator.globalPrivacyControl || navigator.doNotTrack === '1') return;
    // The certified CMP configured in AdSense supplies the consent signal to Google.
    // Non-personalized ads still require that CMP in applicable regions.
    window.adsbygoogle = window.adsbygoogle || [];
    window.adsbygoogle.requestNonPersonalizedAds = 1;
    window.adBreak = window.adConfig = o => window.adsbygoogle.push(o);
    const script = document.createElement('script');
    script.async = true; script.crossOrigin = 'anonymous';
    script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + config.client;
    script.dataset.adFrequencyHint = '180s';
    if (config.test) { script.dataset.adbreakTest = 'on'; script.dataset.adtest = 'on'; }
    script.onload = () => {
      ready = true;
      window.dispatchEvent(new Event('puzzlecub:ads-ready'));
      if (config.h5) window.adConfig({sound:'off', preloadAdBreaks:'on', onReady:()=>{h5Ready=true;}});
    };
    script.onerror = () => { ready = false; h5Ready = false; };
    document.head.appendChild(script);
  });
})();
