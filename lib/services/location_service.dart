import 'dart:convert';
import 'package:http/http.dart' as http;

/// Figures out roughly where a student is signing up from — city,
/// region, country — using IP-based lookup. No location permission
/// dialog needed, so it never blocks or scares off a student during
/// signup.
///
/// This is approximate (based on the phone's internet connection),
/// not exact GPS. That's intentional: it's just meant to let the app
/// owner see "signups are coming from Lahore / Karachi / etc.", not
/// to pinpoint a device.
class LocationService {
  static const _lookupUrl = 'https://ipwho.is/';

  /// Returns a map with city/region/country/ip, or a map with just
  /// 'note': 'unavailable' if the lookup fails (e.g. no internet).
  /// Always resolves — never throws — so it never stops signup.
  Future<Map<String, String>> getSignupLocation() async {
    try {
      final response = await http
          .get(Uri.parse(_lookupUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        return {'note': 'unavailable'};
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == false) {
        return {'note': 'unavailable'};
      }

      return {
        'city': (data['city'] ?? '').toString(),
        'region': (data['region'] ?? '').toString(),
        'country': (data['country'] ?? '').toString(),
        'ip': (data['ip'] ?? '').toString(),
      };
    } catch (_) {
      // No internet yet, lookup service down, timeout, etc. — signup
      // should still work fine without this.
      return {'note': 'unavailable'};
    }
  }

  /// Human-readable one-liner for display/logging, e.g. "Lahore, Punjab, Pakistan".
  String describe(Map<String, String> location) {
    if (location['note'] == 'unavailable') return 'Unknown';
    final parts = [location['city'], location['region'], location['country']]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Unknown' : parts.join(', ');
  }
}
