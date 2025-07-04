import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart'; // Replace with your actual home page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppScaffold()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 189, 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 40.0,
          ), // padding for progress bar
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/splash/splash.png', width: 150, height: 150),
              const SizedBox(height: 24),
              const Text(
                'AutoCare',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              const LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
