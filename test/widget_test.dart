import 'package:flutter_test/flutter_test.dart';
import 'package:flint/models/omni.dart';
import 'package:flint/services/store.dart';

void main() {
  const engine = SearchEngine('ddg', 'DuckDuckGo', 'https://duckduckgo.com/?q=%s');

  group('resolveInput', () {
    test('bare domain becomes https url', () {
      expect(resolveInput('example.com', engine), 'https://example.com');
    });
    test('domain with path is a url', () {
      expect(resolveInput('example.com/path', engine), 'https://example.com/path');
    });
    test('plain words become a search', () {
      expect(resolveInput('hello world', engine),
          'https://duckduckgo.com/?q=hello%20world');
    });
    test('single word without a dot is a search', () {
      expect(resolveInput('intranet', engine), 'https://duckduckgo.com/?q=intranet');
    });
    test('explicit https url passes through', () {
      expect(resolveInput('https://x.com/a?b=c', engine), 'https://x.com/a?b=c');
    });
    test('localhost with port is http', () {
      expect(resolveInput('localhost:8080', engine), 'http://localhost:8080');
    });
    test('IPv4 is http', () {
      expect(resolveInput('192.168.0.1', engine), 'http://192.168.0.1');
    });
    test('empty input yields empty', () {
      expect(resolveInput('   ', engine), '');
    });
  });
}
