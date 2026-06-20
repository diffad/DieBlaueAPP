import 'package:flutter/material.dart';

import '../models/beer_place.dart';
import '../services/opening_hours.dart';
import '../theme/app_theme.dart';

class PlaceDetailsSheet extends StatelessWidget {
  final BeerPlace place;

  const PlaceDetailsSheet({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final status = currentOpenStatus(place.openingHoursRaw, DateTime.now());
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(place.category.markerEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(place.category.label, style: const TextStyle(color: AppColors.beerGold)),
            if (place.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(child: Text(place.address!)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(status, place.openingHoursRaw),
                  style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (place.openingHoursRaw != null) ...[
              const SizedBox(height: 4),
              Text(
                place.openingHoursRaw!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(OpenStatus status) {
    switch (status) {
      case OpenStatus.open:
        return Icons.check_circle;
      case OpenStatus.closed:
        return Icons.cancel;
      case OpenStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _statusColor(OpenStatus status) {
    switch (status) {
      case OpenStatus.open:
        return Colors.greenAccent;
      case OpenStatus.closed:
        return Colors.redAccent;
      case OpenStatus.unknown:
        return Colors.white70;
    }
  }

  String _statusLabel(OpenStatus status, String? raw) {
    switch (status) {
      case OpenStatus.open:
        return 'Jetzt geöffnet';
      case OpenStatus.closed:
        return 'Aktuell geschlossen';
      case OpenStatus.unknown:
        return raw == null ? 'Öffnungszeiten unbekannt' : 'Öffnungszeiten nicht eindeutig';
    }
  }
}
