import 'package:flutter/foundation.dart';

abstract class AppConfig {
  static String get baseUrl {
    return kReleaseMode
        ? 'https://api.pesatime.com/inventory/stock-app/v1/'
        : 'https://cd51-102-217-4-34.ngrok-free.app/inventory/stock-app/v1/';
  }
}
