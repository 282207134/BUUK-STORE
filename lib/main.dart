import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/catalog.dart';
import 'src/store_state.dart';
import 'src/ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const BuukStore());
}

class BuukStore extends StatefulWidget {
  const BuukStore({super.key});

  @override
  State<BuukStore> createState() => _BuukStoreState();
}

class _BuukStoreState extends State<BuukStore> {
  final store = StoreState();

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreScope(
    notifier: store,
    child: MaterialApp(
      title: 'BUUK Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.blue),
        scaffoldBackgroundColor: Palette.paper,
        fontFamily: 'Roboto',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Palette.ink,
          displayColor: Palette.ink,
        ),
      ),
      home: const StoreHome(),
    ),
  );
}
