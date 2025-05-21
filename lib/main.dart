import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔹 Firebase core paketi
import 'firebase_options.dart'; // 🔹 Firebase yapılandırma dosyan
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase başlatılmadan önce gerekli
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // 🔥 Firebase başlatılıyor

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDA App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
