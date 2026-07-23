import 'package:flutter/material.dart';

import '../models/browser.dart';
import '../models/tab.dart';
import '../theme.dart';

/// The Flint new-tab screen: brand, search box, speed-dial of top sites,
/// and the privacy pitch.
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _FlintMark(size: 40),
              const SizedBox(width: 10),
              Text.rich(TextSpan(children: [
                TextSpan(
                  text: 'Flint',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const TextSpan(
                  text: '.',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: flintOrange),
                ),
              ])),
              if (tab.incognito) ...[
                const SizedBox(width: 10),
                Icon(Icons.visibility_off, color: cs.onSurfaceVariant, size: 22),
              ],
            ],
          ),
          const SizedBox(height: 28),
          Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => browser.requestOmniEdit?.call(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(children: [
                  Icon(Icons.search, color: cs.onSurfaceVariant, size: 22),
                  const SizedBox(width: 12),
                  Text('Search or enter address',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15.5)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 34),
          if (top.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final origin in top) _SpeedDialTile(origin: origin, browser: browser),
              ],
            ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              _Pill('Ad & tracker blocking', cs),
              _Pill('Private tabs', cs),
              _Pill('Reader mode', cs),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedDialTile extends StatelessWidget {
  const _SpeedDialTile({required this.origin, required this.browser});
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlamePainter()),
    );
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
