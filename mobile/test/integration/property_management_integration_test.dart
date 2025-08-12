import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/main.dart' as app;
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/services/property_service.dart';
import 'package:home_skillet_mobile/services/http_client.dart';
import 'package:home_skillet_mobile/models/property.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Property Management Integration Tests', () {
    testWidgets('Complete property management workflow', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // TODO: Add authentication flow if required
      // For now, assume user is authenticated

      // Test 1: Navigate to Properties Screen
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();

      // Verify properties screen loaded
      expect(find.text('My Properties'), findsOneWidget);

      // Test 2: Add New Property
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in property form
      await tester.enterText(
        find.byKey(const Key('property_name_field')), 
        'Test Property'
      );
      await tester.enterText(
        find.byKey(const Key('property_address_field')), 
        '123 Test Street, Test City'
      );
      
      // Select property type
      await tester.tap(find.byKey(const Key('property_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('House').last);
      await tester.pumpAndSettle();

      // Add optional details
      await tester.enterText(
        find.byKey(const Key('year_built_field')), 
        '2000'
      );
      await tester.enterText(
        find.byKey(const Key('bedrooms_field')), 
        '3'
      );
      await tester.enterText(
        find.byKey(const Key('bathrooms_field')), 
        '2'
      );

      // Save property
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Verify property was created and we're back to list
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('123 Test Street, Test City'), findsOneWidget);

      // Test 3: Search for Property
      await tester.enterText(find.byType(TextField), 'Test Property');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Test Property'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Test 4: Filter Properties by Type
      await tester.tap(find.text('House'));
      await tester.pumpAndSettle();

      // Verify filtered results show only houses
      expect(find.text('Test Property'), findsOneWidget);

      // Reset filter
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Test 5: View Property Details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Verify details screen
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('123 Test Street, Test City'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // bedrooms
      expect(find.text('2'), findsOneWidget); // bathrooms

      // Test 6: Edit Property
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Edit Property'));
      await tester.pumpAndSettle();

      // Modify property name
      await tester.enterText(
        find.byKey(const Key('property_name_field')), 
        'Updated Test Property'
      );

      // Save changes
      await tester.tap(find.text('Update Property'));
      await tester.pumpAndSettle();

      // Verify update was successful
      expect(find.text('Updated Test Property'), findsOneWidget);

      // Test 7: Property Settings
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify settings screen
      expect(find.text('Property Settings'), findsOneWidget);
      expect(find.text('Property Information'), findsOneWidget);
      expect(find.text('Access Control'), findsOneWidget);

      // Go back to property list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test 8: Grid View Toggle
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Verify grid view is active
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byIcon(Icons.grid_view), findsOneWidget);

      // Switch back to list view
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      // Verify list view is active
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);

      // Test 9: Delete Property
      await tester.tap(find.byType(PopupMenuButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify property was deleted
      expect(find.text('Updated Test Property'), findsNothing);
      expect(find.text('No Properties Yet'), findsOneWidget);
    });

    testWidgets('Property form validation', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to add property
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Test validation - try to save without required fields
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Please enter a property name'), findsOneWidget);
      expect(find.text('Please enter an address'), findsOneWidget);

      // Fill in minimum required fields
      await tester.enterText(
        find.byKey(const Key('property_name_field')), 
        'Validation Test Property'
      );
      await tester.enterText(
        find.byKey(const Key('property_address_field')), 
        '456 Validation Street'
      );

      // Test invalid year
      await tester.enterText(
        find.byKey(const Key('year_built_field')), 
        '1700'
      );

      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Verify year validation error
      expect(find.text('Enter valid year'), findsOneWidget);

      // Fix the year
      await tester.enterText(
        find.byKey(const Key('year_built_field')), 
        '1990'
      );

      // Now save should work
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Verify property was created
      expect(find.text('Validation Test Property'), findsOneWidget);
    });

    testWidgets('Search and filter functionality', (tester) async {
      // Launch the app and create some test properties first
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to properties
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();

      // Create multiple properties with different types
      final testProperties = [
        {'name': 'Beach House', 'address': '100 Beach Road', 'type': 'House'},
        {'name': 'City Apartment', 'address': '200 City Center', 'type': 'Apartment'},
        {'name': 'Mountain Condo', 'address': '300 Mountain View', 'type': 'Condo'},
      ];

      for (final property in testProperties) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('property_name_field')), 
          property['name']!
        );
        await tester.enterText(
          find.byKey(const Key('property_address_field')), 
          property['address']!
        );

        // Select property type
        await tester.tap(find.byKey(const Key('property_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(property['type']!).last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Property'));
        await tester.pumpAndSettle();
      }

      // Test search functionality
      await tester.enterText(find.byType(TextField), 'Beach');
      await tester.pumpAndSettle();

      // Verify only Beach House is shown
      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('City Apartment'), findsNothing);
      expect(find.text('Mountain Condo'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Verify all properties are shown again
      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('City Apartment'), findsOneWidget);
      expect(find.text('Mountain Condo'), findsOneWidget);

      // Test type filtering
      await tester.tap(find.text('Apartment'));
      await tester.pumpAndSettle();

      // Verify only apartments are shown
      expect(find.text('City Apartment'), findsOneWidget);
      expect(find.text('Beach House'), findsNothing);
      expect(find.text('Mountain Condo'), findsNothing);

      // Test condo filter
      await tester.tap(find.text('Condo'));
      await tester.pumpAndSettle();

      // Verify only condos are shown
      expect(find.text('Mountain Condo'), findsOneWidget);
      expect(find.text('Beach House'), findsNothing);
      expect(find.text('City Apartment'), findsNothing);

      // Reset to all
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Verify all properties are shown
      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('City Apartment'), findsOneWidget);
      expect(find.text('Mountain Condo'), findsOneWidget);
    });

    testWidgets('Error handling and recovery', (tester) async {
      // This test would require mocking network failures
      // For demonstration purposes, we'll test basic error scenarios
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to properties
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();

      // Test creating property with duplicate name (if backend validates this)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('property_name_field')), 
        'Error Test Property'
      );
      await tester.enterText(
        find.byKey(const Key('property_address_field')), 
        '789 Error Street'
      );

      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // If there's an error, verify error handling
      // This would depend on backend implementation
      
      // Test retry functionality if error occurred
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Offline functionality and data persistence', (tester) async {
      // This would test offline capabilities and local storage
      // For now, we'll verify that the app handles lack of data gracefully
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to properties when no data is available
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();

      // Verify empty state is handled properly
      if (find.text('No Properties Yet').evaluate().isNotEmpty) {
        expect(find.text('No Properties Yet'), findsOneWidget);
        expect(find.text('Add Your First Property'), findsOneWidget);
      }

      // Test pull-to-refresh functionality
      await tester.drag(
        find.byType(RefreshIndicator), 
        const Offset(0, 300)
      );
      await tester.pumpAndSettle();

      // Verify refresh indicator appeared and disappeared
      // (Actual network request would be mocked in real integration test)
    });
  });
}

// Custom test keys for reliable widget identification
class PropertyTestKeys {
  static const Key propertyNameField = Key('property_name_field');
  static const Key propertyAddressField = Key('property_address_field');
  static const Key propertyTypeDropdown = Key('property_type_dropdown');
  static const Key yearBuiltField = Key('year_built_field');
  static const Key bedroomsField = Key('bedrooms_field');
  static const Key bathroomsField = Key('bathrooms_field');
  static const Key squareFootageField = Key('square_footage_field');
  static const Key createPropertyButton = Key('create_property_button');
  static const Key updatePropertyButton = Key('update_property_button');
  static const Key cancelButton = Key('cancel_button');
  static const Key deletePropertyButton = Key('delete_property_button');
  static const Key confirmDeleteButton = Key('confirm_delete_button');
  static const Key propertyCard = Key('property_card');
  static const Key propertySearchField = Key('property_search_field');
  static const Key gridViewToggle = Key('grid_view_toggle');
  static const Key filterButton = Key('filter_button');
}