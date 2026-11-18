import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/utils/app_color.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController bubbleC;

  @override
  void initState() {
    super.initState();

    bubbleC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    bubbleC.dispose();
    super.dispose();
  }

  // gelembunkk
  Widget bubble(double left, double size, double startOffset) {
    return AnimatedBuilder(
      animation: bubbleC,
      builder: (context, child) {
        double progress = (bubbleC.value + startOffset) % 1.0;
        return Positioned(
          left: left,
          bottom: 58 + (progress * 42),
          child: Opacity(
            opacity: 1.0 - progress,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColor.sage,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.darkRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(  //logo sm gelebung
              width: 110,
              height: 115,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColor.sage.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science,
                      size: 54,
                      color: AppColor.cream,
                    ),
                  ),
                  bubble(46, 8, 0.0),
                  bubble(56, 6, 0.35),
                  bubble(42, 5, 0.7),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'LAB THINGS',
              style: TextStyle(
                fontSize: 28,
                letterSpacing: 3,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Laboratory Inventory System',
              style: TextStyle(
                color: AppColor.sage,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigationPage();
        }

        return const LoginScreen();
      },
    );
  }
}