const FALLBACK_CENTER = [52.5200, 13.4050]; // Berlin

let map;
let userMarker;
let placeMarkers = [];
let popInTimers = [];
let placesById = new Map();
let selectedCategories = new Set(['biergarten', 'kneipe', 'restaurant', 'tankstelle', 'sonstiges']);
let onlyOpenNow = false;
let center = FALLBACK_CENTER;

const $loading = document.getElementById('loadingOverlay');
const $error = document.getElementById('errorBanner');
const $sheet = document.getElementById('detailsSheet');
const $sheetContent = document.getElementById('detailsContent');
const $sheetBackdrop = document.getElementById('sheetBackdrop');
const $toggleOpenNow = document.getElementById('toggleOpenNow');
const $nearestInfo = document.getElementById('nearestInfo');

function distanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function formatDistance(meters) {
  if (meters >= 1000) return `${(meters / 1000).toFixed(1)} km`;
  return `${Math.round(meters)} m`;
}

function updateNearestInfo(places) {
  if (!places.length) {
    $nearestInfo.classList.add('hidden');
    return;
  }
  const nearest = places
    .map((place) => ({ place, distance: distanceMeters(center[0], center[1], place.lat, place.lon) }))
    .sort((a, b) => a.distance - b.distance)
    .slice(0, 3);
  if (!nearest.length) {
    $nearestInfo.classList.add('hidden');
    return;
  }
  const labels = ['Nächstes Bier', '2. nächstes Bier', '3. nächstes Bier'];
  $nearestInfo.innerHTML = nearest
    .map(({ place, distance }, i) => `<div>🍺 ${labels[i]}: ${escapeHtml(place.name)} – ${formatDistance(distance)} entfernt</div>`)
    .join('');
  $nearestInfo.classList.remove('hidden');
}

function setLoading(isLoading) {
  $loading.classList.toggle('hidden', !isLoading);
}

function showError(message) {
  if (!message) {
    $error.classList.add('hidden');
    return;
  }
  $error.textContent = message;
  $error.classList.remove('hidden');
}

function initMap() {
  map = L.map('map', { zoomControl: true }).setView(center, 14);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 19,
  }).addTo(map);

  userMarker = L.marker(center, {
    icon: L.divIcon({ className: 'marker-emoji user-marker', html: '📍', iconSize: [30, 30] }),
  }).addTo(map);
}

function locateUser() {
  return new Promise((resolve) => {
    if (!navigator.geolocation) {
      resolve();
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        center = [pos.coords.latitude, pos.coords.longitude];
        map.setView(center, 14);
        userMarker.setLatLng(center);
        resolve();
      },
      () => resolve(),
      { timeout: 8000 }
    );
  });
}

function renderMarkers() {
  placeMarkers.forEach((m) => map.removeLayer(m));
  placeMarkers = [];
  popInTimers.forEach((t) => clearTimeout(t));
  popInTimers = [];

  const filtered = Array.from(placesById.values()).filter((place) => {
    if (!selectedCategories.has(place.category)) return false;
    if (onlyOpenNow && currentOpenStatus(place.openingHoursRaw, new Date()) !== 'open') {
      return false;
    }
    return true;
  });

  filtered.forEach((place, index) => {
    const marker = L.marker([place.lat, place.lon], {
      icon: L.divIcon({ className: 'marker-emoji marker-pop-in', html: `<span class="beer-emoji">${place.emoji}</span>`, iconSize: [32, 32] }),
    });
    marker.on('click', () => showDetails(place));
    placeMarkers.push(marker);

    const timer = setTimeout(() => {
      marker.addTo(map);
      const el = marker.getElement();
      if (el) requestAnimationFrame(() => el.classList.add('marker-pop-in-visible'));
    }, index * 40);
    popInTimers.push(timer);
  });

  updateNearestInfo(filtered);
}

function statusInfo(status, raw) {
  if (status === 'open') return { cls: 'status-open', icon: '✅', label: 'Jetzt geöffnet' };
  if (status === 'closed') return { cls: 'status-closed', icon: '⛔', label: 'Aktuell geschlossen' };
  return {
    cls: 'status-unknown',
    icon: '❓',
    label: raw ? 'Öffnungszeiten nicht eindeutig' : 'Öffnungszeiten unbekannt',
  };
}

