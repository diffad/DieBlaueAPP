/// Sehr einfache Auswertung des OSM `opening_hours`-Tags.
/// Deckt die häufigsten Muster ab (z.B. "Mo-Fr 10:00-22:00; Sa-Su 12:00-23:00").
/// Komplexere Syntax (PH, Feiertage, Kommentare) wird als "unbekannt" behandelt.
enum OpenStatus { open, closed, unknown }

const _dayNames = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

OpenStatus currentOpenStatus(String? openingHours, DateTime now) {
  if (openingHours == null || openingHours.trim().isEmpty) {
    return OpenStatus.unknown;
  }
  final raw = openingHours.trim();
  if (raw == '24/7') return OpenStatus.open;

  try {
    final today = _dayNames[now.weekday - 1];
    final rules = raw.split(';').map((r) => r.trim()).where((r) => r.isNotEmpty);
    bool matchedAnyRuleForToday = false;
    for (final rule in rules) {
      final parts = rule.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final dayPart = parts[0];
      final timePart = parts.sublist(1).join(' ');
      if (!_dayMatches(dayPart, today)) continue;
      matchedAnyRuleForToday = true;
      if (timePart.toLowerCase() == 'off' || timePart.toLowerCase() == 'closed') {
        continue;
      }
      for (final span in timePart.split(',')) {
        final times = span.split('-');
        if (times.length != 2) continue;
        final start = _parseTime(times[0]);
        final end = _parseTime(times[1]);
        if (start == null || end == null) continue;
        final nowMinutes = now.hour * 60 + now.minute;
        if (end > start) {
          if (nowMinutes >= start && nowMinutes < end) return OpenStatus.open;
        } else {
          // Über Mitternacht hinaus geöffnet (z.B. 18:00-02:00)
          if (nowMinutes >= start || nowMinutes < end) return OpenStatus.open;
        }
      }
    }
    return matchedAnyRuleForToday ? OpenStatus.closed : OpenStatus.unknown;
  } catch (_) {
    return OpenStatus.unknown;
  }
}

bool _dayMatches(String dayPart, String today) {
  for (final segment in dayPart.split(',')) {
    if (segment.contains('-')) {
      final range = segment.split('-');
      if (range.length != 2) continue;
      final startIdx = _dayNames.indexOf(range[0]);
      final endIdx = _dayNames.indexOf(range[1]);
      final todayIdx = _dayNames.indexOf(today);
      if (startIdx == -1 || endIdx == -1 || todayIdx == -1) continue;
      if (startIdx <= endIdx) {
        if (todayIdx >= startIdx && todayIdx <= endIdx) return true;
      } else {
        if (todayIdx >= startIdx || todayIdx <= endIdx) return true;
      }
    } else if (segment == today) {
      return true;
    }
  }
  return false;
}

int? _parseTime(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  return hours * 60 + minutes;
}
