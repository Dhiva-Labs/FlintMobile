import 'package:flutter/services.dart' show rootBundle;

/// Network-level ad & tracker blocking using a bundled domain blocklist.
///
/// Blocking is done by hostname: a request is blocked when its host — or any of
/// its parent domains — is on the list. This is fast (hash-set lookups) and
/// covers the ad/tracker networks most pages pull in. It never touches page
/// content it cannot classify, and a per-site allowlist lets the user disable
/// blocking where a site breaks.
class AdBlock {
  final Set<String> _domains = <String>{};
  bool ready = false;

  Future<void> load() async {
    if (ready) return;
    try {
      final text = await rootBundle.loadString('assets/adblock/domains.txt');
      for (final line in text.split('\n')) {
        final d = line.trim();
        if (d.isNotEmpty && !d.startsWith('#')) _domains.add(d);
      }
      ready = true;
    } catch (_) {
      ready = false;
    }
  }

  int get size => _domains.length;

  /// True if [host] or a parent domain is blocklisted.
  bool blocks(String host) {
    if (_domains.isEmpty || host.isEmpty) return false;
    host = host.toLowerCase();
    if (_domains.contains(host)) return true;
    var idx = host.indexOf('.');
    // Walk parent domains: a.b.c.com -> b.c.com -> c.com
    while (idx != -1) {
      final parent = host.substring(idx + 1);
      if (!parent.contains('.')) break;
      if (_domains.contains(parent)) return true;
      idx = host.indexOf('.', idx + 1);
    }
    return false;
  }
}
