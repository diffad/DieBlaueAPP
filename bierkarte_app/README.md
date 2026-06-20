# DieBlaueAPP – Bierkarte

Flutter-App, die Biergärten, Kneipen/Bars, Restaurants und Tankstellen mit
Bier in deiner Umgebung auf einer Karte anzeigt – inklusive Öffnungszeiten.

## Technik

- **Karte:** OpenStreetMap-Tiles via `flutter_map` (kostenlos, kein API-Key).
- **Ortsdaten:** Overpass API (OpenStreetMap) – liefert Name, Kategorie,
  Adresse und `opening_hours`, sofern in OSM gepflegt.
- **Design:** Dunkles Blau als Hauptfarbe (`lib/theme/app_theme.dart`).
- **Marker:** Je Kategorie ein eigenes Bier-Emoji-Symbol
  (`lib/models/beer_place.dart` → `markerEmoji`).

## Setup

1. Flutter SDK installieren (>= 3.x): https://docs.flutter.dev/get-started/install
2. Abhängigkeiten installieren:
   ```
   flutter pub get
   ```
3. App starten:
   ```
   flutter run
   ```

### Berechtigungen

Für die Standortfreigabe müssen native Berechtigungen ergänzt werden, sobald
die Android/iOS-Plattformordner generiert sind (`flutter create .` im
Projektordner ausführen, falls die Ordner `android/` und `ios/` fehlen):

- **Android** (`android/app/src/main/AndroidManifest.xml`):
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  ```
- **iOS** (`ios/Runner/Info.plist`):
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Wird benötigt, um Orte mit Bier in deiner Nähe zu finden.</string>
  ```

## App-Icon aus dem Logo erstellen

Das hochgeladene Logo liegt unter `assets/images/logo.jpg`. Mit dem Paket
[`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
lässt sich daraus automatisch das App-Icon für Android/iOS generieren.

## Bekannte Einschränkungen (MVP)

- `opening_hours`-Parsing deckt nur gängige Muster ab (z.B.
  `Mo-Fr 10:00-22:00; Sa-Su 12:00-23:00`), keine Feiertags-/PH-Syntax.
- Reine Anzeige, kein Hinzufügen eigener Orte/Bewertungen (laut Absprache
  für MVP nicht vorgesehen).
- Datenqualität hängt von OpenStreetMap ab – nicht jeder Ort hat
  `opening_hours` gepflegt.
