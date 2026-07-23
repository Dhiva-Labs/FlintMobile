import 'package:flutter/material.dart';

import '../services/vpn.dart';
import '../theme.dart';

/// Opera-style browser-VPN screen: a big connect toggle, a list of exit servers
/// the user has added, and an honest explanation of what it does.
class VpnPage extends StatefulWidget {
  const VpnPage({super.key, required this.vpn});
  final Vpn vpn;

  @override
  State<VpnPage> createState() => _VpnPageState();
}

class _VpnPageState extends State<VpnPage> {
  Vpn get vpn => widget.vpn;

  Future<void> _toggle(bool on) async {
    if (on && vpn.servers.isEmpty) {
      _addServerDialog();
      return;
    }
    final ok = await vpn.toggle(on);
    if (!ok && mounted && vpn.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vpn.lastError!)));
    }
    setState(() {});
  }

  void _addServerDialog() {
    final label = TextEditingController();
    final url = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add proxy server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Name (e.g. My VPS – Germany)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: url,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'https://host:8080  or  socks5://host:1080',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a server you control or one from a VPN/proxy provider. '
              'Flint routes the browser through it — it runs no servers itself.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (url.text.trim().isEmpty) return;
              vpn.addServer(label.text, url.text);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final on = vpn.isOn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure proxy (VPN)'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addServerDialog),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _toggle(!vpn.enabled),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? flintOrange : cs.surfaceContainerHighest,
                      boxShadow: on
                          ? [BoxShadow(color: flintOrange.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 4)]
                          : null,
                    ),
                    child: Icon(
                      on ? Icons.shield : Icons.shield_outlined,
                      size: 64,
                      color: on ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  on ? 'Connected' : 'Not connected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (on)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('via ${vpn.current!.label}',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                if (!vpn.supported)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Not supported on this device\'s WebView',
                        style: TextStyle(color: cs.error)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('SERVERS',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: cs.primary)),
          const SizedBox(height: 4),
          if (vpn.servers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(children: [
                Text('No servers yet', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _addServerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add a server'),
                ),
              ]),
            )
          else
            for (int i = 0; i < vpn.servers.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: vpn.active,
                onChanged: (v) {
                  vpn.select(v!);
                  setState(() {});
                },
                title: Text(vpn.servers[i].label),
                subtitle: Text(vpn.servers[i].url, maxLines: 1, overflow: TextOverflow.ellipsis),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    vpn.removeServer(i);
                    setState(() {});
                  },
                ),
              ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'This routes Flint\'s browsing traffic through the server you choose — '
              'like Opera\'s built-in VPN, but the exit server is yours or your '
              'provider\'s, so no Dhiva Labs server ever sees your traffic and '
              'nothing is logged. It secures the browser only, not other apps. '
              'For a device-wide tunnel, use a dedicated WireGuard app.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
