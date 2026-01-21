import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/uploard_screen.dart';
import 'screens/test_screen.dart';
import 'screens/results_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART PREP.AI',
      debugShowCheckedModeBanner: false,
      // In your MaterialApp's theme property

      theme: ThemeData(
        useMaterial3: true,
        // FIX: Just remove this line
        // primarySwatch: Colors.deepPurple,

        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.deepPurple, // You'll need to keep this
          foregroundColor: Colors.white,      // and this
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        //cardTheme: CardTheme( // The red line will disappear
        //   elevation: 2,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(16),
        //   ),

      ),

      // We start at the Home Screen
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),

      },
    );
  }
}