import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'store.dart';

/// A proxy/VPN exit server the user has configured.
class ProxyServer {
  ProxyServer(this.label, this.url);
  final String label;
  final String url; // e.g. https://host:8080, socks5://host:1080
  Map<String, dynamic> toJson() => {'l': label, 'u': url};
  factory ProxyServer.fromJson(Map<String, dynamic> j) =>
      ProxyServer(j['l'] as String, j['u'] as String);

  String get host {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }
}

/// Opera-style "browser VPN": routes the browser's traffic through a remote
/// secure proxy the user chooses. Flint operates no servers and keeps no logs —
/// the exit server is one the user supplies (their own, or a provider's). Only
/// the browser's traffic is routed, not the whole device.
///
/// Implemented with Android's WebView ProxyController (PROXY_OVERRIDE), which is
/// the same mechanism a browser-scoped VPN uses.
class Vpn extends ChangeNotifier {
  Vpn(this._store) {
    _load();
  }

  final Store _store;

  final List<ProxyServer> servers = [];
  int active = -1;
  bool enabled = false;
  bool supported = true;
  String? lastError;

  bool get isOn => enabled && active >= 0 && active < servers.length;
  ProxyServer? get current => isOn ? servers[active] : null;

  void _load() {
    final raw = _store.raw.getStringList('proxyServers') ?? const [];
    servers
      ..clear()
      ..addAll(raw.map((s) => ProxyServer.fromJson(jsonDecode(s) as Map<String, dynamic>)));
    active = _store.raw.getInt('proxyActive') ?? -1;
    enabled = _store.raw.getBool('vpnOn') ?? false;
    if (active >= servers.length) active = servers.isEmpty ? -1 : 0;
  }

  void _save() {
    _store.raw.setStringList('proxyServers', servers.map((s) => jsonEncode(s.toJson())).toList());
    _store.raw.setInt('proxyActive', active);
    _store.raw.setBool('vpnOn', enabled);
  }

  Future<void> init() async {
    try {
      supported = await WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE);
    } catch (_) {
      supported = false;
    }
    if (isOn) await _apply();
  }

  void addServer(String label, String url) {
    url = url.trim();
    if (!RegExp(r'^(https?|socks4?|socks5)://', caseSensitive: false).hasMatch(url)) {
      // default to a secure http proxy if the user omitted the scheme
      url = 'https://$url';
    }
    servers.add(ProxyServer(label.trim().isEmpty ? _hostOf(url) : label.trim(), url));
    if (active < 0) active = servers.length - 1;
    _save();
    notifyListeners();
  }

  void removeServer(int index) {
    if (index < 0 || index >= servers.length) return;
    servers.removeAt(index);
    if (active == index) {
      active = servers.isEmpty ? -1 : 0;
      if (enabled) toggle(false);
    } else if (active > index) {
      active--;
    }
    _save();
    notifyListeners();
  }

  Future<void> select(int index) async {
    if (index < 0 || index >= servers.length) return;
    active = index;
    _save();
    if (enabled) await _apply();
    notifyListeners();
  }

  Future<bool> toggle(bool on) async {
    if (on && (active < 0 || servers.isEmpty)) return false;
    enabled = on;
    _save();
    final ok = on ? await _apply() : await _clear();
    notifyListeners();
    return ok;
  }

  Future<bool> _apply() async {
    lastError = null;
    if (!supported) {
      lastError = 'This device\'s WebView does not support proxying.';
      return false;
    }
    final server = current;
    if (server == null) return false;
    try {
      await ProxyController.instance().setProxyOverride(
        settings: ProxySettings(
          proxyRules: [ProxyRule(url: server.url)],
          bypassRules: ['localhost', '127.0.0.1'],
        ),
      );
      return true;
    } catch (e) {
      lastError = e.toString();
      enabled = false;
      _save();
      return false;
    }
  }

  Future<bool> _clear() async {
    try {
      await ProxyController.instance().clearProxyOverride();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }
}