function showDetails(place) {
  const status = currentOpenStatus(place.openingHoursRaw, new Date());
  const info = statusInfo(status, place.openingHoursRaw);

  const googleMapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${place.name} ${place.lat},${place.lon}`)}`;

  $sheetContent.innerHTML = `
    <div class="detail-title"><span class="beer-emoji">${place.emoji}</span><span>${escapeHtml(place.name)}</span></div>
    <div class="detail-category">${place.label}</div>
    ${place.address ? `<div class="detail-row">📍 ${escapeHtml(place.address)}</div>` : ''}
    <div class="detail-row ${info.cls}">${info.icon} ${info.label}</div>
    ${place.openingHoursRaw ? `<div class="opening-hours-raw">${escapeHtml(place.openingHoursRaw)}</div>` : ''}
    <a class="google-maps-link" href="${googleMapsUrl}" target="_blank" rel="noopener">⭐ Bewertungen &amp; Öffnungszeiten auf Google Maps ansehen →</a>
  `;
  $sheet.classList.remove('hidden');
  $sheetBackdrop.classList.remove('hidden');
}

function hideDetails() {
  $sheet.classList.add('hidden');
  $sheetBackdrop.classList.add('hidden');
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// Lädt Orte für den aktuell sichtbaren Kartenausschnitt (mit etwas Rand)
// und fügt sie zum bestehenden Bestand hinzu, statt ihn zu ersetzen –
// so bleiben bereits geladene Bereiche beim Weiterzoomen/-scrollen erhalten.
async function loadPlacesForCurrentView() {
  setLoading(true);
  showError(null);
  try {
    const bounds = map.getBounds().pad(0.2);
    const bbox = {
      south: bounds.getSouth(),
      west: bounds.getWest(),
      north: bounds.getNorth(),
      east: bounds.getEast(),
    };
    const places = await fetchPlacesInBounds(bbox);
    places.forEach((place) => placesById.set(place.id, place));
    renderMarkers();
  } catch (e) {
    showError(`Orte konnten nicht geladen werden: ${e.message}`);
  } finally {
    setLoading(false);
  }
}

function setupFilters() {
  document.querySelectorAll('#categoryFilters .chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      const category = chip.dataset.category;
      if (selectedCategories.has(category)) {
        selectedCategories.delete(category);
        chip.classList.remove('active');
      } else {
        selectedCategories.add(category);
        chip.classList.add('active');
      }
      renderMarkers();
    });
  });
}

async function reloadIfNewVersionAvailable() {
  try {
    const response = await fetch('index.html', { cache: 'no-store' });
    const html = await response.text();
    const match = /APP_VERSION\s*=\s*'([^']+)'/.exec(html);
    if (match && match[1] !== APP_VERSION) {
      window.location.reload();
      return true;
    }
  } catch (e) {
    // Versions-Check ist best-effort; bei Fehlern einfach normal weiterladen.
  }
  return false;
}

function setupHeaderActions() {
  $toggleOpenNow.addEventListener('click', () => {
    onlyOpenNow = !onlyOpenNow;
    $toggleOpenNow.classList.toggle('active', onlyOpenNow);
    renderMarkers();
  });
  document.getElementById('refreshBtn').addEventListener('click', loadPlacesForCurrentView);
  document.getElementById('appLogo').addEventListener('click', reloadIfNewVersionAvailable);
  $sheetBackdrop.addEventListener('click', hideDetails);
}

function unregisterServiceWorkers() {
  if (!('serviceWorker' in navigator)) return;
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    registrations.forEach((reg) => reg.unregister());
  });
  if (window.caches) {
    caches.keys().then((keys) => keys.forEach((key) => caches.delete(key)));
  }
}

async function main() {
  document.getElementById('appVersion').textContent = `v${APP_VERSION}`;
  unregisterServiceWorkers();
  initMap();
  setupFilters();
  setupHeaderActions();
  setLoading(true);
  await locateUser();
  await loadPlacesForCurrentView();
}

main();
