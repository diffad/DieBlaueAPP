import 'package:latlong2/latlong.dart';

enum PlaceCategory { biergarten, kneipe, restaurant, tankstelle, sonstiges }

extension PlaceCategoryX on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.biergarten:
        return 'Biergarten';
      case PlaceCategory.kneipe:
        return 'Kneipe / Bar';
      case PlaceCategory.restaurant:
        return 'Restaurant';
      case PlaceCategory.tankstelle:
        return 'Tankstelle';
      case PlaceCategory.sonstiges:
        return 'Sonstiges';
    }
  }

  /// Emoji-Bier-Symbol je Kategorie, wird auf der Karte als Marker genutzt.
  String get markerEmoji {
    switch (this) {
      case PlaceCategory.biergarten:
        return '🍺🌳';
      case PlaceCategory.kneipe:
        return '🍻';
      case PlaceCategory.restaurant:
        return '🍺🍽';
      case PlaceCategory.tankstelle:
        return '🍺⛽';
      case PlaceCategory.sonstiges:
        return '🍺';
    }
  }
}

class BeerPlace {
  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final String? openingHoursRaw;
  final String? address;

  BeerPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.openingHoursRaw,
    this.address,
  });

  static PlaceCategory categoryFromTags(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String?;
    final shop = tags['shop'] as String?;
    if (amenity == 'biergarten') return PlaceCategory.biergarten;
    if (amenity == 'bar' || amenity == 'pub') return PlaceCategory.kneipe;
    if (amenity == 'restaurant' || amenity == 'fast_food') {
      return PlaceCategory.restaurant;
    }
    if (amenity == 'fuel' || shop == 'convenience' && tags['fuel'] != null) {
      return PlaceCategory.tankstelle;
    }
    return PlaceCategory.sonstiges;
  }

  factory BeerPlace.fromOverpassElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
    double lat;
    double lon;
    if (element['type'] == 'node') {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    } else {
      final center = element['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num).toDouble();
      lon = (center['lon'] as num).toDouble();
    }
    final street = tags['addr:street'];
    final houseNumber = tags['addr:housenumber'];
    final city = tags['addr:city'];
    final addressParts = [
      if (street != null) '$street${houseNumber != null ? ' $houseNumber' : ''}',
      if (city != null) city,
    ];
    return BeerPlace(
      id: '${element['type']}/${element['id']}',
      name: (tags['name'] as String?) ?? 'Unbenannt',
      category: categoryFromTags(tags),
      location: LatLng(lat, lon),
      openingHoursRaw: tags['opening_hours'] as String?,
      address: addressParts.isEmpty ? null : addressParts.join(', '),
    );
  }
}
