// Lädt Biergärten, Kneipen/Bars, Restaurants und Tankstellen im Umkreis
// eines Punktes über die kostenlose Overpass-API (OpenStreetMap-Daten).

const OVERPASS_ENDPOINTS = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.openstreetmap.ru/api/interpreter',
];

function categoryFromTags(tags) {
  const amenity = tags.amenity;
  if (amenity === 'biergarten') return 'biergarten';
  if (amenity === 'bar' || amenity === 'pub') return 'kneipe';
  if (amenity === 'restaurant' || amenity === 'fast_food') return 'restaurant';
  if (amenity === 'fuel') return 'tankstelle';
  return 'sonstiges';
}

const CATEGORY_EMOJI = {
  biergarten: '🌳',
  kneipe: '🍻',
  restaurant: '🍽',
  tankstelle: '⛽',
  sonstiges: '🍺',
};

const CATEGORY_ACCENT = {
  biergarten: { icon: '🍺', pos: 'pos-br' },
  restaurant: { icon: '🍺', pos: 'pos-tl' },
  tankstelle: { icon: '🥫', pos: 'pos-top' },
};

const CATEGORY_LABEL = {
  biergarten: 'Biergarten',
  kneipe: 'Kneipe / Bar',
  restaurant: 'Restaurant',
  tankstelle: 'Tankstelle',
  sonstiges: 'Sonstiges',
};

function elementToPlace(element) {
  const tags = element.tags || {};
  let lat, lon;
  if (element.type === 'node') {
    lat = element.lat;
    lon = element.lon;
  } else {
    lat = element.center.lat;
    lon = element.center.lon;
  }
  const street = tags['addr:street'];
  const houseNumber = tags['addr:housenumber'];
  const city = tags['addr:city'];
  const addressParts = [];
  if (street) addressParts.push(houseNumber ? `${street} ${houseNumber}` : street);
  if (city) addressParts.push(city);

  const category = categoryFromTags(tags);
  return {
    id: `${element.type}/${element.id}`,
    name: tags.name || 'Unbenannt',
    category,
    emoji: CATEGORY_EMOJI[category],
    accent: CATEGORY_ACCENT[category] || null,
    label: CATEGORY_LABEL[category],
    lat,
    lon,
    openingHoursRaw: tags.opening_hours || null,
    address: addressParts.length ? addressParts.join(', ') : null,
  };
}

// bbox: { south, west, north, east } – z.B. aus Leaflet map.getBounds()
async function fetchPlacesInBounds(bbox) {
  const bboxStr = `${bbox.south},${bbox.west},${bbox.north},${bbox.east}`;
  const query = `
    [out:json][timeout:25];
    (
      node["amenity"="biergarten"](${bboxStr});
      node["amenity"="bar"](${bboxStr});
      node["amenity"="pub"](${bboxStr});
      node["amenity"="restaurant"](${bboxStr});
      node["amenity"="fuel"](${bboxStr});
      way["amenity"="biergarten"](${bboxStr});
      way["amenity"="bar"](${bboxStr});
      way["amenity"="pub"](${bboxStr});
      way["amenity"="restaurant"](${bboxStr});
      way["amenity"="fuel"](${bboxStr});
    );
    out center tags;
  `;

  let lastError;
  for (const endpoint of OVERPASS_ENDPOINTS) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        body: `data=${encodeURIComponent(query)}`,
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      });
      if (!response.ok) {
        lastError = new Error(`Overpass-Anfrage fehlgeschlagen: ${response.status}`);
        continue;
      }
      const data = await response.json();
      return data.elements.map(elementToPlace);
    } catch (e) {
      lastError = e;
    }
  }
  throw lastError;
}
