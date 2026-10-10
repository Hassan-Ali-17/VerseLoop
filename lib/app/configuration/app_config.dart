import 'package:flutter/foundation.dart';

enum AppMode {
  fixture,
  connected,
}

enum UserRole {
  customer,
  staff,
}

class AppConfig {
  static AppMode currentMode = AppMode.connected;
  static UserRole currentRole = UserRole.customer;

  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _envWsUrl = String.fromEnvironment('WS_URL');

  // PC's local Wi-Fi IP for physical mobile devices on the same network
  static String hostIp = '192.168.1.12';

  static String get baseApiUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    // On physical mobile devices, 'localhost' points to the phone itself.
    // Use the host computer's local Wi-Fi IP address.
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final host = isMobile ? hostIp : 'localhost';
    return 'http://$host:8080/api/v1';
  }

  static String get webSocketUrl {
    if (_envWsUrl.isNotEmpty) return _envWsUrl;
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final host = isMobile ? hostIp : 'localhost';
    return 'ws://$host:8080/ws';
  }

  static bool get isFixtureMode => currentMode == AppMode.fixture;
  static bool get isConnectedMode => currentMode == AppMode.connected;

  static void setMode(AppMode mode) {
    currentMode = mode;
  }

  static void setRole(UserRole role) {
    currentRole = role;
  }
}
