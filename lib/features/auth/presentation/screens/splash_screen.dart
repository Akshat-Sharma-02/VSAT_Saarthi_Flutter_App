import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.containsKey('token');

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (isLoggedIn) {
        /// Login → Direct Dashboard
        Navigator.pushReplacementNamed(
          context,
          DashboardScreen.routeName,
        );
      } else {
        /// Logout → Login Screen
        Navigator.pushReplacementNamed(
          context,
          LoginScreen.routeName,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// LOGO
            Image.asset(
              'assets/logo/logo_VSAT.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            /// APP NAME
            const Text(
              "VSAT Saarthi",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Smart VSAT Companion",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),

            const SizedBox(height: 30),

            const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}