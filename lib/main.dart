import 'package:flutter/material.dart';

import 'printer_test_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Printer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PrinterTestScreen(),
    );
  }
}
