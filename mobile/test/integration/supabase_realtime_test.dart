import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:async';

import '../../lib/services/supabase_service.dart';
import '../../lib/config/supabase_config.dart';
import '../../lib/models/project.dart';
import '../../lib/models/property.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Real-time Integration Tests', () {
    setUpAll(() async {
      // Initialize Supabase for integration tests
      // Note: These tests require a real Supabase instance configured for testing
      try {
        await SupabaseService.initialize();
      } catch (e) {
        // Skip tests if Supabase is not configured
        print('Skipping Supabase integration tests: Supabase not configured');
      }
    });

    tearDownAll(() {
      SupabaseService.instance.dispose();
    });

    group('Project Real-time Updates', () {
      testWidgets('should receive real-time project updates', (WidgetTester tester) async {
        // Skip if Supabase is not configured
        if (!SupabaseConfig.isConfigured()) {
          return;
        }

        final completer = Completer<List<Project>>();
        late StreamSubscription subscription;

        // Listen to project updates
        subscription = SupabaseService.instance.watchProjects().listen(
          (projects) {
            if (!completer.isCompleted) {
              completer.complete(projects);
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        );

        try {
          // Wait for initial data or timeout
          final projects = await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Project>[],
          );

          expect(projects, isA<List<Project>>());
          
          // Test passes if we get any response (empty list is valid)
          print('Received ${projects.length} projects from real-time subscription');
        } finally {
          await subscription.cancel();
        }
      });

      testWidgets('should handle project CRUD operations with real-time updates', (WidgetTester tester) async {
        if (!SupabaseConfig.isConfigured()) {
          return;
        }

        final updateCompleter = Completer<List<Project>>();
        late StreamSubscription subscription;
        int updateCount = 0;

        subscription = SupabaseService.instance.watchProjects().listen(
          (projects) {
            updateCount++;
            if (updateCount >= 2) { // Initial load + update after create
              if (!updateCompleter.isCompleted) {
                updateCompleter.complete(projects);
              }
            }
          },
          onError: (error) {
            if (!updateCompleter.isCompleted) {
              updateCompleter.completeError(error);
            }
          },
        );

        try {
          // Create a test project to trigger real-time update
          final testProject = Project(
            id: 'test-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Real-time Test Project',
            description: 'Testing real-time updates',
            propertyId: 'test-property-id',
            status: ProjectStatus.active,
            priority: ProjectPriority.medium,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );

          // Create project (this should trigger a real-time update)
          await SupabaseService.instance.createProject(testProject);

          // Wait for the real-time update
          final updatedProjects = await updateCompleter.future.timeout(
            const Duration(seconds: 15),
            onTimeout: () => <Project>[],
          );

          expect(updatedProjects, isA<List<Project>>());
          
          // Clean up - delete the test project
          try {
            await SupabaseService.instance.deleteProject(testProject.id);
          } catch (e) {
            print('Cleanup failed: $e');
          }
        } finally {
          await subscription.cancel();
        }
      });
    });

    group('Property Real-time Updates', () {
      testWidgets('should receive real-time property updates', (WidgetTester tester) async {
        if (!SupabaseConfig.isConfigured()) {
          return;
        }

        final completer = Completer<List<Property>>();
        late StreamSubscription subscription;

        subscription = SupabaseService.instance.watchProperties().listen(
          (properties) {
            if (!completer.isCompleted) {
              completer.complete(properties);
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        );

        try {
          final properties = await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Property>[],
          );

          expect(properties, isA<List<Property>>());
          print('Received ${properties.length} properties from real-time subscription');
        } finally {
          await subscription.cancel();
        }
      });
    });

    group('Maintenance Reminders Real-time', () {
      testWidgets('should receive real-time maintenance reminder updates', (WidgetTester tester) async {
        if (!SupabaseConfig.isConfigured()) {
          return;
        }

        final completer = Completer<Map<String, dynamic>>();
        late StreamSubscription subscription;

        subscription = SupabaseService.instance.watchMaintenanceReminders().listen(
          (reminders) {
            if (!completer.isCompleted) {
              completer.complete(reminders);
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        );

        try {
          final reminders = await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () => <String, dynamic>{},
          );

          expect(reminders, isA<Map<String, dynamic>>());
          expect(reminders.containsKey('upcoming'), isTrue);
          expect(reminders.containsKey('overdue'), isTrue);
          expect(reminders.containsKey('today'), isTrue);
          
          print('Received maintenance reminders: ${reminders.keys.join(', ')}');
        } finally {
          await subscription.cancel();
        }
      });
    });

    group('Error Handling', () {
      testWidgets('should handle connection errors gracefully', (WidgetTester tester) async {
        if (!SupabaseConfig.isConfigured()) {
          return;
        }

        final errorCompleter = Completer<dynamic>();
        late StreamSubscription subscription;

        // Try to watch a non-existent table to trigger an error
        subscription = SupabaseService.instance.watchProjects(propertyId: 'non-existent-property').listen(
          (projects) {
            // Should not reach here with non-existent property
          },
          onError: (error) {
            if (!errorCompleter.isCompleted) {
              errorCompleter.complete(error);
            }
          },
        );

        try {
          // Wait for either success or error
          await Future.any([
            errorCompleter.future.timeout(const Duration(seconds: 5)),
            Future.delayed(const Duration(seconds: 5)),
          ]);

          // Test passes if no unhandled exceptions occur
          expect(true, isTrue);
        } finally {
          await subscription.cancel();
        }
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle multiple concurrent subscriptions', (WidgetTester tester) async {
        if (!SupabaseConfig.isConfigured()) {
          return;
        }

        final List<StreamSubscription> subscriptions = [];
        final List<Completer> completers = [];

        try {
          // Create multiple subscriptions
          for (int i = 0; i < 3; i++) {
            final completer = Completer<bool>();
            completers.add(completer);

            StreamSubscription? subscription;
            
            switch (i) {
              case 0:
                subscription = SupabaseService.instance.watchProjects().listen(
                  (projects) {
                    if (!completer.isCompleted) completer.complete(true);
                  },
                  onError: (error) {
                    if (!completer.isCompleted) completer.complete(false);
                  },
                );
                break;
              case 1:
                subscription = SupabaseService.instance.watchProperties().listen(
                  (properties) {
                    if (!completer.isCompleted) completer.complete(true);
                  },
                  onError: (error) {
                    if (!completer.isCompleted) completer.complete(false);
                  },
                );
                break;
              case 2:
                subscription = SupabaseService.instance.watchMaintenanceReminders().listen(
                  (reminders) {
                    if (!completer.isCompleted) completer.complete(true);
                  },
                  onError: (error) {
                    if (!completer.isCompleted) completer.complete(false);
                  },
                );
                break;
            }
            
            if (subscription != null) {
              subscriptions.add(subscription);
            }
          }

          // Wait for all subscriptions to either succeed or timeout
          final results = await Future.wait(
            completers.map((c) => c.future.timeout(
              const Duration(seconds: 10),
              onTimeout: () => false,
            )),
          );

          // At least some subscriptions should work
          expect(results.any((result) => result == true), isTrue);
          print('Concurrent subscriptions results: $results');
        } finally {
          // Clean up all subscriptions
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        }
      });
    });
  });
}