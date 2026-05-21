import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final currentLevel = prefs.getInt("currentLevel") ?? 1;

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (seenOnboarding) {

      // 👇 بعد اللوجين هنحدد يروح فين حسب التقدم
      if (currentLevel == 1) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else if (currentLevel == 2) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }

    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E8F7E),
      body: Center(
        child: Image.asset(
          'assets/images/splash.jpg',
          width: 200,
        ),
      ),
    );
  }
}