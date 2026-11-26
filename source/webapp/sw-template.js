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
