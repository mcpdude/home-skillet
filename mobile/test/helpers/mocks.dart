import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:home_skillet_mobile/services/auth_service.dart';
import 'package:home_skillet_mobile/services/property_service.dart';
import 'package:home_skillet_mobile/services/project_service.dart';
import 'package:home_skillet_mobile/services/maintenance_service.dart';
import 'package:home_skillet_mobile/services/storage_service.dart';
import 'package:home_skillet_mobile/services/http_client.dart';
import 'package:home_skillet_mobile/services/supabase_service.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/providers/project_provider.dart';
import 'package:home_skillet_mobile/providers/maintenance_provider.dart';
import 'package:home_skillet_mobile/models/user.dart';

// Generate mocks for all services, providers, and Supabase classes
@GenerateMocks([
  // Existing services
  AuthService,
  PropertyService,
  ProjectService,
  MaintenanceService,
  StorageService,
  HttpClient,
  
  // Supabase integration
  SupabaseService,
  SupabaseClient,
  GoTrueClient,
  RealtimeClient,
  RealtimeChannel,
  PostgrestClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  StorageClient,
  
  // Providers
  AuthProvider,
  PropertyProvider,
  ProjectProvider,
  MaintenanceProvider,
  
  // Models
  UserModel,
])
void main() {
  // This file is used by mockito to generate mock classes
  // Run: flutter packages pub run build_runner build
}