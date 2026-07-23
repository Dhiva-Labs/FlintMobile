import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReaderArticle {
  ReaderArticle(this.title, this.byline, this.site, this.content, this.url);
  final String title;
  final String byline;
  final String site;
  final String content; // sanitized HTML from Readability
  final String url;
}

/// Extract the main article from the current page using Mozilla Readability.
Future<ReaderArticle?> extractArticle(InAppWebViewController c) async {
  final lib = await rootBundle.loadString('assets/reader/Readability.js');
  final js = '''
(function(){
  try {
    $lib
    var clone = document.cloneNode(true);
    var a = new Readability(clone).parse();
    if (!a || !a.content) return null;
    return {
      title: a.title || document.title || '',
      byline: a.byline || '',
      site: a.siteName || location.hostname,
      content: a.content,
      url: location.href
    };
  } catch (e) { return null; }
})()
''';
  final res = await c.evaluateJavascript(source: js);
  if (res is! Map || res['content'] == null) return null;
  return ReaderArticle(
    (res['title'] ?? '') as String,
    (res['byline'] ?? '') as String,
    (res['site'] ?? '') as String,
    res['content'] as String,
    (res['url'] ?? '') as String,
  );
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.article});
  final ReaderArticle article;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  double _fontSize = 18;
  bool _sepia = false;

  String _buildHtml() {
    final a = widget.article;
    final dark = Theme.of(context).brightness == Brightness.dark && !_sepia;
    final bg = _sepia ? '#f4ecd8' : (dark ? '#17191d' : '#ffffff');
    final fg = _sepia ? '#433422' : (dark ? '#e8eaed' : '#1c1e21');
    final dim = _sepia ? '#7a6a52' : (dark ? '#9aa1ac' : '#61687a');
    return '''
<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src http: https: data:; style-src 'unsafe-inline';">
<style>
  body{margin:0;padding:24px 20px 80px;background:$bg;color:$fg;
       font:${_fontSize}px/1.75 -apple-system,Roboto,system-ui,sans-serif;}
  h1{font-size:1.5em;line-height:1.25;margin:0 0 6px}
  .meta{color:$dim;font-size:.8em;margin-bottom:26px}
  img{max-width:100%;height:auto;border-radius:8px}
  a{color:#e8702a}
  pre{overflow-x:auto;background:rgba(128,128,128,.15);padding:12px;border-radius:8px;font-size:.85em}
  blockquote{border-left:3px solid #e8702a;margin:0 0 1em;padding-left:16px;color:$dim}
</style></head>
<body>
  <h1>${_escape(a.title)}</h1>
  <div class="meta">${_escape([a.site, a.byline].where((s) => s.isNotEmpty).join(' · '))}</div>
  ${a.content}
</body></html>
''';
  }

  String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        actions: [
          IconButton(
              icon: const Icon(Icons.text_decrease),
              onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(13, 26))),
          IconButton(
              icon: const Icon(Icons.text_increase),
              onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(13, 26))),
          IconButton(
              icon: Icon(_sepia ? Icons.wb_sunny : Icons.wb_sunny_outlined),
              onPressed: () => setState(() => _sepia = !_sepia)),
        ],
      ),
      body: InAppWebView(
        key: ValueKey('reader-${_fontSize}_$_sepia'),
        initialData: InAppWebViewInitialData(data: _buildHtml(), baseUrl: WebUri(widget.article.url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: false,
          transparentBackground: true,
        ),
      ),
    );
  }
}
