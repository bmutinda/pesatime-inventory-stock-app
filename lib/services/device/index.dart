import 'dart:math';

import 'package:inventory_app/helpers/prefs/shared_preferences.dart';

abstract class DeviceUtils {
  static const String _deviceIdKey = 'device_id';

  static Future<String> getDeviceId() async {
    final existingDeviceId =
        await SharedPreferencesManager.getString(_deviceIdKey);

    if (existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }

    final deviceId = _generateDeviceId();
    await SharedPreferencesManager.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return hex.join();
  }
}
