import 'package:flutter/material.dart';

import '../models/browser.dart';
import '../theme.dart';

/// Grid of open tabs with close buttons and new-tab actions.
class TabSwitcherPage extends StatefulWidget {
  const TabSwitcherPage({super.key, required this.browser});
  final Browser browser;

  @override
  State<TabSwitcherPage> createState() => _TabSwitcherPageState();
}

class _TabSwitcherPageState extends State<TabSwitcherPage> {
  Browser get b => widget.browser;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('${b.tabs.length} ${b.tabs.length == 1 ? "tab" : "tabs"}'),
        actions: [
          IconButton(
            tooltip: 'New private tab',
            icon: const Icon(Icons.visibility_off_outlined),
            onPressed: () {
              b.newTab(incognito: true);
              Navigator.pop(context);
              b.requestOmniEdit?.call();
            },
          ),
          IconButton(
            tooltip: 'New tab',
            icon: const Icon(Icons.add),
            onPressed: () {
              b.newTab();
              Navigator.pop(context);
              b.requestOmniEdit?.call();
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: b.tabs.length,
        itemBuilder: (context, i) {
          final tab = b.tabs[i];
          final active = i == b.activeIndex;
          return GestureDetector(
            onTap: () {
              b.selectTab(i);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: tab.incognito ? cs.surfaceContainerHigh : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? flintOrange : cs.outlineVariant.withValues(alpha: 0.4),
                  width: active ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
                    child: Row(
                      children: [
                        Icon(tab.incognito ? Icons.visibility_off : Icons.public,
                            size: 15, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.isHome ? 'New Tab' : tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => b.closeTab(tab)),
                          child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tab.isHome
                            ? '🔥'
                            : (tab.host.isNotEmpty ? tab.host[0].toUpperCase() : '?'),
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
