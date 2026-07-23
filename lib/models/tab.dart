import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// One browser tab. Owns its own InAppWebView state and notifies listeners as
/// its title / url / progress / block-count change.
class BrowserTab extends ChangeNotifier {
  BrowserTab({required this.id, required this.initialUrl, this.incognito = false});

  final int id;
  final String initialUrl;
  final bool incognito;

  InAppWebViewController? controller;

  String url = '';
  String title = 'New Tab';
  String host = '';
  double progress = 0;
  bool isLoading = false;
  bool canGoBack = false;
  bool canGoForward = false;
  int blocked = 0;
  bool get isHome => url.isEmpty || url == 'about:blank';

  Uint8List? thumbnail;

  void update({
    String? url,
    String? title,
    double? progress,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    if (url != null) {
      this.url = url;
      host = _hostOf(url);
    }
    if (title != null && title.isNotEmpty) this.title = title;
    if (progress != null) this.progress = progress;
    if (isLoading != null) this.isLoading = isLoading;
    if (canGoBack != null) this.canGoBack = canGoBack;
    if (canGoForward != null) this.canGoForward = canGoForward;
    notifyListeners();
  }

  void bumpBlocked() {
    blocked++;
    notifyListeners();
  }

  void resetBlocked() {
    blocked = 0;
    notifyListeners();
  }

  static String _hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }
}
