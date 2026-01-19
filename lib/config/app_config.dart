/// ============================================
/// TASKIFY APPLICATION CONFIGURATION
/// ============================================
/// 
/// This file contains all environment-specific configurations.
/// To change the API endpoint for different environments, simply
/// update the values below.
/// 
/// ============================================

class AppConfig {
  // ============================================
  // ENVIRONMENT SELECTION
  // ============================================
  // Change this to switch between environments:
  // - Environment.development
  // - Environment.staging  
  // - Environment.production
  // ============================================
  
  static const Environment currentEnvironment = Environment.development;

  // ============================================
  // API CONFIGURATION
  // ============================================
  
  /// Development Environment (Local Development)
  static const String _devApiUrl = 'https://taskify-api-two.vercel.app/api';
  
  /// Staging Environment (Testing on Network)
  static const String _stagingApiUrl = 'https://taskify-api-two.vercel.app/api';
  
  /// Production Environment (vercel Public URL)
  static const String _productionApiUrl = 'https://taskify-api-two.vercel.app/api';

  // ============================================
  // DATABASE CONFIGURATION (For Reference Only)
  // ============================================
  // Note: Flutter doesn't connect directly to database.
  // These are for documentation purposes only.
  
  static const String dbServer = 'DESKTOP-L642Q38';
  static const String dbName = 'TaskifyDB';
  static const String dbUser = 'taskify';
  // Password is stored securely on backend only

  // ============================================
  // API ENDPOINTS (Auto-selected based on environment)
  // ============================================
  
  /// Get the API base URL based on current environment
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _devApiUrl;
      case Environment.staging:
        return _stagingApiUrl;
      case Environment.production:
        return _productionApiUrl;
    }
  }

  // ============================================
  // ENDPOINT PATHS
  // ============================================
  
  // Auth Endpoints
  static String get loginEndpoint => '$apiBaseUrl/auth/login';
  static String get signupEndpoint => '$apiBaseUrl/auth/signup';
  static String get refreshTokenEndpoint => '$apiBaseUrl/auth/refresh';
  static String get getMeEndpoint => '$apiBaseUrl/auth/me';
  
  // Task Endpoints
  static String get tasksEndpoint => '$apiBaseUrl/tasks';
  
  // Upload Endpoint
  static String get uploadsBaseUrl => apiBaseUrl.replaceAll('/api', '/uploads');

  // ============================================
  // APP SETTINGS
  // ============================================
  
  static const String appName = 'Taskify';
  static const String appVersion = '1.0.0';
  
  
  /// Connection timeout in seconds
  static const int connectionTimeout = 30;
  
  /// Receive timeout in seconds
  static const int receiveTimeout = 30;

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get environment name as string
  static String get environmentName {
    switch (currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Check if running in development mode
  static bool get isDevelopment => currentEnvironment == Environment.development;
  
  /// Check if running in production mode
  static bool get isProduction => currentEnvironment == Environment.production;

  /// Print current configuration (for debugging)
  static void printConfig() {
    print('=================================');
    print('TASKIFY CONFIGURATION');
    print('=================================');
    print('Environment: $environmentName');
    print('API Base URL: $apiBaseUrl');
    print('DB Server: $dbServer');
    print('DB Name: $dbName');
    print('=================================');
  }
}

// ============================================
// ENVIRONMENT ENUM
// ============================================

enum Environment {
  development,
  staging,
  production,
}
