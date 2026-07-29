import 'package:flutter/foundation.dart';

abstract class AppConfig {
  static String get baseUrl {
    return kReleaseMode
        ? 'https://api.pesatime.com/inventory/stock-app/v1/'
        : 'https://8483-41-90-113-129.ngrok-free.app/inventory/stock-app/v1/';
  }

  static const String authValidateCode = "auth/validate-code";
  static const String authLogin = "auth/login";
  static const String authRefresh = "auth/refresh";
  static const String profile = "me";
}
