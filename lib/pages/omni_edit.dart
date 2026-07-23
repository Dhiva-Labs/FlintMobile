import 'package:flutter/material.dart';

import '../models/browser.dart';
import '../theme.dart';

/// Full-screen omnibox editor with history/bookmark suggestions.
/// Pops with the chosen URL or query string.
class OmniEditPage extends StatefulWidget {
  const OmniEditPage({super.key, required this.browser, required this.initial});
  final Browser browser;
  final String initial;

  @override
  State<OmniEditPage> createState() => _OmniEditPageState();
}

class _OmniEditPageState extends State<OmniEditPage> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.initial.startsWith('http') ? widget.initial : '');
  List<_Sug> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _update(_ctl.text);
  }

  void _update(String q) {
    final query = q.trim().toLowerCase();
    final out = <_Sug>[];
    final store = widget.browser.store;
    if (query.isNotEmpty) {
      for (final b in store.bookmarks) {
        if (b.url.toLowerCase().contains(query) || b.title.toLowerCase().contains(query)) {
          out.add(_Sug(b.title, b.url, Icons.star, true));
        }
        if (out.length >= 4) break;
      }
      for (final h in store.history) {
        if (out.length >= 8) break;
        if (h.url.toLowerCase().contains(query) || h.title.toLowerCase().contains(query)) {
          if (out.any((s) => s.url == h.url)) continue;
          out.add(_Sug(h.title, h.url, Icons.history, false));
        }
      }
    }
    setState(() => _suggestions = out);
  }

  void _submit(String value) => Navigator.of(context).pop(value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _ctl,
              autofocus: true,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search or enter address',
                border: InputBorder.none,
                suffixIcon: _ctl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _ctl.clear();
                          _update('');
                        }),
              ),
              onChanged: _update,
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _submit(v);
              },
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          for (final s in _suggestions)
            ListTile(
              leading: Icon(s.icon, color: s.bookmark ? flintOrange : cs.onSurfaceVariant, size: 20),
              title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(s.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.north_west, size: 18),
                onPressed: () {
                  _ctl.text = s.url;
                  _update(s.url);
                },
              ),
              onTap: () => _submit(s.url),
            ),
        ],
      ),
    );
  }
}

class _Sug {
  _Sug(this.title, this.url, this.icon, this.bookmark);
  final String title;
  final String url;
  final IconData icon;
  final bool bookmark;
}
