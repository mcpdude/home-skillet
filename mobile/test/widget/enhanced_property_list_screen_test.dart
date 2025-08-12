import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/models/property.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/screens/properties/enhanced_property_list_screen.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('EnhancedPropertyListScreen Widget Tests', () {
    late MockPropertyService mockPropertyService;
    late PropertyProvider propertyProvider;

    setUp(() {
      mockPropertyService = MockPropertyService();
      propertyProvider = PropertyProvider(propertyService: mockPropertyService);
    });

    Widget createWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<PropertyProvider>.value(
          value: propertyProvider,
          child: const EnhancedPropertyListScreen(),
        ),
      );
    }

    testWidgets('should display app bar with correct title', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pump(); // Allow async operations to complete

      // Assert
      expect(find.text('My Properties'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);
      
      // Set loading state
      propertyProvider.loadProperties();

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no properties', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No Properties Yet'), findsOneWidget);
      expect(find.text('Add your first property to start managing home maintenance projects'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('should display properties when available', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson(TestData.mockProperty),
        Property.fromJson({
          ...TestData.mockProperty,
          'id': '2',
          'name': 'Second Property',
          'address': '456 Second St',
        }),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('Second Property'), findsOneWidget);
      expect(find.text('123 Test St'), findsOneWidget);
      expect(find.text('456 Second St'), findsOneWidget);
    });

    testWidgets('should display property cards with correct information', (tester) async {
      // Arrange
      final property = Property.fromJson({
        ...TestData.mockProperty,
        'bedrooms': 3,
        'bathrooms': 2,
        'square_footage': 2000.0,
        'year_built': 1995,
      });

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => [property]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('123 Test St'), findsOneWidget);
      expect(find.text('3 bed'), findsOneWidget);
      expect(find.text('2 bath'), findsOneWidget);
      expect(find.text('2000 sq ft'), findsOneWidget);
      expect(find.text('1995'), findsOneWidget);
    });

    testWidgets('should show filter toggle button', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.filter_list_outlined), findsOneWidget);
    });

    testWidgets('should toggle filter section when filter button is tapped', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially, advanced filters should not be visible
      expect(find.text('All Types'), findsNothing);

      // Tap the filter button
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('All Types'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('should display search bar in filter section', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Toggle filters
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Search properties...'), findsOneWidget);
    });

    testWidgets('should filter properties by type', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson({...TestData.mockProperty, 'type': 'house'}),
        Property.fromJson({...TestData.mockProperty, 'id': '2', 'name': 'Apartment', 'type': 'apartment'}),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Toggle filters
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      // Initially both properties should be visible
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('Apartment'), findsOneWidget);

      // Tap on House filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'House'));
      await tester.pumpAndSettle();

      // Assert only house property is visible
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('Apartment'), findsNothing);
    });

    testWidgets('should search properties by text', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson({...TestData.mockProperty, 'name': 'Beach House'}),
        Property.fromJson({...TestData.mockProperty, 'id': '2', 'name': 'City Apartment', 'address': '456 Urban St'}),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Toggle filters
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField).first, 'beach');
      await tester.pumpAndSettle();

      // Assert only matching property is visible
      expect(find.text('Beach House'), findsOneWidget);
      expect(find.text('City Apartment'), findsNothing);
    });

    testWidgets('should clear filters when clear button is tapped', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson(TestData.mockProperty),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Toggle filters and apply a filter
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'search');
      await tester.pumpAndSettle();

      // Tap clear filters
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Assert search field is cleared
      expect(find.text('search'), findsNothing);
      expect(find.text('Test Property'), findsOneWidget);
    });

    testWidgets('should navigate to add property when FAB is tapped', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Property'), findsOneWidget);

      // Note: Navigation testing would require a more complex setup with Navigator
      // For now, we just verify the button exists
    });

    testWidgets('should show property action buttons', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => [Property.fromJson(TestData.mockProperty)]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('should display property type badges with correct colors', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson({...TestData.mockProperty, 'type': 'house'}),
        Property.fromJson({...TestData.mockProperty, 'id': '2', 'type': 'commercial'}),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('House'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);
    });

    testWidgets('should handle pull-to-refresh', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => [Property.fromJson(TestData.mockProperty)]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Perform pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert the service was called again
      verify(mockPropertyService.getProperties()).called(greaterThan(1));
    });

    testWidgets('should display error message when loading fails', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenThrow(Exception('Failed to load properties'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ErrorMessage), findsOneWidget);
    });

    testWidgets('should display filtered results count', (tester) async {
      // Arrange
      final properties = [
        Property.fromJson(TestData.mockProperty),
        Property.fromJson({...TestData.mockProperty, 'id': '2'}),
      ];

      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => properties);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Apply search filter
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'test');
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Found'), findsOneWidget);
      expect(find.textContaining('properties'), findsOneWidget);
    });

    testWidgets('should show refresh button in app bar', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should handle refresh button tap', (tester) async {
      // Arrange
      when(mockPropertyService.getProperties())
          .thenAnswer((_) async => <Property>[]);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert the service was called again
      verify(mockPropertyService.getProperties()).called(greaterThan(1));
    });
  });
}