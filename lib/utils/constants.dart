import '../config/app_config.dart';

class AppConstants {
  /// API Base URL - now managed from AppConfig
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  /// App Name
  static String get appName => AppConfig.appName;
  
  /// App Version
  static String get appVersion => AppConfig.appVersion;
}
