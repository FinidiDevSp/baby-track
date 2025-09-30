import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Skeleton',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      routerConfig: null, // TODO: implement go_router
    );
  }
}
