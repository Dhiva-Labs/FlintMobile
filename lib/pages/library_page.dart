import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/browser.dart';
import '../services/downloads.dart';

/// Bookmarks / History / Downloads in one tabbed page.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.browser, this.initialTab = 0});
  final Browser browser;
  final int initialTab;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late final TabController _tc =
      TabController(length: 3, vsync: this, initialIndex: widget.initialTab);

  Browser get b => widget.browser;

  void _open(String url) {
    b.newTab(url: url);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tc,
          tabs: const [
            Tab(text: 'Bookmarks'),
            Tab(text: 'History'),
            Tab(text: 'Downloads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [_bookmarks(), _history(), _downloads()],
      ),
    );
  }

  Widget _empty(String text) => Center(
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _bookmarks() {
    final items = b.store.bookmarks;
    if (items.isEmpty) return _empty('No bookmarks yet');
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final bm = items[i];
        return ListTile(
          leading: _favTile(bm.url),
          title: Text(bm.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(bm.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => b.store.removeBookmark(bm.url)),
          ),
          onTap: () => _open(bm.url),
        );
      },
    );
  }

  Widget _history() {
    final items = b.store.history;
    if (items.isEmpty) return _empty('No history');
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => b.store.clearHistory()),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Clear all'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final h = items[i];
              return ListTile(
                leading: _favTile(h.url),
                title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(h.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => b.store.removeHistory(h.url)),
                ),
                onTap: () => _open(h.url),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _downloads() {
    return AnimatedBuilder(
      animation: b.downloads,
      builder: (context, _) {
        final items = b.downloads.items;
        if (items.isEmpty) return _empty('No downloads yet');
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final d = items[i];
            return ListTile(
              leading: Icon(switch (d.state) {
                'done' => Icons.check_circle_outline,
                'failed' => Icons.error_outline,
                _ => Icons.downloading,
              }),
              title: Text(d.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: _subtitle(d),
              trailing: d.state == 'done' && d.path != null
                  ? IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => Share.shareXFiles([XFile(d.path!)]),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _subtitle(DownloadItem d) {
    if (d.state == 'running') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_fmt(d.received)}${d.total > 0 ? ' / ${_fmt(d.total)}' : ''}'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: d.total > 0 ? d.progress : null, minHeight: 3),
        ],
      );
    }
    return Text(d.state == 'done' ? _fmt(d.received) : 'Failed');
  }

  Widget _favTile(String url) {
    final host = Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? '?';
    final letter = host.isNotEmpty ? host[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  String _fmt(int n) {
    const u = ['B', 'KB', 'MB', 'GB'];
    var v = n.toDouble();
    var i = 0;
    while (v >= 1024 && i < u.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v < 10 && i > 0 ? v.toStringAsFixed(1) : v.round()} ${u[i]}';
  }
}
