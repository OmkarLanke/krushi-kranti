import 'package:flutter/material.dart';
import 'features/hiring/presentation/screens/hiring_landing_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Krushi Kranti Hiring',
      home: const HiringLandingScreen(), // <--- Set this as home
    );
  }
}