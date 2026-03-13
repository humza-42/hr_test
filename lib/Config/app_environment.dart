/// App Environment Configuration
///
/// This file controls the backend environment for the application.
/// Toggle between mock and live backend by changing [useMockBackend].
///
/// Usage:
/// - Set `useMockBackend = true` for development with mock server
/// - Set `useMockBackend = false` for production/real backend
class AppEnvironment {
  // ============================================
  // ENVIRONMENT TOGGLE
  // ============================================

  /// Set to `true` to use mock backend (JSON Server)
  /// Set to `false` to use live backend (Python server)
  static const bool useMockBackend = true;

  // ============================================
  // BASE URLS
  // ============================================

  /// Mock server URL (JSON Server)
  /// Use localhost for Windows desktop, 10.0.2.2 for Android emulator
  static const String mockBaseUrl = 'http://localhost:5000/api';

  /// Live server URL (Python Backend)
  static const String liveBaseUrl = 'http://192.168.18.26:5000/api';

  // ============================================
  // ACTIVE CONFIGURATION
  // ============================================

  /// Returns the active base URL based on environment
  static String get baseUrl => useMockBackend ? mockBaseUrl : liveBaseUrl;

  // ============================================
  // MOCK CREDENTIALS (For Testing)
  // ============================================

  /// Mock email for testing with mock server
  static const String mockEmail = 'test@example.com';

  /// Mock password for testing with mock server
  static const String mockPassword = 'password123';

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Check if currently using mock backend
  static bool get isMockMode => useMockBackend;

  /// Get environment name for display purposes
  static String get environmentName => useMockBackend ? 'Mock' : 'Live';

  /// Print current environment info (useful for debugging)
  static void printEnvironmentInfo() {
    print('========================================');
    print('Environment: $environmentName');
    print('Base URL: $baseUrl');
    print('Mock Mode: $isMockMode');
    print('========================================');
  }
}
