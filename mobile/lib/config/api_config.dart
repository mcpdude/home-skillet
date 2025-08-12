class ApiConfig {
  // Backend API Configuration
  static const String baseUrl = 'http://localhost:5000/api'; // Updated for project management backend
  static const String apiVersion = 'v1';
  
  // Traditional REST API Endpoints (Node.js backend)
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String propertiesEndpoint = '/properties';
  static const String projectsEndpoint = '/projects';
  static const String tasksEndpoint = '/tasks';
  
  // Supabase REST API Endpoints
  static const String supabaseRestEndpoint = '/rest/v1';
  
  // API Mode Selection
  static ApiMode currentMode = ApiMode.nodeBackend; // Default to Node.js backend
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String apiModeKey = 'api_mode';
  
  // Helper methods for API mode management
  static void setApiMode(ApiMode mode) {
    currentMode = mode;
  }
  
  static bool get isUsingSupabase => currentMode == ApiMode.supabase;
  static bool get isUsingNodeBackend => currentMode == ApiMode.nodeBackend;
  static bool get isUsingHybrid => currentMode == ApiMode.hybrid;
}

enum ApiMode {
  nodeBackend,  // Use Node.js backend exclusively
  supabase,     // Use Supabase REST API exclusively
  hybrid,       // Use both - Node.js for auth, Supabase for data + realtime
}