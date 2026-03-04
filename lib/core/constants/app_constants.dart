class AppConstants {
  AppConstants._();

  static const String appName = 'UMKM Ku';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Free tier limits
  static const int maxFreeProducts = 30;
  static const int maxFreeCustomers = 10;
  static const int maxFreeHistoryDays = 30;

  // SharedPreferences keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserId = 'user_id';

  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int syncBatchSize = 50;

  // Pagination
  static const int defaultPageSize = 20;
}
