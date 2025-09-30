import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(Future<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    // TODO: add logger here
  };
  runApp(ProviderScope(child: await builder()));
}
