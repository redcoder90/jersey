import 'dart:async';

import 'package:flutter/material.dart';

import 'common/widgets/auth_background.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });

    _timer = Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 900),
            opacity: _isVisible ? 1 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  child: Image.asset(
                    'images/headphone.PNG',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Jersey Drip',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Premium sports commerce powered by Firebase',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
