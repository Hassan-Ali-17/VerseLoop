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

  // Live Railway Cloud Backend Domain
  static const String cloudDomain = 'verseloop-production.up.railway.app';

  static String get baseApiUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    return 'https://$cloudDomain/api/v1';
  }

  static String get webSocketUrl {
    if (_envWsUrl.isNotEmpty) return _envWsUrl;
    return 'wss://$cloudDomain/ws';
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
