import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'intro_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'home_screen.dart';

import 'realtime_graph.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthService>(
      valueListenable: authService,
      builder: (context, service, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D1117),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00FF88),
              brightness: Brightness.dark,
            ),
          ),
          // 👇 Start with IntroScreen first
          home: const IntroScreen(),
          routes: {
            '/intro': (context) => const IntroScreen(),
            '/login': (context) => AuthGate(), // Firebase auth handler here
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            

          },
        );
      },
    );
  }
}

/// 🔥 This widget listens to Firebase authentication state.
class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
