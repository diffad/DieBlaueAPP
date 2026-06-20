import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/beer_place.dart';

/// Lädt Biergärten, Kneipen/Bars, Restaurants und Tankstellen im Umkreis
/// eines Punktes über die kostenlose Overpass-API (OpenStreetMap-Daten).
class OverpassService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<BeerPlace>> fetchNearbyPlaces(
    LatLng center, {
    double radiusMeters = 3000,
  }) async {
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="biergarten"](around:$radiusMeters,${center.latitude},${center.longitude});
        node["amenity"="bar"](around:$radiusMeters,${center.latitude},${center.longitude});
        node["amenity"="pub"](around:$radiusMeters,${center.latitude},${center.longitude});
        node["amenity"="restaurant"](around:$radiusMeters,${center.latitude},${center.longitude});
        node["amenity"="fuel"](around:$radiusMeters,${center.latitude},${center.longitude});
        way["amenity"="biergarten"](around:$radiusMeters,${center.latitude},${center.longitude});
        way["amenity"="bar"](around:$radiusMeters,${center.latitude},${center.longitude});
        way["amenity"="pub"](around:$radiusMeters,${center.latitude},${center.longitude});
        way["amenity"="restaurant"](around:$radiusMeters,${center.latitude},${center.longitude});
        way["amenity"="fuel"](around:$radiusMeters,${center.latitude},${center.longitude});
      );
      out center tags;
    ''';

    final response = await http.post(
      Uri.parse(_endpoint),
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception('Overpass-Anfrage fehlgeschlagen: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List).cast<Map<String, dynamic>>();
    return elements.map(BeerPlace.fromOverpassElement).toList();
  }
}
