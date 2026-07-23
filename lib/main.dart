import 'package:flutter/material.dart';

import 'models/browser.dart';
import 'pages/browser_shell.dart';
import 'services/adblock.dart';
import 'services/store.dart';
import 'services/vpn.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  final adblock = AdBlock();
  await adblock.load();
  final vpn = Vpn(store);
  await vpn.init();
  runApp(FlintApp(store: store, adblock: adblock, vpn: vpn));
}

class FlintApp extends StatefulWidget {
  const FlintApp({super.key, required this.store, required this.adblock, required this.vpn});
  final Store store;
  final AdBlock adblock;
  final Vpn vpn;

  static FlintAppState of(BuildContext context) =>
      context.findAncestorStateOfType<FlintAppState>()!;

  @override
  State<FlintApp> createState() => FlintAppState();
}

class FlintAppState extends State<FlintApp> {
  late final Browser browser = Browser(widget.store, widget.adblock, widget.vpn)..init();

  void refreshTheme() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flint',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeModeFrom(widget.store.theme),
      home: BrowserShell(browser: browser),
    );
  }
}
