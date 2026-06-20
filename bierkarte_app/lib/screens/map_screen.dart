import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/beer_place.dart';
import '../services/opening_hours.dart';
import '../services/overpass_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/place_details_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallbackCenter = LatLng(52.5200, 13.4050); // Berlin

  final _overpassService = OverpassService();
  final _mapController = MapController();

  LatLng _center = _fallbackCenter;
  List<BeerPlace> _places = [];
  bool _isLoading = false;
  String? _error;
  bool _onlyOpenNow = false;

  Set<PlaceCategory> _selectedCategories = {
    PlaceCategory.biergarten,
    PlaceCategory.kneipe,
    PlaceCategory.restaurant,
    PlaceCategory.tankstelle,
    PlaceCategory.sonstiges,
  };

  @override
  void initState() {
    super.initState();
    _initLocationAndLoad();
  }

  Future<void> _initLocationAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (permission == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.always ||
          granted == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        _center = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      // Fällt auf Standardstandort zurück, wenn kein Standort verfügbar ist.
    }
    await _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final places = await _overpassService.fetchNearbyPlaces(_center);
      setState(() => _places = places);
    } catch (e) {
      setState(() => _error = 'Orte konnten nicht geladen werden: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<BeerPlace> get _filteredPlaces {
    return _places.where((place) {
      if (!_selectedCategories.contains(place.category)) return false;
      if (_onlyOpenNow) {
        final status = currentOpenStatus(place.openingHoursRaw, DateTime.now());
        if (status != OpenStatus.open) return false;
      }
      return true;
    }).toList();
  }

  void _toggleCategory(PlaceCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _showPlaceDetails(BeerPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PlaceDetailsSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/images/logo.jpg', width: 32, height: 32),
            ),
            const SizedBox(width: 10),
            const Text('DieBlaueAPP'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_onlyOpenNow ? Icons.access_time_filled : Icons.access_time),
            tooltip: 'Nur jetzt geöffnete Orte anzeigen',
            onPressed: () => setState(() => _onlyOpenNow = !_onlyOpenNow),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaces,
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryFilterBar(
            selected: _selectedCategories,
            onToggle: _toggleCategory,
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade900,
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dieblaueapp.bierkarte',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.my_location, color: AppColors.beerGold),
                        ),
                        ..._filteredPlaces.map(
                          (place) => Marker(
                            point: place.location,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showPlaceDetails(place),
                              child: Text(
                                place.category.markerEmoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
