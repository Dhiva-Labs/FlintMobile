import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/browser.dart';
import '../models/tab.dart';
import 'home_page.dart';

const _desktopUA =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

/// Renders one tab: the Flint home screen when the tab has no URL yet,
/// otherwise an InAppWebView wired to blocking, history and downloads.
class WebTab extends StatefulWidget {
  const WebTab({super.key, required this.browser, required this.tab});
  final Browser browser;
  final BrowserTab tab;

  @override
  State<WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<WebTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  BrowserTab get tab => widget.tab;
  Browser get browser => widget.browser;

  bool _wasHome = true;

  @override
  void initState() {
    super.initState();
    // Capture the initial home state eagerly (a `late` field would initialize
    // lazily inside the listener, after the URL already changed, and miss the
    // very transition we watch for). Rebuild only when the tab crosses the
    // home <-> page boundary; progress and title updates are consumed by the
    // omnibar, so the native web view is never rebuilt mid-load.
    _wasHome = tab.isHome;
    tab.addListener(_onTab);
  }

  @override
  void dispose() {
    tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (tab.isHome != _wasHome && mounted) {
      setState(() => _wasHome = tab.isHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (tab.isHome) {
      return HomePage(browser: browser, tab: tab);
    }
    return InAppWebView(
      key: ValueKey('webview-${tab.id}'),
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: InAppWebViewSettings(
        useShouldInterceptRequest: true,
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,
        javaScriptEnabled: true,
        incognito: tab.incognito,
        transparentBackground: true,
        mediaPlaybackRequiresUserGesture: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        useHybridComposition: true,
        allowsInlineMediaPlayback: true,
        preferredContentMode: browser.store.desktopMode
            ? UserPreferredContentMode.DESKTOP
            : UserPreferredContentMode.RECOMMENDED,
        userAgent: browser.store.desktopMode ? _desktopUA : '',
      ),
      onWebViewCreated: (c) => tab.controller = c,
      onLoadStart: (c, url) {
        tab.resetBlocked();
        tab.update(url: url?.toString(), isLoading: true, progress: 0);
      },
      onLoadStop: (c, url) async {
        tab.update(url: url?.toString(), isLoading: false, progress: 1);
        final t = await c.getTitle();
        if (t != null && t.isNotEmpty) tab.update(title: t);
        if (!tab.incognito) {
          browser.store.recordHistory(url?.toString() ?? '', t ?? '');
        }
        await _syncNav(c);
        browser.refreshChrome();
      },
      onProgressChanged: (c, p) => tab.update(progress: p / 100.0, isLoading: p < 100),
      onTitleChanged: (c, t) {
        if (t != null && t.isNotEmpty) tab.update(title: t);
      },
      onUpdateVisitedHistory: (c, url, isReload) async {
        tab.update(url: url?.toString());
        await _syncNav(c);
        browser.refreshChrome();
      },
      shouldInterceptRequest: (c, request) async {
        if (browser.shouldBlock(tab, request.url.toString())) {
          return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
        }
        return null;
      },
      shouldOverrideUrlLoading: (c, action) async {
        final uri = action.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;
        const web = {'http', 'https', 'about', 'data', 'blob', 'javascript'};
        if (!web.contains(uri.scheme)) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onDownloadStartRequest: (c, req) =>
          browser.onDownload(req.url.toString(), req.suggestedFilename),
      onReceivedError: (c, req, err) {
        if (req.isForMainFrame ?? false) tab.update(isLoading: false, progress: 1);
      },
      onCreateWindow: (c, req) async {
        final u = req.request.url;
        if (u != null) browser.openInNewTab(u.toString());
        return false;
      },
    );
  }

  Future<void> _syncNav(InAppWebViewController c) async {
    final back = await c.canGoBack();
    final fwd = await c.canGoForward();
    tab.update(canGoBack: back, canGoForward: fwd);
  }
}
