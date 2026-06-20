// Sehr einfache Auswertung des OSM `opening_hours`-Tags.
// Deckt gängige Muster ab (z.B. "Mo-Fr 10:00-22:00; Sa-Su 12:00-23:00").
// Komplexere Syntax (PH, Feiertage, Kommentare) wird als "unknown" behandelt.

const DAY_NAMES = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

function dayMatches(dayPart, today) {
  for (const segment of dayPart.split(',')) {
    if (segment.includes('-')) {
      const [from, to] = segment.split('-');
      const startIdx = DAY_NAMES.indexOf(from);
      const endIdx = DAY_NAMES.indexOf(to);
      const todayIdx = DAY_NAMES.indexOf(today);
      if (startIdx === -1 || endIdx === -1 || todayIdx === -1) continue;
      if (startIdx <= endIdx) {
        if (todayIdx >= startIdx && todayIdx <= endIdx) return true;
      } else {
        if (todayIdx >= startIdx || todayIdx <= endIdx) return true;
      }
    } else if (segment === today) {
      return true;
    }
  }
  return false;
}

function parseTime(value) {
  const match = /^(\d{1,2}):(\d{2})$/.exec(value.trim());
  if (!match) return null;
  return parseInt(match[1], 10) * 60 + parseInt(match[2], 10);
}

// returns 'open' | 'closed' | 'unknown'
function currentOpenStatus(openingHours, now) {
  if (!openingHours || !openingHours.trim()) return 'unknown';
  const raw = openingHours.trim();
  if (raw === '24/7') return 'open';

  try {
    const today = DAY_NAMES[now.getDay() === 0 ? 6 : now.getDay() - 1];
    const rules = raw.split(';').map(r => r.trim()).filter(Boolean);
    let matchedAnyRuleForToday = false;

    for (const rule of rules) {
      const parts = rule.split(/\s+/);
      if (parts.length < 2) continue;
      const dayPart = parts[0];
      const timePart = parts.slice(1).join(' ');
      if (!dayMatches(dayPart, today)) continue;
      matchedAnyRuleForToday = true;
      if (/^(off|closed)$/i.test(timePart)) continue;

      for (const span of timePart.split(',')) {
        const times = span.split('-');
        if (times.length !== 2) continue;
        const start = parseTime(times[0]);
        const end = parseTime(times[1]);
        if (start === null || end === null) continue;
        const nowMinutes = now.getHours() * 60 + now.getMinutes();
        if (end > start) {
          if (nowMinutes >= start && nowMinutes < end) return 'open';
        } else {
          if (nowMinutes >= start || nowMinutes < end) return 'open';
        }
      }
    }
    return matchedAnyRuleForToday ? 'closed' : 'unknown';
  } catch (e) {
    return 'unknown';
  }
}
