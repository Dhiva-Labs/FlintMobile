import '../services/store.dart';

/// Resolve omnibox input to a navigable URL: a URL if it looks like one,
/// otherwise a search on the chosen engine.
String resolveInput(String raw, SearchEngine engine) {
  final text = raw.trim();
  if (text.isEmpty) return '';

  // localhost and bare IPs first, before the scheme check (otherwise
  // "localhost:8080" reads as a scheme named "localhost").
  if (text == 'localhost' || text.startsWith('localhost:') || text.startsWith('localhost/')) {
    return 'http://$text';
  }
  final ipish = RegExp(r'^\d{1,3}(\.\d{1,3}){3}([:/].*)?$');
  if (ipish.hasMatch(text)) return 'http://$text';

  // Explicit scheme.
  final scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');
  if (scheme.hasMatch(text)) {
    if (RegExp(r'^(https?|ftp|file|mailto|tel):', caseSensitive: false).hasMatch(text)) {
      return text;
    }
    return engine.urlFor(text);
  }

  // A single token containing a dot and no spaces → treat as a domain.
  final domainish = RegExp(r'^[^\s]+\.[^\s]{2,}$');
  if (!text.contains(' ') && domainish.hasMatch(text)) {
    return 'https://$text';
  }
  return engine.urlFor(text);
}

String hostOf(String url) {
  try {
    return Uri.parse(url).host;
  } catch (_) {
    return '';
  }
}

String prettyUrl(String url) {
  if (url.isEmpty || url == 'about:blank' || url.startsWith('flint:')) return '';
  return url;
}
