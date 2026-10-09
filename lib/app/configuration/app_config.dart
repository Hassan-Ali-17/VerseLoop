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

  static const String baseApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static const String webSocketUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  static bool get isFixtureMode => currentMode == AppMode.fixture;
  static bool get isConnectedMode => currentMode == AppMode.connected;

  static void setMode(AppMode mode) {
    currentMode = mode;
  }

  static void setRole(UserRole role) {
    currentRole = role;
  }
}
