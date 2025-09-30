import 'package:flutter/widgets.dart';

Future<void> bootstrap(Future<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    // TODO: add logger here
  };
  runApp(await builder());
}
