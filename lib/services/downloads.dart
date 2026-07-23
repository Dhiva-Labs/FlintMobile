import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DownloadItem {
  DownloadItem(this.url, this.filename);
  final String url;
  String filename;
  String? path;
  int received = 0;
  int total = 0;
  String state = 'running'; // running | done | failed
  double get progress => total > 0 ? received / total : 0;
}

/// Minimal download manager: streams files to the app's external files
/// directory (no storage permission needed) and tracks progress.
class Downloads extends ChangeNotifier {
  final List<DownloadItem> items = [];
  final _client = HttpClient();

  Future<Directory> _dir() async {
    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/Downloads');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _safeName(String name) {
    var n = name.replaceAll(RegExp(r'[/\\<>:"|?*\x00-\x1f]'), '_').trim();
    if (n.isEmpty) n = 'download';
    return n;
  }

  Future<DownloadItem> start(String url, String? suggested) async {
    var name = _safeName(suggested ?? Uri.parse(url).pathSegments.lastOrNull ?? 'download');
    final item = DownloadItem(url, name);
    items.insert(0, item);
    notifyListeners();
    _run(item);
    return item;
  }

  Future<void> _run(DownloadItem item) async {
    try {
      final dir = await _dir();
      var file = File('${dir.path}/${item.filename}');
      var i = 1;
      while (file.existsSync()) {
        final dot = item.filename.lastIndexOf('.');
        final base = dot > 0 ? item.filename.substring(0, dot) : item.filename;
        final ext = dot > 0 ? item.filename.substring(dot) : '';
        file = File('${dir.path}/$base ($i)$ext');
        i++;
      }
      item.path = file.path;

      final req = await _client.getUrl(Uri.parse(item.url));
      final resp = await req.close();
      item.total = resp.contentLength;
      final sink = file.openWrite();
      var lastNotify = DateTime.now();
      await for (final chunk in resp) {
        sink.add(chunk);
        item.received += chunk.length;
        if (DateTime.now().difference(lastNotify).inMilliseconds > 200) {
          lastNotify = DateTime.now();
          notifyListeners();
        }
      }
      await sink.close();
      item.state = 'done';
    } catch (_) {
      item.state = 'failed';
    }
    notifyListeners();
  }
}
