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
    final bool loggedIn = await AuthUtils.isLoggedIn();

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      loggedIn ? '/home' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.appBlue,
        ),
      ),
    );
  }
}
