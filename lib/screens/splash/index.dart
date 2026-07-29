import 'package:flutter/material.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/auth/index.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    var hasActiveSession = false;

    try {
      hasActiveSession = await AuthUtils.refreshSession();
    } on AuthException {
      hasActiveSession = false;
    }

    if (hasActiveSession) {
      try {
        await AuthUtils.getMe();
      } on AuthException {
        hasActiveSession = false;
      }
    }

    if (!hasActiveSession) {
      await AuthUtils.logout();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      hasActiveSession ? '/home' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pesatime Stocktake',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.appBlue,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppColors.appBlue,
            ),
          ],
        ),
      ),
    );
  }
}
