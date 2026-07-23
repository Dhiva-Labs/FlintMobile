import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A search engine option.
class SearchEngine {
  final String id;
  final String name;
  final String query; // %s placeholder
  const SearchEngine(this.id, this.name, this.query);

  String urlFor(String terms) => query.replaceFirst('%s', Uri.encodeComponent(terms));
}

const kEngines = <SearchEngine>[
  SearchEngine('ddg', 'DuckDuckGo', 'https://duckduckgo.com/?q=%s'),
  SearchEngine('google', 'Google', 'https://www.google.com/search?q=%s'),
  SearchEngine('bing', 'Bing', 'https://www.bing.com/search?q=%s'),
  SearchEngine('brave', 'Brave', 'https://search.brave.com/search?q=%s'),
];

class Bookmark {
  final String url;
  final String title;
  final int added;
  Bookmark(this.url, this.title, this.added);
  Map<String, dynamic> toJson() => {'u': url, 't': title, 'a': added};
  factory Bookmark.fromJson(Map<String, dynamic> j) =>
      Bookmark(j['u'] as String, (j['t'] ?? j['u']) as String, (j['a'] ?? 0) as int);
}

class HistoryEntry {
  final String url;
  final String title;
  final int ts;
  HistoryEntry(this.url, this.title, this.ts);
  Map<String, dynamic> toJson() => {'u': url, 't': title, 's': ts};
  factory HistoryEntry.fromJson(Map<String, dynamic> j) =>
      HistoryEntry(j['u'] as String, (j['t'] ?? j['u']) as String, (j['s'] ?? 0) as int);
}

/// Persistent settings + bookmarks + history, backed by SharedPreferences.
class Store {
  Store._(this._p);
  final SharedPreferences _p;

  static Future<Store> open() async => Store._(await SharedPreferences.getInstance());

  /// Direct access for auxiliary services (e.g. the VPN) that persist their own keys.
  SharedPreferences get raw => _p;

  // ---- settings ----
  String get searchEngine => _p.getString('searchEngine') ?? 'ddg';
  set searchEngine(String v) => _p.setString('searchEngine', v);

  // theme: system | light | dark
  String get theme => _p.getString('theme') ?? 'system';
  set theme(String v) => _p.setString('theme', v);

  bool get adblockEnabled => _p.getBool('adblock') ?? true;
  set adblockEnabled(bool v) => _p.setBool('adblock', v);

  bool get desktopMode => _p.getBool('desktopMode') ?? false;
  set desktopMode(bool v) => _p.setBool('desktopMode', v);

  int get blockedTotal => _p.getInt('blockedTotal') ?? 0;
  set blockedTotal(int v) => _p.setInt('blockedTotal', v);

  SearchEngine get engine =>
      kEngines.firstWhere((e) => e.id == searchEngine, orElse: () => kEngines.first);

  List<String> get adblockAllowlist => _p.getStringList('allowlist') ?? const [];
  set adblockAllowlist(List<String> v) => _p.setStringList('allowlist', v);

  bool isAllowlisted(String host) {
    if (host.isEmpty) return false;
    return adblockAllowlist.any((h) => host == h || host.endsWith('.$h'));
  }

  void toggleAllowlist(String host) {
    final list = List<String>.from(adblockAllowlist);
    if (list.contains(host)) {
      list.remove(host);
    } else {
      list.add(host);
    }
    adblockAllowlist = list;
  }

  // ---- bookmarks ----
  List<Bookmark> get bookmarks {
    final raw = _p.getStringList('bookmarks') ?? const [];
    return raw.map((s) => Bookmark.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  bool isBookmarked(String url) => bookmarks.any((b) => b.url == url);

  bool toggleBookmark(String url, String title) {
    final list = bookmarks;
    final idx = list.indexWhere((b) => b.url == url);
    final added = idx < 0;
    if (added) {
      list.insert(0, Bookmark(url, title, DateTime.now().millisecondsSinceEpoch));
    } else {
      list.removeAt(idx);
    }
    _p.setStringList('bookmarks', list.map((b) => jsonEncode(b.toJson())).toList());
    return added;
  }

  void removeBookmark(String url) {
    final list = bookmarks..removeWhere((b) => b.url == url);
    _p.setStringList('bookmarks', list.map((b) => jsonEncode(b.toJson())).toList());
  }

  // ---- history ----
  List<HistoryEntry> get history {
    final raw = _p.getStringList('history') ?? const [];
    return raw.map((s) => HistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  void recordHistory(String url, String title) {
    if (!url.startsWith('http')) return;
    final list = history;
    list.removeWhere((h) => h.url == url);
    list.insert(0, HistoryEntry(url, title, DateTime.now().millisecondsSinceEpoch));
    if (list.length > 3000) list.removeRange(3000, list.length);
    _p.setStringList('history', list.map((h) => jsonEncode(h.toJson())).toList());
  }

  void removeHistory(String url) {
    final list = history..removeWhere((h) => h.url == url);
    _p.setStringList('history', list.map((h) => jsonEncode(h.toJson())).toList());
  }

  void clearHistory() => _p.remove('history');

  /// Top visited origins for the home speed dial.
  List<String> topSites({int limit = 8}) {
    final counts = <String, int>{};
    for (final h in history) {
      try {
        final origin = Uri.parse(h.url).origin;
        counts[origin] = (counts[origin] ?? 0) + 1;
      } catch (_) {}
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }
}
