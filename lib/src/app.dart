import 'package:flutter/material.dart';
import 'package:tigerface_flutter_app/src/screens/home.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '타이거 페이스',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
