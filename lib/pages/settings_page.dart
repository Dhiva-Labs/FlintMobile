import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../main.dart';
import '../models/browser.dart';
import '../services/store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.browser});
  final Browser browser;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Store get store => widget.browser.store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _header('General'),
          _card([
            ListTile(
              title: const Text('Search engine'),
              trailing: DropdownButton<String>(
                value: store.searchEngine,
                underline: const SizedBox(),
                onChanged: (v) => setState(() => store.searchEngine = v!),
                items: [
                  for (final e in kEngines) DropdownMenuItem(value: e.id, child: Text(e.name)),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Theme'),
              trailing: DropdownButton<String>(
                value: store.theme,
                underline: const SizedBox(),
                onChanged: (v) {
                  setState(() => store.theme = v!);
                  FlintApp.of(context).refreshTheme();
                },
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('System')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                ],
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Desktop site by default'),
              value: store.desktopMode,
              onChanged: (v) => setState(() => store.desktopMode = v),
            ),
          ]),
          _header('Privacy'),
          _card([
            SwitchListTile(
              title: const Text('Block ads & trackers'),
              subtitle: Text(
                  '${_fmt(widget.browser.adblock.size)} domains · ${_fmt(store.blockedTotal)} blocked all-time'),
              value: store.adblockEnabled,
              onChanged: (v) => setState(() => store.adblockEnabled = v),
            ),
            if (store.adblockAllowlist.isNotEmpty) ...[
              const Divider(height: 1),
              ListTile(
                title: const Text('Sites where blocking is off'),
                subtitle: Text(store.adblockAllowlist.join(', ')),
                trailing: TextButton(
                  onPressed: () => setState(() => store.adblockAllowlist = []),
                  child: const Text('Clear'),
                ),
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear browsing data'),
              subtitle: const Text('History, cookies and cache'),
              onTap: _clearData,
            ),
          ]),
          _header('About'),
          _card([
            const ListTile(
              title: Text('Flint'),
              subtitle: Text('Fast, private mobile browser by Dhiva Labs · v1.0.0'),
            ),
            const Divider(height: 1),
            const ListTile(
              title: Text('Privacy'),
              subtitle: Text(
                  'Flint sends nothing about you anywhere. History and bookmarks stay on this device.'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 16, 8),
        child: Text(text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.primary,
            )),
      );

  Widget _card(List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  /// Group digits with thousands separators, e.g. 89235 -> "89,235".
  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _clearData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear browsing data?'),
        content: const Text('This clears history, cookies and cache.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;
    store.clearHistory();
    try {
      await CookieManager.instance().deleteAllCookies();
      await InAppWebViewController.clearAllCache();
    } catch (_) {}
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Browsing data cleared')));
    }
  }
}
