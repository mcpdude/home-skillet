import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/models/property.dart';
import 'package:home_skillet_mobile/models/auth_models.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/screens/properties/enhanced_property_list_screen.dart';
import 'package:home_skillet_mobile/screens/properties/add_edit_property_screen.dart';
import 'package:home_skillet_mobile/screens/properties/property_detail_screen.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Property Management Integration Tests', () {
    late MockPropertyService mockPropertyService;
    late MockAuthService mockAuthService;
    late PropertyProvider propertyProvider;
    late AuthProvider authProvider;

    setUp(() {
      mockPropertyService = MockPropertyService();
      mockAuthService = MockAuthService();
      propertyProvider = PropertyProvider(propertyService: mockPropertyService);
      authProvider = AuthProvider(authService: mockAuthService);

      // Set up authenticated user
      authProvider.currentUser = const User(
        id: 'user123',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        userType: UserType.propertyOwner,
      );
    });

    Widget createPropertyApp() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<PropertyProvider>.value(value: propertyProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const EnhancedPropertyListScreen(),
        ),
      );
    }

    testWidgets('Complete property creation workflow', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);
      when(mockPropertyService.createProperty(any))
          .thenAnswer((_) async => Property.fromJson(TestData.mockProperty));

      // Act & Assert - Start with empty property list
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      expect(find.text('No Properties Yet'), findsOneWidget);
      expect(find.text('Add Property'), findsOneWidget);

      // Navigate to add property screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Property'), findsOneWidget); // App bar title
      expect(find.text('Create Property'), findsOneWidget); // Button text

      // Fill out the property form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'New Test Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 Integration Test St',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description').first,
        'A beautiful test property',
      );

      // Select property type
      await tester.tap(find.byType(DropdownButtonFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('House'));
      await tester.pumpAndSettle();

      // Fill optional fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year Built').first,
        '2020',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Square Footage').first,
        '2500',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bedrooms').first,
        '4',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bathrooms').first,
        '3',
      );

      // Submit the form
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Verify property was created
      verify(mockPropertyService.createProperty(any)).called(1);
    });

    testWidgets('Property listing with search and filter workflow', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson({
          ...TestData.mockProperty,
          'name': 'Beach House',
          'type': 'house',
          'address': '123 Beach Rd',
        }),
        Property.fromJson({
          ...TestData.mockProperty,
          'id': '2',
          'name': 'Downtown Apartment',
          'type': 'apartment',
          'address': '456 Downtown Ave',
        }),
        Property.fromJson({
          ...TestData.mockProperty,
          'id': '3',
          'name': 'Commercial Office',
          'type': 'commercial',
          'address': '789 Business St',
        }),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act & Assert - View all properties
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('Downtown Apartment'), findsOneWidget);
      expect(find.text('Commercial Office'), findsOneWidget);

      // Test search functionality
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'beach');
      await tester.pumpAndSettle();

      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('Downtown Apartment'), findsNothing);
      expect(find.text('Commercial Office'), findsNothing);
      expect(find.textContaining('Found 1'), findsOneWidget);

      // Clear search and test type filter
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('Downtown Apartment'), findsOneWidget);
      expect(find.text('Commercial Office'), findsOneWidget);

      // Filter by apartment type
      await tester.tap(find.widgetWithText(FilterChip, 'Apartment'));
      await tester.pumpAndSettle();

      expect(find.text('Beach House'), findsNothing);
      expect(find.text('Downtown Apartment'), findsOneWidget);
      expect(find.text('Commercial Office'), findsNothing);

      // Test pull-to-refresh
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      verify(mockPropertyService.getProperties()).called(greaterThan(1));
    });

    testWidgets('Property detail view and edit workflow', (tester) async {
      // Arrange
      final property = Property.fromJson({
        ...TestData.mockProperty,
        'name': 'Editable Property',
        'address': '123 Edit St',
        'description': 'A property to edit',
        'bedrooms': 3,
        'bathrooms': 2,
      });

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => [property]);
      when(mockPropertyService.updateProperty(any))
          .thenAnswer((_) async => property.copyWith(name: 'Updated Property'));

      propertyProvider.allProperties.add(property);

      // Act & Assert - Navigate to detail screen
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      // Tap on property to view details
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.text('Editable Property'), findsOneWidget);
      expect(find.text('123 Edit St'), findsOneWidget);
      expect(find.text('A property to edit'), findsOneWidget);

      // Test edit functionality
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Property'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Property'), findsOneWidget); // App bar title
      expect(find.text('Update Property'), findsOneWidget); // Button text
      expect(find.byIcon(Icons.delete), findsOneWidget); // Delete button

      // Modify property name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'Updated Property',
      );

      // Save changes
      await tester.tap(find.text('Update Property'));
      await tester.pumpAndSettle();

      verify(mockPropertyService.updateProperty(any)).called(1);
    });

    testWidgets('Property deletion workflow', (tester) async {
      // Arrange
      final property = Property.fromJson(TestData.mockProperty);
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => [property]);
      when(mockPropertyService.deleteProperty(any))
          .thenAnswer((_) async {});

      propertyProvider.allProperties.add(property);

      // Act & Assert - Navigate to edit screen
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Property'));
      await tester.pumpAndSettle();

      // Trigger delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete Property'), findsOneWidget);
      expect(find.text('Are you sure you want to delete'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(mockPropertyService.deleteProperty(property.id)).called(1);
    });

    testWidgets('Property form validation workflow', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act & Assert - Test form validation
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsWidgets);

      // Fill name but not address
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'Test Property',
      );
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget); // Only address now

      // Test invalid year
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 Test St',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year Built').first,
        '1500', // Invalid year
      );
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      expect(find.text('Enter valid year'), findsOneWidget);

      // Fix year and try again
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year Built').first,
        '2020',
      );
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // No validation errors should remain
      expect(find.text('This field is required'), findsNothing);
      expect(find.text('Enter valid year'), findsNothing);
    });

    testWidgets('Property creation with error handling workflow', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);
      when(mockPropertyService.createProperty(any))
          .thenThrow(Exception('Server error'));

      // Act & Assert - Test error handling
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill valid form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'Test Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 Test St',
      );

      // Submit and expect error
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      expect(find.text('Error: Exception: Server error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Close error message
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Error: Exception: Server error'), findsNothing);
    });

    testWidgets('Property type filtering workflow', (tester) async {
      // Arrange
      final properties = PropertyType.values.map((type) => 
        Property.fromJson({
          ...TestData.mockProperty,
          'id': type.name,
          'name': '${type.name} Property',
          'type': type.name,
        })
      ).toList();

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act & Assert - Test all property type filters
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      // Test each property type filter
      for (final type in PropertyType.values) {
        final typeName = type.name[0].toUpperCase() + type.name.substring(1);
        
        // Skip if type name doesn't match expected format
        String displayName;
        switch (type) {
          case PropertyType.house:
            displayName = 'House';
            break;
          case PropertyType.apartment:
            displayName = 'Apartment';
            break;
          case PropertyType.condo:
            displayName = 'Condo';
            break;
          case PropertyType.townhouse:
            displayName = 'Townhouse';
            break;
          case PropertyType.commercial:
            displayName = 'Commercial';
            break;
          case PropertyType.other:
            displayName = 'Other';
            break;
        }

        await tester.tap(find.widgetWithText(FilterChip, displayName));
        await tester.pumpAndSettle();

        // Should show only properties of this type
        expect(find.text('${type.name} Property'), findsOneWidget);
        expect(find.textContaining('Found 1'), findsOneWidget);

        // Clear filter for next iteration
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('End-to-end property management workflow', (tester) async {
      // Arrange - Start with empty list
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      final createdProperty = Property.fromJson({
        ...TestData.mockProperty,
        'name': 'End-to-End Property',
        'address': '123 E2E St',
      });

      when(mockPropertyService.createProperty(any))
          .thenAnswer((_) async => createdProperty);
      when(mockPropertyService.updateProperty(any))
          .thenAnswer((_) async => createdProperty.copyWith(name: 'Updated E2E Property'));
      when(mockPropertyService.deleteProperty(any))
          .thenAnswer((_) async {});

      // Act & Assert - Complete workflow
      await tester.pumpWidget(createPropertyApp());
      await tester.pumpAndSettle();

      // 1. Start with empty state
      expect(find.text('No Properties Yet'), findsOneWidget);

      // 2. Create new property
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'End-to-End Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 E2E St',
      );

      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // 3. Verify creation and navigate back
      verify(mockPropertyService.createProperty(any)).called(1);

      // Simulate successful creation by adding property to provider
      propertyProvider.allProperties.add(createdProperty);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 4. View property in list
      expect(find.text('End-to-End Property'), findsOneWidget);
      expect(find.text('123 E2E St'), findsOneWidget);

      // 5. Navigate to detail screen
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.text('End-to-End Property'), findsOneWidget);

      // 6. Edit property
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Property'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'Updated E2E Property',
      );

      await tester.tap(find.text('Update Property'));
      await tester.pumpAndSettle();

      verify(mockPropertyService.updateProperty(any)).called(1);

      // 7. Delete property
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(mockPropertyService.deleteProperty(createdProperty.id)).called(1);

      // Workflow complete - all major operations tested
    });
  });
}