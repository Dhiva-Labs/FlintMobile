import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/browser.dart';
import '../theme.dart';
import 'library_page.dart';
import 'omni_edit.dart';
import 'reader_page.dart';
import 'settings_page.dart';
import 'tab_switcher.dart';
import 'web_tab.dart';

class BrowserShell extends StatefulWidget {
  const BrowserShell({super.key, required this.browser});
  final Browser browser;

  @override
  State<BrowserShell> createState() => _BrowserShellState();
}

class _BrowserShellState extends State<BrowserShell> {
  Browser get b => widget.browser;
  bool _finding = false;
  final _findCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    b.requestOmniEdit = _openOmni;
    b.onDownloadStarted = (name) {
      if (!mounted) return;
      _snack('Downloading $name');
    };
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openOmni() async {
    final result = await Navigator.of(context).push<String>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OmniEditPage(browser: b, initial: b.active.url),
    ));
    if (result != null && result.isNotEmpty) b.navigate(result);
  }

  Future<void> _openReader() async {
    final tab = b.active;
    if (tab.controller == null || tab.isHome) return;
    final article = await extractArticle(tab.controller!);
    if (!mounted) return;
    if (article == null) {
      _snack('Reader view is not available for this page');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderPage(article: article),
    ));
  }

  void _openMenu() {
    final tab = b.active;
    final bookmarked = tab.url.startsWith('http') && b.store.isBookmarked(tab.url);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(children: [
            _MenuIcon(bookmarked ? Icons.star : Icons.star_border, bookmarked ? 'Saved' : 'Bookmark',
                () {
              Navigator.pop(ctx);
              b.toggleBookmark();
              _snack(b.store.isBookmarked(tab.url) ? 'Bookmark added' : 'Bookmark removed');
            }, active: bookmarked),
            _MenuIcon(Icons.article_outlined, 'Reader', () {
              Navigator.pop(ctx);
              _openReader();
            }),
            _MenuIcon(Icons.search, 'Find', () {
              Navigator.pop(ctx);
              setState(() => _finding = true);
            }),
            _MenuIcon(Icons.share_outlined, 'Share', () {
              Navigator.pop(ctx);
              if (tab.url.startsWith('http')) Share.share(tab.url);
            }),
          ]),
          const Divider(height: 8),
          _MenuRow(Icons.add, 'New tab', () {
            Navigator.pop(ctx);
            b.newTab();
            _openOmni();
          }),
          _MenuRow(Icons.visibility_off_outlined, 'New private tab', () {
            Navigator.pop(ctx);
            b.newTab(incognito: true);
            _openOmni();
          }),
          _MenuRow(Icons.star_border, 'Bookmarks', () {
            Navigator.pop(ctx);
            _openLibrary(0);
          }),
          _MenuRow(Icons.history, 'History', () {
            Navigator.pop(ctx);
            _openLibrary(1);
          }),
          _MenuRow(Icons.download_outlined, 'Downloads', () {
            Navigator.pop(ctx);
            _openLibrary(2);
          }),
          _MenuRow(
            b.store.desktopMode ? Icons.smartphone : Icons.desktop_windows,
            b.store.desktopMode ? 'Mobile site' : 'Desktop site',
            () {
              Navigator.pop(ctx);
              b.store.desktopMode = !b.store.desktopMode;
              b.active.controller?.reload();
              setState(() {});
            },
          ),
          _MenuRow(Icons.settings_outlined, 'Settings', () {
            Navigator.pop(ctx);
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => SettingsPage(browser: b)))
                .then((_) => setState(() {}));
          }),
        ]),
      ),
    );
  }

  void _openLibrary(int tab) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LibraryPage(browser: b, initialTab: tab)))
        .then((_) => setState(() {}));
  }

  Future<void> _openTabs() async {
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TabSwitcherPage(browser: b),
    ));
    setState(() {});
  }

  Future<bool> _handleBack() async {
    final tab = b.active;
    if (tab.controller != null && tab.canGoBack) {
      await b.goBack();
      return false;
    }
    if (b.tabs.length > 1) {
      b.closeTab(tab);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: b,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final allow = await _handleBack();
            if (allow && context.mounted) Navigator.of(context).maybePop();
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _Omnibar(browser: b, onEdit: _openOmni, onMenu: _openMenu),
                  Expanded(
                    child: IndexedStack(
                      index: b.activeIndex,
                      children: [
                        for (final t in b.tabs) WebTab(key: ValueKey(t.id), browser: b, tab: t),
                      ],
                    ),
                  ),
                  if (_finding) _FindBar(browser: b, controller: _findCtl, onClose: () {
                    b.active.controller?.clearMatches();
                    setState(() => _finding = false);
                  }),
                  _BottomBar(
                    browser: b,
                    onTabs: _openTabs,
                    onMenu: _openMenu,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Omnibar extends StatelessWidget {
  const _Omnibar({required this.browser, required this.onEdit, required this.onMenu});
  final Browser browser;
  final VoidCallback onEdit;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tab = browser.active;
    final secure = tab.url.startsWith('https');
    final blocking =
        browser.store.adblockEnabled && !browser.store.isAllowlisted(tab.host) && tab.host.isNotEmpty;
    return AnimatedBuilder(
      animation: tab,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Column(
            children: [
              Row(children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Material(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: onEdit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Icon(
                            tab.incognito
                                ? Icons.visibility_off
                                : secure
                                    ? Icons.lock
                                    : tab.isHome
                                        ? Icons.search
                                        : Icons.info_outline,
                            size: 17,
                            color: secure ? Colors.green : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tab.isHome
                                  ? 'Search or enter address'
                                  : (tab.host.isEmpty ? tab.url : tab.host),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: tab.isHome ? cs.onSurfaceVariant : cs.onSurface,
                              ),
                            ),
                          ),
                          if (!tab.isHome)
                            GestureDetector(
                              onTap: () => browser.reloadOrStop(),
                              child: Icon(tab.isLoading ? Icons.close : Icons.refresh,
                                  size: 19, color: cs.onSurfaceVariant),
                            ),
                        ]),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _shieldSheet(context),
                  icon: Badge(
                    isLabelVisible: tab.blocked > 0,
                    label: Text('${tab.blocked}'),
                    backgroundColor: flintOrange,
                    child: Icon(Icons.shield_outlined,
                        color: blocking ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
              ]),
              if (tab.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    value: tab.progress == 0 ? null : tab.progress,
                    minHeight: 2.5,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _shieldSheet(BuildContext context) {
    final tab = browser.active;
    final allow = browser.store.isAllowlisted(tab.host);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: flintOrange),
            title: Text('${tab.blocked} blocked on this page'),
            subtitle: Text('${browser.store.blockedTotal} blocked all-time'),
          ),
          if (tab.host.isNotEmpty)
            SwitchListTile(
              secondary: const Icon(Icons.tune),
              title: const Text('Block ads & trackers here'),
              subtitle: Text(tab.host),
              value: !allow,
              onChanged: (_) {
                Navigator.pop(ctx);
                browser.toggleSiteBlocking();
              },
            ),
        ]),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.browser, required this.onTabs, required this.onMenu});
  final Browser browser;
  final VoidCallback onTabs;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tab = browser.active;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: tab.canGoBack ? browser.goBack : null,
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              onPressed: tab.canGoForward ? browser.goForward : null,
              icon: const Icon(Icons.arrow_forward),
            ),
            IconButton(
              onPressed: () {
                browser.newTab();
                browser.requestOmniEdit?.call();
              },
              icon: const Icon(Icons.add),
            ),
            InkWell(
              onTap: onTabs,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.onSurface, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${browser.tabs.length}',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ),
              ),
            ),
            IconButton(onPressed: onMenu, icon: const Icon(Icons.more_vert)),
          ],
        ),
      ),
    );
  }
}

class _FindBar extends StatelessWidget {
  const _FindBar({required this.browser, required this.controller, required this.onClose});
  final Browser browser;
  final TextEditingController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Find in page', border: InputBorder.none),
            onChanged: (v) => browser.active.controller?.findAllAsync(find: v),
            onSubmitted: (_) => browser.active.controller?.findNext(forward: true),
          ),
        ),
        IconButton(
            onPressed: () => browser.active.controller?.findNext(forward: false),
            icon: const Icon(Icons.keyboard_arrow_up)),
        IconButton(
            onPressed: () => browser.active.controller?.findNext(forward: true),
            icon: const Icon(Icons.keyboard_arrow_down)),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ]),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon(this.icon, this.label, this.onTap, {this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 84,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Icon(icon, color: active ? flintOrange : cs.onSurface),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
