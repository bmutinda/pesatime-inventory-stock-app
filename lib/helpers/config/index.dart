import 'package:flutter/foundation.dart';

abstract class AppConfig {
  static String get baseUrl {
    return kReleaseMode
        ? 'https://api.pesatime.com/inventory/stock-app/v1/'
        : 'http://10.0.2.2:3550/inventory/stock-app/v1/';
  }

  static const String authValidateCode = "auth/validate-code";
  static const String authLogin = "auth/login";
  static const String authRefresh = "auth/refresh";
  static const String profile = "me";
}
