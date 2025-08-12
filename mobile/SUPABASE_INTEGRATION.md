# Supabase Integration Guide

This document provides comprehensive information about the Supabase integration in the Home Skillet Flutter mobile app.

## Overview

The app has been enhanced with Supabase integration while maintaining the existing Node.js backend architecture. The integration supports three operational modes:

1. **Node.js Backend Only** (Default) - Traditional JWT authentication with Node.js API
2. **Supabase Only** - Direct Supabase integration with Supabase Auth
3. **Hybrid Mode** - Node.js for authentication, Supabase for data and real-time features

## Architecture

### Key Components

- **SupabaseService** - Core service for Supabase operations and real-time subscriptions
- **Enhanced HttpClient** - Smart routing between Node.js backend and Supabase REST API
- **Enhanced AuthService** - Supports both JWT and Supabase Auth
- **Environment Configuration** - Environment-specific settings for different deployment modes

### File Structure

```
lib/
├── config/
│   ├── supabase_config.dart      # Supabase configuration
│   ├── environment.dart          # Environment-specific settings
│   └── api_config.dart          # Enhanced with API mode selection
├── services/
│   ├── supabase_service.dart    # Core Supabase integration
│   ├── http_client.dart         # Enhanced with hybrid support
│   └── auth_service.dart        # Enhanced with Supabase Auth
└── ...
```

## Configuration

### Environment Variables

Set these environment variables or update the default values in the configuration files:

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Node.js Backend
NODE_BACKEND_URL=https://your-backend.com/api

# Feature Flags
ENABLE_SUPABASE=true
ENABLE_REALTIME=true
ENABLE_SUPABASE_AUTH=false  # Keep JWT as primary
API_MODE=nodeBackend        # nodeBackend, supabase, or hybrid
```

### Flutter Build Configuration

To pass environment variables during build:

```bash
# Development
flutter run --dart-define=SUPABASE_URL=https://dev-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-dev-key

# Production
flutter build apk --dart-define=SUPABASE_URL=https://prod-project.supabase.co \
                  --dart-define=SUPABASE_ANON_KEY=your-prod-key \
                  --dart-define=API_MODE=hybrid
