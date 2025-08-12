class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main routes
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String properties = '/properties';
  static const String addProperty = '/properties/add';
  static const String editProperty = '/properties/:propertyId/edit';
  static const String propertyDetail = '/properties/:propertyId';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:projectId';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:taskId';
  static const String maintenance = '/maintenance';
  static const String maintenanceSchedules = '/maintenance/schedules';
  static const String maintenanceScheduleDetail = '/maintenance/schedules/:scheduleId';
  static const String maintenanceTasks = '/maintenance/tasks';
  static const String maintenanceTaskDetail = '/maintenance/tasks/:taskId';
  static const String maintenanceCalendar = '/maintenance/calendar';
  
  // Profile routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // Utility routes
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
}