import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/project.dart';
import '../models/property.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  SupabaseClient get client => Supabase.instance.client;
  
  // Real-time subscription management
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, StreamController> _streamControllers = {};
  
  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      SupabaseConfig.validateConfiguration();
      
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      
      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Supabase: $e');
      }
      rethrow;
    }
  }
  
  // Authentication helpers
  bool get isAuthenticated => client.auth.currentUser != null;
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => client.auth.currentUser?.id;
  
  // Real-time project updates
  Stream<List<Project>> watchProjects({String? propertyId}) {
    final key = 'projects_${propertyId ?? 'all'}';
    
    if (_streamControllers.containsKey(key)) {
      return _streamControllers[key]!.stream as Stream<List<Project>>;
    }
    
    final controller = StreamController<List<Project>>.broadcast();
    _streamControllers[key] = controller;
    
    // Initial data load
    _loadInitialProjects(controller, propertyId);
    
    // Set up real-time subscription
    final channel = client.channel('${SupabaseConfig.projectsChannel}_$key');
    
    var query = channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: SupabaseConfig.projectsTable,
    );
    
    if (propertyId != null) {
      query = query.filter('property_id', 'eq', propertyId);
    }
    
    query.listen((payload) {
      if (kDebugMode) {
        print('🔄 Project update received: ${payload.eventType}');
      }
      _handleProjectChange(controller, payload, propertyId);
    });
    
    channel.subscribe();
    _activeChannels[key] = channel;
    
    return controller.stream;
  }
  
  // Real-time property updates
  Stream<List<Property>> watchProperties() {
    const key = 'properties_all';
    
    if (_streamControllers.containsKey(key)) {
      return _streamControllers[key]!.stream as Stream<List<Property>>;
    }
    
    final controller = StreamController<List<Property>>.broadcast();
    _streamControllers[key] = controller;
    
    // Initial data load
    _loadInitialProperties(controller);
    
    // Set up real-time subscription
    final channel = client.channel(SupabaseConfig.propertiesChannel);
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.propertiesTable,
        )
        .listen((payload) {
          if (kDebugMode) {
            print('🔄 Property update received: ${payload.eventType}');
          }
          _handlePropertyChange(controller, payload);
        });
    
    channel.subscribe();
    _activeChannels[key] = channel;
    
    return controller.stream;
  }
  
  // Real-time maintenance updates
  Stream<Map<String, dynamic>> watchMaintenanceReminders() {
    const key = 'maintenance_reminders';
    
    if (_streamControllers.containsKey(key)) {
      return _streamControllers[key]!.stream as Stream<Map<String, dynamic>>;
    }
    
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _streamControllers[key] = controller;
    
    // Initial data load
    _loadInitialMaintenanceReminders(controller);
    
    // Set up real-time subscription
    final channel = client.channel(SupabaseConfig.maintenanceChannel);
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.maintenanceSchedulesTable,
        )
        .listen((payload) {
          if (kDebugMode) {
            print('🔄 Maintenance update received: ${payload.eventType}');
          }
          _handleMaintenanceChange(controller, payload);
        });
    
    channel.subscribe();
    _activeChannels[key] = channel;
    
    return controller.stream;
  }
  
  // Direct Supabase CRUD operations
  Future<List<Project>> getProjects({String? propertyId}) async {
    try {
      var query = client
          .from(SupabaseConfig.projectsTable)
          .select();
      
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      
      if (currentUserId != null) {
        query = query.eq('user_id', currentUserId!);
      }
      
      final response = await query;
      return (response as List)
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch projects from Supabase: $e');
      }
      throw Exception('Failed to fetch projects: $e');
    }
  }
  
  Future<List<Property>> getProperties() async {
    try {
      final query = client
          .from(SupabaseConfig.propertiesTable)
          .select();
      
      if (currentUserId != null) {
        // Use RLS to automatically filter by user access
        final response = await query;
        return (response as List)
            .map((json) => Property.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch properties from Supabase: $e');
      }
      throw Exception('Failed to fetch properties: $e');
    }
  }
  
  Future<Project> createProject(Project project) async {
    try {
      final data = project.toJson();
      data['user_id'] = currentUserId;
      
      final response = await client
          .from(SupabaseConfig.projectsTable)
          .insert(data)
          .select()
          .single();
      
      return Project.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create project in Supabase: $e');
      }
      throw Exception('Failed to create project: $e');
    }
  }
  
  Future<Project> updateProject(Project project) async {
    try {
      final response = await client
          .from(SupabaseConfig.projectsTable)
          .update(project.toJson())
          .eq('id', project.id)
          .select()
          .single();
      
      return Project.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update project in Supabase: $e');
      }
      throw Exception('Failed to update project: $e');
    }
  }
  
  Future<void> deleteProject(String projectId) async {
    try {
      await client
          .from(SupabaseConfig.projectsTable)
          .delete()
          .eq('id', projectId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete project in Supabase: $e');
      }
      throw Exception('Failed to delete project: $e');
    }
  }
  
  // Private helper methods
  Future<void> _loadInitialProjects(StreamController<List<Project>> controller, String? propertyId) async {
    try {
      final projects = await getProjects(propertyId: propertyId);
      if (!controller.isClosed) {
        controller.add(projects);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  Future<void> _loadInitialProperties(StreamController<List<Property>> controller) async {
    try {
      final properties = await getProperties();
      if (!controller.isClosed) {
        controller.add(properties);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  Future<void> _loadInitialMaintenanceReminders(StreamController<Map<String, dynamic>> controller) async {
    try {
      // Load upcoming maintenance reminders
      final response = await client
          .from(SupabaseConfig.maintenanceSchedulesTable)
          .select('*, properties(*)')
          .gte('next_due_date', DateTime.now().toIso8601String())
          .lte('next_due_date', DateTime.now().add(const Duration(days: 30)).toIso8601String())
          .order('next_due_date');
      
      final reminders = {
        'upcoming': response,
        'overdue': [],
        'today': [],
      };
      
      if (!controller.isClosed) {
        controller.add(reminders);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  void _handleProjectChange(StreamController<List<Project>> controller, 
                          PostgresChangePayload payload, String? propertyId) async {
    try {
      final projects = await getProjects(propertyId: propertyId);
      if (!controller.isClosed) {
        controller.add(projects);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  void _handlePropertyChange(StreamController<List<Property>> controller, 
                           PostgresChangePayload payload) async {
    try {
      final properties = await getProperties();
      if (!controller.isClosed) {
        controller.add(properties);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  void _handleMaintenanceChange(StreamController<Map<String, dynamic>> controller,
                              PostgresChangePayload payload) async {
    try {
      await _loadInitialMaintenanceReminders(controller);
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  // Cleanup methods
  void unsubscribeFromChannel(String key) {
    if (_activeChannels.containsKey(key)) {
      _activeChannels[key]?.unsubscribe();
      _activeChannels.remove(key);
    }
    
    if (_streamControllers.containsKey(key)) {
      _streamControllers[key]?.close();
      _streamControllers.remove(key);
    }
  }
  
  void dispose() {
    for (final channel in _activeChannels.values) {
      channel.unsubscribe();
    }
    _activeChannels.clear();
    
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
  
  // Error handling
  String formatSupabaseError(dynamic error) {
    if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    } else if (error is AuthException) {
      return 'Authentication error: ${error.message}';
    } else if (error is StorageException) {
      return 'Storage error: ${error.message}';
    } else {
      return 'An unexpected error occurred: $error';
    }
  }
}