```

## Features

### Real-time Subscriptions

The app now supports real-time updates for:

1. **Projects** - Real-time project updates across devices
2. **Properties** - Property changes and additions
3. **Maintenance Reminders** - Upcoming and overdue maintenance tasks

#### Usage Example

```dart
// Listen to project updates
StreamBuilder<List<Project>>(
  stream: SupabaseService.instance.watchProjects(propertyId: 'property-123'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final projects = snapshot.data!;
      return ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) => ProjectTile(project: projects[index]),
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Hybrid Authentication

The authentication service now supports both JWT (primary) and Supabase Auth:

```dart
// The AuthService automatically chooses the appropriate method
final authResponse = await authService.login(LoginRequest(
  email: 'user@example.com',
  password: 'password123',
));
```

### Smart API Routing

The HTTP client automatically routes requests based on the configured API mode:

```dart
// This will route to Node.js backend in nodeBackend mode
// or to Supabase in supabase/hybrid mode for data operations
final projects = await httpClient.get('/projects');

// This will always route to Node.js backend (forced)
final authResult = await httpClient.post('/auth/login', 
  data: credentials, 
  forceNodeBackend: true
);
```

## API Modes

### 1. Node.js Backend Only (Default)

- All requests go to the Node.js backend
- JWT authentication
- Traditional REST API
- No real-time features

```dart
ApiConfig.setApiMode(ApiMode.nodeBackend);
```

### 2. Supabase Only

- All requests go directly to Supabase
- Supabase Auth for authentication
- Direct database operations through Supabase REST API
- Full real-time capabilities

```dart
ApiConfig.setApiMode(ApiMode.supabase);
```

### 3. Hybrid Mode (Recommended)

- Authentication requests go to Node.js backend (JWT)
- Data operations go to Supabase
- Real-time features enabled
- Best of both worlds

```dart
ApiConfig.setApiMode(ApiMode.hybrid);
```

## Real-time Features

### Project Updates

```dart
// Watch all projects
SupabaseService.instance.watchProjects()

// Watch projects for specific property
SupabaseService.instance.watchProjects(propertyId: 'property-123')
```

### Property Updates

```dart
// Watch all accessible properties
SupabaseService.instance.watchProperties()
```

### Maintenance Reminders

```dart
// Watch maintenance reminders (upcoming, overdue, today)
SupabaseService.instance.watchMaintenanceReminders()
```

### Cleanup

Always clean up subscriptions to prevent memory leaks:

```dart
@override
void dispose() {
  SupabaseService.instance.unsubscribeFromChannel('projects_all');
  super.dispose();
}
```

## Error Handling

The integration includes comprehensive error handling:

```dart
try {
  final projects = await SupabaseService.instance.getProjects();
} catch (e) {
  final friendlyMessage = SupabaseService.instance.formatSupabaseError(e);
  // Show user-friendly error message
}
```

### Common Error Types

- **PostgrestException** - Database-related errors
- **AuthException** - Authentication errors
- **StorageException** - File storage errors (if using Supabase Storage)
- **Network Errors** - Connection issues

## Testing

### Unit Tests

Run unit tests for Supabase integration:

```bash
flutter test test/unit/supabase_service_test.dart
flutter test test/unit/auth_service_supabase_test.dart
flutter test test/unit/http_client_hybrid_test.dart
```

### Integration Tests

Run integration tests (requires configured Supabase instance):

```bash
flutter test integration_test/supabase_realtime_test.dart
```

### Test Helpers

Use the provided test helpers for consistent testing:

```dart
import '../helpers/supabase_test_helpers.dart';

// Create mock data
final mockProject = SupabaseTestHelpers.createMockProjectData();
final mockUser = SupabaseTestHelpers.createMockSupabaseUser();

// Set up mock environment
SupabaseTestHelpers.setupTestEnvironment();
```

## Security Considerations

### Row Level Security (RLS)

The Supabase database has RLS enabled on all tables. Users can only access:

- Their own user profile
- Properties they own or have been granted access to
- Projects and tasks for accessible properties
- Maintenance data for accessible properties

### Authentication

- JWT remains the primary authentication method
- Supabase Auth is optional and can be enabled via configuration
- Tokens are securely stored using flutter_secure_storage

### API Keys

- The Supabase anon key is safe to use in the client app
- It only provides access allowed by RLS policies
- Never store the service role key in the client app

## Performance Optimization

### Connection Management

- Real-time connections are managed efficiently
- Automatic reconnection on network changes
- Proper cleanup of unused subscriptions

### Caching

- The app maintains offline capability
- Data is cached locally using the existing storage service
- Real-time updates supplement cached data

### Subscription Management

- Only create subscriptions when needed
- Unsubscribe when leaving screens
- Use the built-in subscription management in SupabaseService

## Deployment

### Development Environment

1. Set up a Supabase project for development
2. Configure environment variables
3. Run database migrations on Supabase
4. Test with the hybrid mode

### Production Environment

1. Create production Supabase project
2. Set up production environment variables
3. Enable RLS policies
4. Configure proper CORS settings
5. Monitor real-time connection usage

## Troubleshooting

### Common Issues

1. **Configuration not found**
   - Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set
   - Check that values don't contain placeholder text

2. **Real-time not working**
   - Verify that RLS policies allow the user to access data
   - Check that real-time is enabled on the Supabase dashboard
   - Ensure proper subscription setup and cleanup

3. **Authentication issues**
   - Verify API mode configuration
   - Check that both JWT and Supabase auth are configured correctly
   - Ensure proper token handling

4. **Performance issues**
   - Monitor the number of active subscriptions
   - Implement proper cleanup in widget dispose methods
   - Use connection pooling settings

### Debug Information

Enable debug logging to see configuration and request details:

```dart
if (kDebugMode) {
  print('Environment Config: ${EnvironmentConfig.debugInfo}');
  print('API Mode: ${ApiConfig.currentMode}');
}
```

## Migration Path

### From Node.js Only to Hybrid

1. Set up Supabase project
2. Run database migrations
3. Configure environment variables
4. Set API mode to hybrid
5. Test authentication still works
6. Gradually enable real-time features

### From Hybrid to Supabase Only

1. Ensure all data is properly synced
2. Test Supabase Auth thoroughly
3. Update API mode to supabase
4. Remove Node.js backend dependencies (if desired)
5. Update deployment configuration

## Benefits

### Real-time Features
- Instant updates across devices
- Live collaboration capabilities
- Maintenance reminders and notifications

### Scalability
- Supabase handles database scaling automatically
- Real-time infrastructure is managed
- Reduces backend maintenance overhead

### Developer Experience
- Type-safe database operations
- Built-in authentication handling
- Comprehensive error handling
- Easy testing with provided helpers

### Offline Capability
- Maintains existing offline features
- Real-time updates supplement cached data
- Graceful degradation when offline

## Support

For issues related to Supabase integration:

1. Check the troubleshooting section above
2. Review the test files for usage examples
3. Consult the Supabase documentation
4. Check the environment configuration

The integration is designed to be backward compatible, so existing functionality continues to work even if Supabase is not configured.