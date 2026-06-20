const CACHE_NAME = 'bierkarte-v1';
const APP_SHELL = [
  './index.html',
  './css/style.css',
  './js/app.js',
  './js/openingHours.js',
  './js/overpassService.js',
  './icons/logo.jpg',
  './manifest.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (url.origin === location.origin) {
    event.respondWith(
      caches.match(event.request).then((cached) => cached || fetch(event.request))
    );
  }
});
