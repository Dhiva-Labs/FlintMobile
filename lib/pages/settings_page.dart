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
        children: [
          _header('General'),
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
          SwitchListTile(
            title: const Text('Desktop site by default'),
            value: store.desktopMode,
            onChanged: (v) => setState(() => store.desktopMode = v),
          ),
          _header('Privacy'),
          SwitchListTile(
            title: const Text('Block ads & trackers'),
            subtitle: Text(
                '${widget.browser.adblock.size} domains · ${store.blockedTotal} blocked all-time'),
            value: store.adblockEnabled,
            onChanged: (v) => setState(() => store.adblockEnabled = v),
          ),
          if (store.adblockAllowlist.isNotEmpty)
            ListTile(
              title: const Text('Sites where blocking is off'),
              subtitle: Text(store.adblockAllowlist.join(', ')),
              trailing: TextButton(
                onPressed: () => setState(() => store.adblockAllowlist = []),
                child: const Text('Clear'),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear browsing data'),
            subtitle: const Text('History, cookies and cache'),
            onTap: _clearData,
          ),
          _header('About'),
          const ListTile(
            title: Text('Flint'),
            subtitle: Text('Fast, private mobile browser by Dhiva Labs · v1.0.0'),
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text(
                'Flint sends nothing about you anywhere. History and bookmarks stay on this device.'),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.primary,
            )),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Browsing data cleared')));
    }
  }
}
