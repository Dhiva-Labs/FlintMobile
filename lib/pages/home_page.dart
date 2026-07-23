import 'package:flutter/material.dart';

import '../models/browser.dart';
import '../models/tab.dart';
import '../theme.dart';

/// The Flint new-tab screen: brand, speed-dial of top sites (with a real empty
/// state), and the privacy pitch. Search lives in the always-present address
/// bar above, so there's no second search box here.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.browser, required this.tab});
  final Browser browser;
  final BrowserTab tab;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final top = browser.store.topSites(limit: 8);
    return Container(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Brand(incognito: tab.incognito),
                      const SizedBox(height: 36),
                      if (top.isNotEmpty)
                        _SpeedDial(sites: top, browser: browser)
                      else
                        _EmptyDial(onSearch: () => browser.requestOmniEdit?.call()),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 22, left: 20, right: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: [
                  _Pill('Ad & tracker blocking', cs),
                  _Pill('Private tabs', cs),
                  _Pill('Reader mode', cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.incognito});
  final bool incognito;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _FlintMark(size: 42),
        const SizedBox(width: 12),
        Text.rich(TextSpan(children: [
          TextSpan(
            text: 'Flint',
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.5),
          ),
          const TextSpan(
              text: '.', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: flintOrange)),
        ])),
        if (incognito) ...[
          const SizedBox(width: 12),
          Icon(Icons.visibility_off, color: cs.onSurfaceVariant, size: 22),
        ],
      ],
    );
  }
}

class _EmptyDial extends StatelessWidget {
  const _EmptyDial({required this.onSearch});
  final VoidCallback onSearch;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.explore_outlined, size: 30, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(height: 12),
        Text(
          'Sites you visit most will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.5),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: onSearch,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Search the web'),
        ),
      ],
    );
  }
}

class _SpeedDial extends StatelessWidget {
  const _SpeedDial({required this.sites, required this.browser});
  final List<String> sites;
  final Browser browser;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 18,
      children: [for (final origin in sites) _DialTile(origin: origin, browser: browser)],
    );
  }
}

class _DialTile extends StatelessWidget {
  const _DialTile({required this.origin, required this.browser});
  final String origin;
  final Browser browser;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final host = Uri.tryParse(origin)?.host.replaceFirst('www.', '') ?? origin;
    final letter = host.isNotEmpty ? host[0].toUpperCase() : '?';
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Material(
            color: flintOrange,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => browser.navigate(origin),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Center(
                  child: Text(letter,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.cs);
  final String text;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check, size: 14, color: flintOrange),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
    ]);
  }
}

class _FlintMark extends StatelessWidget {
  const _FlintMark({this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _FlamePainter()));
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final p = Path()
      ..moveTo(s * 0.5, s * 0.08)
      ..cubicTo(s * 0.62, s * 0.28, s * 0.85, s * 0.4, s * 0.85, s * 0.62)
      ..cubicTo(s * 0.85, s * 0.82, s * 0.7, s * 0.94, s * 0.5, s * 0.94)
      ..cubicTo(s * 0.3, s * 0.94, s * 0.15, s * 0.82, s * 0.15, s * 0.62)
      ..cubicTo(s * 0.15, s * 0.5, s * 0.22, s * 0.42, s * 0.3, s * 0.34)
      ..cubicTo(s * 0.29, s * 0.46, s * 0.34, s * 0.53, s * 0.4, s * 0.56)
      ..cubicTo(s * 0.36, s * 0.4, s * 0.42, s * 0.22, s * 0.5, s * 0.08)
      ..close();
    canvas.drawPath(p, Paint()..color = flintOrange);
    final inner = Path()
      ..moveTo(s * 0.5, s * 0.42)
      ..cubicTo(s * 0.56, s * 0.54, s * 0.66, s * 0.6, s * 0.66, s * 0.72)
      ..cubicTo(s * 0.66, s * 0.82, s * 0.59, s * 0.88, s * 0.5, s * 0.88)
      ..cubicTo(s * 0.41, s * 0.88, s * 0.34, s * 0.82, s * 0.34, s * 0.72)
      ..cubicTo(s * 0.34, s * 0.65, s * 0.4, s * 0.58, s * 0.45, s * 0.52)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFFFD9A0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
