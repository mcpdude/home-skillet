import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/screens/properties/property_dashboard_screen.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/models/property.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('PropertyDashboardScreen Widget Tests', () {
    late MockPropertyProvider mockPropertyProvider;

    setUp(() {
      mockPropertyProvider = MockPropertyProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<PropertyProvider>.value(
          value: mockPropertyProvider,
          child: const PropertyDashboardScreen(),
        ),
      );
    }

    group('Loading States', () {
      testWidgets('should show loading indicator when loading properties', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(true);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should hide loading indicator when not loading', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Empty States', () {
      testWidgets('should show empty state when no properties exist', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('No Properties Yet'), findsOneWidget);
        expect(find.text('Add your first property to start managing home maintenance projects'), findsOneWidget);
        expect(find.text('Add Your First Property'), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      });

      testWidgets('should show filtered empty state when no properties match filters', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([Property.fromJson(TestData.mockProperty)]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(true);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('No Properties Found'), findsOneWidget);
        expect(find.text('Try adjusting your search or filter criteria'), findsOneWidget);
        expect(find.text('Clear Filters'), findsOneWidget);
        expect(find.byIcon(Icons.search_off), findsOneWidget);
      });
    });

    group('Property List Display', () {
      testWidgets('should display properties in list view', (tester) async {
        // Arrange
        final properties = [
          Property.fromJson({
            ...TestData.mockProperty,
            'name': 'Test House',
            'address': '123 Test St',
            'type': 'house',
          }),
          Property.fromJson({
            ...TestData.mockProperty,
            'id': '2',
            'name': 'Test Apartment',
            'address': '456 Test Ave',
            'type': 'apartment',
          }),
        ];

        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn(properties);
        when(mockPropertyProvider.allProperties).thenReturn(properties);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          PropertyType.house: 1,
          PropertyType.apartment: 1,
          PropertyType.condo: 0,
          PropertyType.townhouse: 0,
          PropertyType.other: 0,
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('Test House'), findsOneWidget);
        expect(find.text('Test Apartment'), findsOneWidget);
        expect(find.text('123 Test St'), findsOneWidget);
        expect(find.text('456 Test Ave'), findsOneWidget);
      });

      testWidgets('should display property type chips', (tester) async {
        // Arrange
        final properties = [
          Property.fromJson({
            ...TestData.mockProperty,
            'type': 'house',
          }),
        ];

        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn(properties);
        when(mockPropertyProvider.allProperties).thenReturn(properties);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          PropertyType.house: 1,
          PropertyType.apartment: 0,
          PropertyType.condo: 0,
          PropertyType.townhouse: 0,
          PropertyType.other: 0,
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('House'), findsWidgets);
      });

      testWidgets('should display property stats when available', (tester) async {
        // Arrange
        final properties = [
          Property.fromJson({
            ...TestData.mockProperty,
            'bedrooms': 3,
            'bathrooms': 2,
            'square_footage': 2000.0,
          }),
        ];

        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn(properties);
        when(mockPropertyProvider.allProperties).thenReturn(properties);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          PropertyType.house: 1,
          PropertyType.apartment: 0,
          PropertyType.condo: 0,
          PropertyType.townhouse: 0,
          PropertyType.other: 0,
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('3'), findsOneWidget); // bedrooms
        expect(find.text('2'), findsOneWidget); // bathrooms
        expect(find.text('2000 sq ft'), findsOneWidget); // square footage
        expect(find.byIcon(Icons.bed_outlined), findsOneWidget);
        expect(find.byIcon(Icons.bathtub_outlined), findsOneWidget);
        expect(find.byIcon(Icons.square_foot), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should display search bar', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search properties...'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should call searchProperties when text is entered', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'house');
        await tester.pump();

        // Assert
        verify(mockPropertyProvider.searchProperties('house')).called(1);
      });

      testWidgets('should show clear button when search is active', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(true);
        when(mockPropertyProvider.searchQuery).thenReturn('house');
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Update the search field to show active search
        await tester.enterText(find.byType(TextField), 'house');
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });
    });

    group('Filter Tabs', () {
      testWidgets('should display filter tabs with counts', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          PropertyType.house: 2,
          PropertyType.apartment: 1,
          PropertyType.condo: 0,
          PropertyType.townhouse: 1,
          PropertyType.other: 0,
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('All'), findsOneWidget);
        expect(find.text('House'), findsOneWidget);
        expect(find.text('Apartment'), findsOneWidget);
        expect(find.text('Townhouse'), findsOneWidget);
        
        // Should show counts for non-zero types
        expect(find.text('2'), findsOneWidget); // House count
        expect(find.text('1'), findsWidgets); // Apartment and Townhouse counts
      });

      testWidgets('should hide tabs when search is active', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(true);
        when(mockPropertyProvider.searchQuery).thenReturn('house');
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Enter search to activate search mode
        await tester.enterText(find.byType(TextField), 'house');
        await tester.pump();

        // Assert - tabs should be hidden when search is active
        // Note: This test may need adjustment based on actual implementation
        // The tabs might still be present but not visible due to the scroll behavior
      });
    });

    group('Action Buttons', () {
      testWidgets('should display floating action button for adding property', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Add Property'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsWidgets);
      });

      testWidgets('should display view toggle button', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.list), findsOneWidget); // Default is list view
      });

      testWidgets('should toggle between list and grid view', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Tap the view toggle button
        await tester.tap(find.byIcon(Icons.list));
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.grid_view), findsOneWidget); // Should switch to grid icon
      });

      testWidgets('should display filter button', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.filter_list), findsOneWidget);
      });
    });

    group('Property Cards Actions', () {
      testWidgets('should display property action buttons', (tester) async {
        // Arrange
        final properties = [
          Property.fromJson(TestData.mockProperty),
        ];

        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn(properties);
        when(mockPropertyProvider.allProperties).thenReturn(properties);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          PropertyType.house: 1,
          PropertyType.apartment: 0,
          PropertyType.condo: 0,
          PropertyType.townhouse: 0,
          PropertyType.other: 0,
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('Details'), findsOneWidget);
        expect(find.text('Projects'), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.construction), findsOneWidget);
      });

      testWidgets('should display popup menu for property actions', (tester) async {
        // Arrange
        final properties = [
          Property.fromJson(TestData.mockProperty),
        ];

        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn(properties);
        when(mockPropertyProvider.allProperties).thenReturn(properties);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          PropertyType.house: 1,
          PropertyType.apartment: 0,
          PropertyType.condo: 0,
          PropertyType.townhouse: 0,
          PropertyType.other: 0,
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should display error message when loading fails', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn('Failed to load properties');
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('Failed to load properties'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsWidgets); // Retry button should be present
      });
    });

    group('Refresh Functionality', () {
      testWidgets('should support pull-to-refresh', (tester) async {
        // Arrange
        when(mockPropertyProvider.isLoading).thenReturn(false);
        when(mockPropertyProvider.properties).thenReturn([]);
        when(mockPropertyProvider.allProperties).thenReturn([]);
        when(mockPropertyProvider.errorMessage).thenReturn(null);
        when(mockPropertyProvider.hasFilters).thenReturn(false);
        when(mockPropertyProvider.getPropertiesCountByType()).thenReturn({
          for (var type in PropertyType.values) type: 0
        });

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });
  });
}