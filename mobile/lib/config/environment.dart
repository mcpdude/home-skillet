enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment _environment = Environment.development;
  
  static Environment get current => _environment;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  // Backend API Configuration
  static String get nodeBackendUrl {
    switch (_environment) {
      case Environment.development:
        return const String.fromEnvironment(
          'NODE_BACKEND_URL',
          defaultValue: 'http://localhost:3000/api',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'NODE_BACKEND_URL',
          defaultValue: 'https://staging-api.homeskillet.com/api',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'NODE_BACKEND_URL',
          defaultValue: 'https://api.homeskillet.com/api',
        );
    }
  }
  
  // Supabase Configuration
  static String get supabaseUrl {
    switch (_environment) {
      case Environment.development:
        return const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://your-dev-project.supabase.co',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://your-staging-project.supabase.co',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://your-prod-project.supabase.co',
        );
    }
  }
  
  static String get supabaseAnonKey {
    switch (_environment) {
      case Environment.development:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'your-development-anon-key',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'your-staging-anon-key',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'your-production-anon-key',
        );
    }
  }
  
  // Feature Flags
  static bool get enableSupabaseIntegration {
    return const bool.fromEnvironment(
      'ENABLE_SUPABASE',
      defaultValue: true,
    );
  }
  
  static bool get enableRealtimeFeatures {
    return const bool.fromEnvironment(
      'ENABLE_REALTIME',
      defaultValue: true,
    );
  }
  
  static bool get enableSupabaseAuth {
    return const bool.fromEnvironment(
      'ENABLE_SUPABASE_AUTH',
      defaultValue: false, // Keep JWT as primary by default
    );
  }
  
  static bool get enableLogging {
    return const bool.fromEnvironment(
      'ENABLE_LOGGING',
      defaultValue: isDevelopment,
    );
  }
  
  // API Mode Configuration
  static String get defaultApiMode {
    return const String.fromEnvironment(
      'API_MODE',
      defaultValue: 'nodeBackend', // nodeBackend, supabase, hybrid
    );
  }
  
  // Validation
  static bool get isSupabaseConfigured {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    return url.isNotEmpty && 
           key.isNotEmpty && 
           !url.contains('your-') && 
           !key.contains('your-');
  }
  
  static void validateConfiguration() {
    if (enableSupabaseIntegration && !isSupabaseConfigured) {
      throw Exception(
        'Supabase is enabled but not properly configured. '
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables '
        'or update the default values in EnvironmentConfig.'
      );
    }
  }
  
  // Debug information
  static Map<String, dynamic> get debugInfo => {
    'environment': _environment.name,
    'nodeBackendUrl': nodeBackendUrl,
    'supabaseUrl': isSupabaseConfigured ? supabaseUrl : '[NOT CONFIGURED]',
    'enableSupabaseIntegration': enableSupabaseIntegration,
    'enableRealtimeFeatures': enableRealtimeFeatures,
    'enableSupabaseAuth': enableSupabaseAuth,
    'defaultApiMode': defaultApiMode,
    'enableLogging': enableLogging,
  };
}