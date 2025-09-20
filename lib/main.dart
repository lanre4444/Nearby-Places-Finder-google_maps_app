import 'package:flutter/material.dart';
import 'package:nearby_finder/get_user_location.dart';

// ✅ Make sure this matches the actual path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearby Places App',
      debugShowCheckedModeBanner: false,
      home: GetUserLocation(), // ✅ Starts the upgraded map UI
    );
  }
}
