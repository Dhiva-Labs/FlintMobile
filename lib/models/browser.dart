import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/adblock.dart';
import '../services/downloads.dart';
import '../services/store.dart';
import 'omni.dart';
import 'tab.dart';

/// Top-level browser state: the tab list, the active tab, and navigation ops.
class Browser extends ChangeNotifier {
  Browser(this.store, this.adblock);

  final Store store;
  final AdBlock adblock;
  final Downloads downloads = Downloads();

  /// UI hook so the shell can show a snackbar when a download starts.
  void Function(String filename)? onDownloadStarted;

  /// UI hook so the home screen's search box can open the omnibox editor.
  void Function()? requestOmniEdit;

  void onDownload(String url, String? filename) {
    downloads.start(url, filename);
    onDownloadStarted?.call(filename ?? 'file');
  }

  final List<BrowserTab> tabs = [];
  int activeIndex = 0;
  int _nextId = 1;

  BrowserTab get active => tabs[activeIndex];
  bool get hasTabs => tabs.isNotEmpty;

  void init() {
    if (tabs.isEmpty) newTab();
  }

  BrowserTab newTab({String url = '', bool incognito = false, bool select = true}) {
    final tab = BrowserTab(id: _nextId++, initialUrl: url, incognito: incognito);
    if (url.isNotEmpty) {
      tab.url = url;
      tab.host = hostOf(url);
    }
    tabs.add(tab);
    if (select) activeIndex = tabs.length - 1;
    notifyListeners();
    return tab;
  }

  void selectTab(int index) {
    if (index < 0 || index >= tabs.length) return;
    activeIndex = index;
    notifyListeners();
  }

  void closeTab(BrowserTab tab) {
    final idx = tabs.indexOf(tab);
    if (idx < 0) return;
    tabs.removeAt(idx);
    tab.dispose();
    if (tabs.isEmpty) {
      newTab();
      return;
    }
    if (activeIndex >= tabs.length) activeIndex = tabs.length - 1;
    notifyListeners();
  }

  int get incognitoCount => tabs.where((t) => t.incognito).length;

  // ---- navigation on the active tab ----

  void navigate(String input) {
    final url = resolveInput(input, store.engine);
    if (url.isEmpty) return;
    final tab = active;
    tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    // If we're on the home screen with no controller yet, seed the url so the
    // web view is created pointing at the target.
    if (tab.controller == null) {
      tab.update(url: url);
    }
  }

  void openInNewTab(String url, {bool background = false}) {
    newTab(url: url, incognito: active.incognito, select: !background);
  }

  void goHome() {
    final t = active;
    t.controller = null;
    t.blocked = 0;
    t.update(url: '', title: 'New Tab', isLoading: false, progress: 0);
  }

  Future<void> reloadOrStop() async {
    final t = active;
    if (t.isLoading) {
      await t.controller?.stopLoading();
    } else {
      await t.controller?.reload();
    }
  }

  Future<void> goBack() async => active.controller?.goBack();
  Future<void> goForward() async => active.controller?.goForward();

  void toggleBookmark() {
    final t = active;
    if (!t.url.startsWith('http')) return;
    store.toggleBookmark(t.url, t.title);
    notifyListeners();
  }

  /// Called from each tab's shouldInterceptRequest. Returns true to block.
  bool shouldBlock(BrowserTab tab, String requestUrl) {
    if (!store.adblockEnabled || !adblock.ready) return false;
    if (store.isAllowlisted(tab.host)) return false;
    final host = hostOf(requestUrl);
    if (host.isEmpty || host == tab.host) return false; // never block same-origin
    if (adblock.blocks(host)) {
      tab.bumpBlocked();
      store.blockedTotal = store.blockedTotal + 1;
      return true;
    }
    return false;
  }

  void toggleSiteBlocking() {
    final host = active.host;
    if (host.isEmpty) return;
    store.toggleAllowlist(host);
    active.controller?.reload();
    notifyListeners();
  }

  void refreshChrome() => notifyListeners();
}
