# DieBlaueAPP – Bierkarte (Web-App / PWA)

Reine HTML/JavaScript-Version der Bierkarten-App – kein Build-Prozess,
kein SDK nötig. Läuft direkt im Browser und ist als PWA installierbar
(„Zum Startbildschirm hinzufügen").

## Technik

- **Karte:** OpenStreetMap-Tiles via [Leaflet.js](https://leafletjs.com/) (kostenlos, kein API-Key).
- **Ortsdaten:** Overpass API (OpenStreetMap) – Name, Kategorie, Adresse,
  `opening_hours`.
- **Design:** Dunkles Blau (`css/style.css`, Variable `--dark-blue`).
- **Marker:** Bier-Emoji je Kategorie (`js/overpassService.js` → `CATEGORY_EMOJI`).
- **PWA:** `manifest.json` + `sw.js` (Service Worker für Offline-Caching des App-Shells).

## Lokal testen

Im Ordner `webapp/`:

```bash
python3 -m http.server 8000
```

Dann im Browser öffnen: http://localhost:8000

(Browser-Geolocation funktioniert nur über `https://` oder `localhost` – für
lokale Tests ist `localhost` also völlig ausreichend.)

## Auf dem Handy testen

1. PC und Handy müssen im selben WLAN sein.
2. Lokale IP des PCs ermitteln: `hostname -I` (Linux Mint).
3. Auf dem Handy im Browser öffnen: `http://<PC-IP>:8000`
   - Achtung: Geolocation funktioniert über `http://<IP>` meist **nicht**
     (Browser verlangen HTTPS oder localhost). Die Karte und alle Orte
     werden trotzdem angezeigt, nur der Standort fällt auf Berlin zurück.
4. Für volle Geolocation-Unterstützung auf dem Handy: Web-App auf einem
   echten Hosting mit HTTPS deployen (z.B. GitHub Pages, Netlify, Vercel –
   alle kostenlos) und dort öffnen.

## Als App installieren (PWA)

- **Android (Chrome):** Seite öffnen → Menü (⋮) → "Zum Startbildschirm hinzufügen" / "App installieren".
- **iPhone (Safari):** Seite öffnen → Teilen-Symbol → "Zum Home-Bildschirm".

## Bekannte Einschränkungen (MVP)

- `opening_hours`-Parsing deckt nur gängige Muster ab, keine Feiertags-/PH-Syntax.
- Reine Anzeige, kein Hinzufügen eigener Orte/Bewertungen.
- Geolocation per HTTP (ohne HTTPS) ist in modernen Browsern eingeschränkt –
  für volle Funktion auf HTTPS deployen.
