class SupabaseConfig {
  // Environment-based configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL', // Replace with your actual Supabase URL in production
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY', // Replace with your actual anon key in production
  );
  
  // Supabase table names
  static const String usersTable = 'users';
  static const String propertiesTable = 'properties';
  static const String propertyPermissionsTable = 'property_permissions';
  static const String projectsTable = 'projects';
  static const String projectTasksTable = 'project_tasks';
  static const String projectAssignmentsTable = 'project_assignments';
  static const String maintenanceSchedulesTable = 'maintenance_schedules';
  static const String maintenanceRecordsTable = 'maintenance_records';
  
  // Real-time channels
  static const String projectsChannel = 'projects_realtime';
  static const String propertiesChannel = 'properties_realtime';
  static const String maintenanceChannel = 'maintenance_realtime';
  
  // Configuration options
  static const bool enableRealtime = true;
  static const bool enableAuth = true;
  static const bool enableStorage = false; // Enable if you plan to use Supabase Storage
  
  // Real-time subscription settings
  static const Duration realtimeTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Validation methods
  static bool isConfigured() {
    return supabaseUrl != 'YOUR_SUPABASE_URL' && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
           supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty;
  }
  
  static void validateConfiguration() {
    if (!isConfigured()) {
      throw Exception(
        'Supabase configuration is not set up properly. '
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables '
        'or update the default values in SupabaseConfig.'
      );
    }
  }
  
  // Environment-specific configurations
  static Map<String, dynamic> getClientOptions() {
    return {
      'auth': {
        'persistSession': true,
        'autoRefreshToken': true,
        'detectSessionInUrl': false,
      },
      'realtime': {
        'timeout': realtimeTimeout.inMilliseconds,
      },
      'global': {
        'headers': {
          'x-client-info': 'home-skillet-mobile@1.0.0',
        },
      },
    };
  }
}