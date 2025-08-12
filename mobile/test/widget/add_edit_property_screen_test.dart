import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/models/property.dart';
import 'package:home_skillet_mobile/models/auth_models.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/screens/properties/add_edit_property_screen.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AddEditPropertyScreen Widget Tests', () {
    late MockPropertyService mockPropertyService;
    late MockAuthService mockAuthService;
    late PropertyProvider propertyProvider;
    late AuthProvider authProvider;

    setUp(() {
      mockPropertyService = MockPropertyService();
      mockAuthService = MockAuthService();
      propertyProvider = PropertyProvider(propertyService: mockPropertyService);
      authProvider = AuthProvider(authService: mockAuthService);

      // Set up a mock authenticated user
      authProvider.currentUser = const User(
        id: 'user123',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        userType: UserType.propertyOwner,
      );
    });

    Widget createWidget({String? propertyId, bool isEdit = false}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<PropertyProvider>.value(value: propertyProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: AddEditPropertyScreen(
            propertyId: propertyId,
            isEdit: isEdit,
          ),
        ),
      );
    }

    testWidgets('should display correct title for add mode', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add Property'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display correct title for edit mode', (tester) async {
      // Arrange
      final property = Property.fromJson(TestData.mockProperty);
      propertyProvider.allProperties.add(property);

      // Act
      await tester.pumpWidget(createWidget(propertyId: property.id, isEdit: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Property'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget); // Delete button in edit mode
    });

    testWidgets('should display all required form fields', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(7)); // Name, address, desc, year, sqft, bedrooms, bathrooms
      expect(find.byType(DropdownButtonFormField), findsOneWidget); // Property type
      
      // Check specific field labels
      expect(find.text('Property Name *'), findsOneWidget);
      expect(find.text('Address *'), findsOneWidget);
      expect(find.text('Property Type *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Year Built'), findsOneWidget);
      expect(find.text('Square Footage'), findsOneWidget);
      expect(find.text('Bedrooms'), findsOneWidget);
      expect(find.text('Bathrooms'), findsOneWidget);
    });

    testWidgets('should display property type dropdown options', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap dropdown
      await tester.tap(find.byType(DropdownButtonFormField));
      await tester.pumpAndSettle();

      // Assert all property types are present
      expect(find.text('House'), findsOneWidget);
      expect(find.text('Apartment'), findsOneWidget);
      expect(find.text('Condo'), findsOneWidget);
      expect(find.text('Townhouse'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('should pre-populate form when editing existing property', (tester) async {
      // Arrange
      final property = Property.fromJson({
        ...TestData.mockProperty,
        'name': 'Edit Test Property',
        'address': '789 Edit St',
        'description': 'Edit description',
        'year_built': 2000,
        'square_footage': 1500.0,
        'bedrooms': 2,
        'bathrooms': 1,
      });
      propertyProvider.allProperties.add(property);

      // Act
      await tester.pumpWidget(createWidget(propertyId: property.id, isEdit: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Test Property'), findsOneWidget);
      expect(find.text('789 Edit St'), findsOneWidget);
      expect(find.text('Edit description'), findsOneWidget);
      expect(find.text('2000'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should validate required fields', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap create button without filling required fields
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Assert validation errors appear
      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('should validate numeric fields', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter invalid year
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year Built').first,
        '1500', // Too old
      );
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Assert validation error
      expect(find.text('Enter valid year'), findsOneWidget);
    });

    testWidgets('should display action buttons', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create Property'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show different button text for edit mode', (tester) async {
      // Arrange
      final property = Property.fromJson(TestData.mockProperty);
      propertyProvider.allProperties.add(property);

      // Act
      await tester.pumpWidget(createWidget(propertyId: property.id, isEdit: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Update Property'), findsOneWidget);
    });

    testWidgets('should display image section', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Property Images'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('Add photos to showcase your property'), findsOneWidget);
    });

    testWidgets('should handle image selection', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap add photo button
      await tester.tap(find.text('Add Photo'));
      await tester.pumpAndSettle();

      // Note: Actual image picker testing would require platform channels
      // For now we just verify the button exists and can be tapped
    });

    testWidgets('should create property when form is valid', (tester) async {
      // Arrange
      when(mockPropertyService.createProperty(any))
          .thenAnswer((_) async => Property.fromJson(TestData.mockProperty));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'New Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 New St',
      );

      // Submit form
      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Assert service was called
      verify(mockPropertyService.createProperty(any)).called(1);
    });

    testWidgets('should update property when in edit mode', (tester) async {
      // Arrange
      final property = Property.fromJson(TestData.mockProperty);
      propertyProvider.allProperties.add(property);
      
      when(mockPropertyService.updateProperty(any))
          .thenAnswer((_) async => property);

      // Act
      await tester.pumpWidget(createWidget(propertyId: property.id, isEdit: true));
      await tester.pumpAndSettle();

      // Modify a field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'Updated Property',
      );

      // Submit form
      await tester.tap(find.text('Update Property'));
      await tester.pumpAndSettle();

      // Assert service was called
      verify(mockPropertyService.updateProperty(any)).called(1);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      // Arrange
      final property = Property.fromJson(TestData.mockProperty);
      propertyProvider.allProperties.add(property);

      // Act
      await tester.pumpWidget(createWidget(propertyId: property.id, isEdit: true));
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Delete Property'), findsOneWidget);
      expect(find.text('Are you sure you want to delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should delete property when confirmed', (tester) async {
      // Arrange
      final property = Property.fromJson(TestData.mockProperty);
      propertyProvider.allProperties.add(property);
      
      when(mockPropertyService.deleteProperty(any))
          .thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createWidget(propertyId: property.id, isEdit: true));
      await tester.pumpAndSettle();

      // Tap delete button and confirm
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Assert service was called
      verify(mockPropertyService.deleteProperty(property.id)).called(1);
    });

    testWidgets('should display error message on creation failure', (tester) async {
      // Arrange
      when(mockPropertyService.createProperty(any))
          .thenThrow(Exception('Creation failed'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill required fields and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'New Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 New St',
      );

      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Assert error is displayed
      expect(find.text('Error: Exception: Creation failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should dismiss error message when close button is tapped', (tester) async {
      // Arrange
      when(mockPropertyService.createProperty(any))
          .thenThrow(Exception('Creation failed'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Trigger error
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'New Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 New St',
      );

      await tester.tap(find.text('Create Property'));
      await tester.pumpAndSettle();

      // Close error message
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert error is gone
      expect(find.text('Error: Exception: Creation failed'), findsNothing);
    });

    testWidgets('should enforce input formatters on numeric fields', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Try to enter letters in year field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year Built').first,
        'abc123def',
      );
      await tester.pumpAndSettle();

      // Assert only numbers remain
      expect(find.text('123'), findsOneWidget);
    });

    testWidgets('should limit year built field to 4 digits', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter more than 4 digits
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year Built').first,
        '20231',
      );
      await tester.pumpAndSettle();

      // Assert it's limited to 4 digits
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('should show loading overlay during operations', (tester) async {
      // Arrange - Create a delayed response to see loading state
      when(mockPropertyService.createProperty(any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Property.fromJson(TestData.mockProperty);
      });

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill and submit form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Property Name *').first,
        'New Property',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *').first,
        '123 New St',
      );

      await tester.tap(find.text('Create Property'));
      await tester.pump(); // Don't settle, so we can see loading state

      // Assert loading overlay is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}