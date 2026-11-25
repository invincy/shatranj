(() => {
  let pending = null, dismissed = false;
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  const card = document.createElement('aside');
  card.id = 'install-card'; card.hidden = true; card.setAttribute('aria-label','Install Shatranj');
  card.innerHTML = `<div class="install-heading"><img src="app-icon-192.png" alt=""><div><strong>Keep Shatranj close</strong><div>Your royal battlefield, one tap away.</div></div></div><p id="install-message">Add Shatranj to your home screen for a full-screen game.</p><div class="install-actions"><button id="install-now" type="button">Install app</button><button id="install-later" type="button">Not now</button></div>`;
  document.body.appendChild(card);
  const message = card.querySelector('#install-message'), button = card.querySelector('#install-now');
  const ios = /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const knownInstalled = () => {try{return localStorage.getItem('shatranj-installed') === 'yes';}catch{return false;}};
  const show = () => { if (!standalone() && !dismissed && (pending || !knownInstalled())) card.hidden = false; };
  card.querySelector('#install-later').addEventListener('click', () => {dismissed=true;card.hidden=true;});
  window.addEventListener('beforeinstallprompt', event => {event.preventDefault();pending=event;button.textContent='Install app';show();});
  window.addEventListener('appinstalled', () => {pending=null;card.hidden=true;try{localStorage.setItem('shatranj-installed','yes');}catch{}});
  button.addEventListener('click', async () => {
    if (pending) {
      const event=pending; pending=null;
      try {await event.prompt();const choice=await event.userChoice;if(choice.outcome==='accepted'){card.hidden=true;}else{dismissed=true;card.hidden=true;}}
      catch {message.textContent='Use your browser menu and choose Install app or Add to Home Screen.';button.textContent='How to install';}
    } else {
      message.textContent=ios?'On iPhone or iPad, open this game in Safari. Tap Share, then Add to Home Screen.':'Open your browser menu and choose Install app or Add to Home Screen. If neither appears, try Chrome or Edge. You can keep playing here.';
      button.textContent='Got it';button.onclick=()=>{dismissed=true;card.hidden=true;};
    }
  });
  button.textContent='Add to Home Screen';show();
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('./sw.js',{scope:'./',updateViaCache:'none'}).catch(()=>{});
})();