const CACHE='shatranj-29e2c626e112a9';
const ASSETS=["app-icon-180.png", "app-icon-192.png", "app-icon-512.png", "audio-credits.txt", "computer.js", "icon.svg", "index.apple-touch-icon.png", "index.audio.position.worklet.js", "index.audio.worklet.js", "index.html", "index.icon.png", "index.js", "index.pck.0.bin", "index.pck.1.bin", "index.png", "index.wasm.gz", "install.css", "install.js", "manifest.webmanifest", "startup-recovery.js", "stockfish/COPYING.txt", "stockfish/checksums.txt", "stockfish/credits.html", "stockfish/stockfish-19-lite-single.js", "stockfish/stockfish-19-lite-single.wasm"];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(ASSETS.map(name => new Request(new URL(name,self.registration.scope),{cache:'reload'})))));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith('shatranj-') && key !== CACHE).map(key => caches.delete(key)))).then(()=>self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const url=new URL(event.request.url),scope=new URL(self.registration.scope);
  if(event.request.method!=='GET' || url.origin!==scope.origin || !url.pathname.startsWith(scope.pathname))return;
  let name=url.pathname.slice(scope.pathname.length);
  if(name==='' || name==='index.html')name='index.html';
  if(!ASSETS.includes(name))return;
  event.respondWith(caches.open(CACHE).then(async cache => (await cache.match(new URL(name,scope).href)) || fetch(event.request)));
});

// Activate only after an explicit Update click; never interrupt a live match automatically.
self.addEventListener('message', event => {
  if(event.data && event.data.type==='ACTIVATE_UPDATE')event.waitUntil(self.skipWaiting());
});
