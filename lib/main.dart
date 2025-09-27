import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:twist_dashboard/pages/DashboardLayout.dart';
import 'firebase_options.dart'; // أضف هذا

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ضروري للويب
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Twist Loan System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashboardLayout(),
    );
  }
}
