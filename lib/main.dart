import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';

void main() {
  runApp(const VsatSaarthiApp());
}

class VsatSaarthiApp extends StatelessWidget {
  const VsatSaarthiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VSAT Saarthi',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      // ALWAYS START FROM SPLASH
      initialRoute: SplashScreen.routeName,

      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        OtpScreen.routeName: (_) => const OtpScreen(),
        '/compass': (_) => const SizedBox(),
      },
    );
  }
}