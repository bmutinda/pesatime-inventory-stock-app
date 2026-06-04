import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/helpers/navigator_service.dart';
import 'package:inventory_app/screens/home/index.dart';
import 'package:inventory_app/screens/login/index.dart';
import 'package:flutter/material.dart' hide Router;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Pesatime Inventory STA',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        useMaterial3: true,
        textTheme: GoogleFonts.sourceSans3TextTheme(textTheme).copyWith(),
      ),
    );
  }
}
