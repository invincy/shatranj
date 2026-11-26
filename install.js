(() => {
  let failed = !!window.shatranjStartupFailed;
  let pending = null, dismissed = false, ready = false, waiting = null, reloading = false;
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  const card = document.createElement('aside');
  card.id = 'install-card'; card.hidden = true; card.setAttribute('aria-label','Optional app installation');
  card.innerHTML = `<span id="install-message">Play here, or install.</span><button id="install-now" type="button">Install</button><button id="install-later" type="button" aria-label="Dismiss installation prompt">Not now</button>`;
  document.body.appendChild(card);
  const message = card.querySelector('#install-message'), button = card.querySelector('#install-now');
  const ios = /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const knownInstalled = () => {try{return localStorage.getItem('shatranj-installed') === 'yes';}catch{return false;}};
  const show = () => { card.hidden = !(ready || (failed && waiting)) || dismissed || (!waiting && (standalone() || knownInstalled() || (!pending && !ios))); };
  card.querySelector('#install-later').addEventListener('click', () => {dismissed=true;card.hidden=true;});
  window.addEventListener('shatranj-startup-failed',()=>{failed=true;show();});
  window.addEventListener('beforeinstallprompt', event => {event.preventDefault();pending=event;show();});
  window.addEventListener('appinstalled', () => {pending=null;card.hidden=true;try{localStorage.setItem('shatranj-installed','yes');}catch{}});
  button.addEventListener('click', async () => {
    if (waiting) {
      if (!window.confirm('Load the new version? This restarts the game and ends any current match.')) return;
      reloading=true;button.disabled=true;message.textContent='Updating…';waiting.postMessage({type:'ACTIVATE_UPDATE'});return;
    }
    if (pending) {
      const event=pending;pending=null;
      try {await event.prompt();await event.userChoice;dismissed=true;card.hidden=true;}
      catch {message.textContent='Installation unavailable. Keep playing here.';button.hidden=true;}
    } else if (ios) {
      message.textContent='Safari: Share → Add to Home Screen. Optional.';button.hidden=true;
    }
  });
  // No installation UI while Godot is downloading or starting up.
  const checkReady=()=>{if (!document.getElementById('status')) {ready=true;show();observer.disconnect();}};
  const observer=new MutationObserver(checkReady);observer.observe(document.body,{childList:true,subtree:true});checkReady();
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange',()=>{if(reloading)location.reload();});
    navigator.serviceWorker.register('./sw.js',{scope:'./',updateViaCache:'none'}).then(reg=>{
      const offer=()=>{if(!reg.waiting || !navigator.serviceWorker.controller)return;waiting=reg.waiting;dismissed=false;message.textContent='New version ready';button.textContent='Update';card.setAttribute('aria-label','Game update');show();};
      offer();reg.addEventListener('updatefound',()=>{const worker=reg.installing;if(worker)worker.addEventListener('statechange',()=>{if(worker.state==='installed')offer();});});
      reg.update().catch(()=>{});
    }).catch(()=>{});
  }
})();
