import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/models/property.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('PropertyProvider', () {
    late PropertyProvider propertyProvider;
    late MockPropertyService mockPropertyService;

    setUp(() {
      mockPropertyService = MockPropertyService();
      propertyProvider = PropertyProvider(propertyService: mockPropertyService);
    });

    group('loadProperties', () {
      test('should load properties successfully', () async {
        // Arrange
        final properties = [
          Property.fromJson(TestData.mockProperty),
          Property.fromJson({
            ...TestData.mockProperty,
            'id': '2',
            'name': 'Second Property',
            'type': 'apartment',
          }),
        ];

        when(mockPropertyService.getProperties())
            .thenAnswer((_) async => properties);

        // Act
        await propertyProvider.loadProperties();

        // Assert
        expect(propertyProvider.properties, equals(properties));
        expect(propertyProvider.allProperties, equals(properties));
        expect(propertyProvider.isLoading, isFalse);
        expect(propertyProvider.errorMessage, isNull);
        expect(propertyProvider.selectedProperty, equals(properties.first));
      });

      test('should set error message when loading fails', () async {
        // Arrange
        when(mockPropertyService.getProperties())
            .thenThrow(Exception('Failed to load properties'));

        // Act
        await propertyProvider.loadProperties();

        // Assert
        expect(propertyProvider.properties, isEmpty);
        expect(propertyProvider.isLoading, isFalse);
        expect(propertyProvider.errorMessage, contains('Failed to load properties'));
      });

      test('should set loading state correctly', () async {
        // Arrange
        when(mockPropertyService.getProperties())
            .thenAnswer((_) async {
          // Verify loading state is true during operation
          expect(propertyProvider.isLoading, isTrue);
          return <Property>[];
        });

        // Act
        await propertyProvider.loadProperties();

        // Assert
        expect(propertyProvider.isLoading, isFalse);
      });
    });

    group('createProperty', () {
      test('should create property successfully', () async {
        // Arrange
        final property = Property.fromJson(TestData.mockProperty);
        when(mockPropertyService.createProperty(any))
            .thenAnswer((_) async => property);

        // Act
        final result = await propertyProvider.createProperty(property);

        // Assert
        expect(result, isTrue);
        expect(propertyProvider.allProperties, contains(property));
        expect(propertyProvider.properties, contains(property));
        expect(propertyProvider.selectedProperty, equals(property));
        verify(mockPropertyService.createProperty(any)).called(1);
      });

      test('should return false and set error when creation fails', () async {
        // Arrange
        final property = Property.fromJson(TestData.mockProperty);
        when(mockPropertyService.createProperty(any))
            .thenThrow(Exception('Failed to create property'));

        // Act
        final result = await propertyProvider.createProperty(property);

        // Assert
        expect(result, isFalse);
        expect(propertyProvider.errorMessage, contains('Failed to create property'));
      });
    });

    group('updateProperty', () {
      test('should update property successfully', () async {
        // Arrange
        final originalProperty = Property.fromJson(TestData.mockProperty);
        final updatedProperty = originalProperty.copyWith(name: 'Updated Property');
        
        // Set up initial state
        propertyProvider.allProperties.add(originalProperty);
        propertyProvider.selectedProperty = originalProperty;

        when(mockPropertyService.updateProperty(any))
            .thenAnswer((_) async => updatedProperty);

        // Act
        final result = await propertyProvider.updateProperty(updatedProperty);

        // Assert
        expect(result, isTrue);
        expect(propertyProvider.allProperties.first.name, equals('Updated Property'));
        expect(propertyProvider.selectedProperty?.name, equals('Updated Property'));
        verify(mockPropertyService.updateProperty(any)).called(1);
      });

      test('should return false and set error when update fails', () async {
        // Arrange
        final property = Property.fromJson(TestData.mockProperty);
        when(mockPropertyService.updateProperty(any))
            .thenThrow(Exception('Failed to update property'));

        // Act
        final result = await propertyProvider.updateProperty(property);

        // Assert
        expect(result, isFalse);
        expect(propertyProvider.errorMessage, contains('Failed to update property'));
      });
    });

    group('deleteProperty', () {
      test('should delete property successfully', () async {
        // Arrange
        final property = Property.fromJson(TestData.mockProperty);
        propertyProvider.allProperties.add(property);
        propertyProvider.selectedProperty = property;

        when(mockPropertyService.deleteProperty(any))
            .thenAnswer((_) async {});

        // Act
        final result = await propertyProvider.deleteProperty(property.id);

        // Assert
        expect(result, isTrue);
        expect(propertyProvider.allProperties, isEmpty);
        expect(propertyProvider.selectedProperty, isNull);
        verify(mockPropertyService.deleteProperty(property.id)).called(1);
      });

      test('should return false and set error when deletion fails', () async {
        // Arrange
        const propertyId = '1';
        when(mockPropertyService.deleteProperty(any))
            .thenThrow(Exception('Failed to delete property'));

        // Act
        final result = await propertyProvider.deleteProperty(propertyId);

        // Assert
        expect(result, isFalse);
        expect(propertyProvider.errorMessage, contains('Failed to delete property'));
      });

      test('should update selected property when deleted property was selected', () async {
        // Arrange
        final property1 = Property.fromJson(TestData.mockProperty);
        final property2 = Property.fromJson({...TestData.mockProperty, 'id': '2'});
        
        propertyProvider.allProperties.addAll([property1, property2]);
        propertyProvider.selectedProperty = property1;

        when(mockPropertyService.deleteProperty(any))
            .thenAnswer((_) async {});

        // Act
        await propertyProvider.deleteProperty(property1.id);

        // Assert
        expect(propertyProvider.selectedProperty, equals(property2));
      });
    });

    group('search and filter functionality', () {
      setUp(() {
        final properties = [
          Property.fromJson({
            ...TestData.mockProperty,
            'id': '1',
            'name': 'Main House',
            'address': '123 Main St',
            'type': 'house',
          }),
          Property.fromJson({
            ...TestData.mockProperty,
            'id': '2',
            'name': 'Downtown Apartment',
            'address': '456 Downtown Ave',
            'type': 'apartment',
          }),
          Property.fromJson({
            ...TestData.mockProperty,
            'id': '3',
            'name': 'Beach House',
            'address': '789 Beach Rd',
            'type': 'house',
          }),
        ];

        // Manually set the properties to simulate loaded state by mocking the service
        when(mockPropertyService.getProperties())
            .thenAnswer((_) async => properties);
        
        // Load properties to populate the provider
        await propertyProvider.loadProperties();
      });

      test('should filter properties by search query', () {
        // Act
        propertyProvider.searchProperties('house');

        // Assert
        expect(propertyProvider.properties.length, equals(2));
        expect(propertyProvider.properties.every((p) => 
          p.name.toLowerCase().contains('house') || 
          p.address.toLowerCase().contains('house')), isTrue);
      });

      test('should filter properties by type', () {
        // Act
        propertyProvider.filterByType(PropertyType.apartment);

        // Assert
        expect(propertyProvider.properties.length, equals(1));
        expect(propertyProvider.properties.first.type, equals(PropertyType.apartment));
      });

      test('should combine search and type filters', () {
        // Act
        propertyProvider.searchProperties('main');
        propertyProvider.filterByType(PropertyType.house);

        // Assert
        expect(propertyProvider.properties.length, equals(1));
        expect(propertyProvider.properties.first.name, contains('Main'));
        expect(propertyProvider.properties.first.type, equals(PropertyType.house));
      });

      test('should clear all filters', () {
        // Arrange
        propertyProvider.searchProperties('house');
        propertyProvider.filterByType(PropertyType.apartment);
        
        // Act
        propertyProvider.clearFilters();

        // Assert
        expect(propertyProvider.properties.length, equals(3));
        expect(propertyProvider.searchQuery, isEmpty);
        expect(propertyProvider.selectedTypeFilter, isNull);
        expect(propertyProvider.hasFilters, isFalse);
      });

      test('should return correct properties count by type', () {
        // Act
        final counts = propertyProvider.getPropertiesCountByType();

        // Assert
        expect(counts[PropertyType.house], equals(2));
        expect(counts[PropertyType.apartment], equals(1));
        expect(counts[PropertyType.condo], equals(0));
      });

      test('should perform local search without API call', () {
        // Act
        final results = propertyProvider.searchPropertiesLocal('downtown');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.name, contains('Downtown'));
      });

      test('should get properties by type', () {
        // Act
        final houseProperties = propertyProvider.getPropertiesByType(PropertyType.house);

        // Assert
        expect(houseProperties.length, equals(2));
        expect(houseProperties.every((p) => p.type == PropertyType.house), isTrue);
      });
    });

    group('property selection', () {
      test('should select property correctly', () {
        // Arrange
        final property = Property.fromJson(TestData.mockProperty);

        // Act
        propertyProvider.selectProperty(property);

        // Assert
        expect(propertyProvider.selectedProperty, equals(property));
      });

      test('should get property by ID', () {
        // Arrange
        final property = Property.fromJson(TestData.mockProperty);
        propertyProvider.allProperties.add(property);

        // Act
        final result = propertyProvider.getPropertyById(property.id);

        // Assert
        expect(result, equals(property));
      });

      test('should return null for non-existent property ID', () {
        // Act
        final result = propertyProvider.getPropertyById('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('state management', () {
      test('should notify listeners on state changes', () {
        // Arrange
        var notificationCount = 0;
        propertyProvider.addListener(() => notificationCount++);

        // Act
        propertyProvider.searchProperties('test');

        // Assert
        expect(notificationCount, greaterThan(0));
      });

      test('should handle edge cases gracefully', () {
        // Test empty search query
        propertyProvider.searchProperties('');
        expect(propertyProvider.searchQuery, isEmpty);

        // Test null type filter
        propertyProvider.filterByType(null);
        expect(propertyProvider.selectedTypeFilter, isNull);

        // Test clearing filters when none are set
        propertyProvider.clearFilters();
        expect(propertyProvider.hasFilters, isFalse);
      });

      test('should maintain data integrity during operations', () async {
        // Arrange
        final originalProperties = [
          Property.fromJson(TestData.mockProperty),
          Property.fromJson({...TestData.mockProperty, 'id': '2'}),
        ];

        when(mockPropertyService.getProperties())
            .thenAnswer((_) async => originalProperties);

        // Act
        await propertyProvider.loadProperties();
        propertyProvider.searchProperties('test');

        // Assert
        expect(propertyProvider.allProperties, equals(originalProperties));
        expect(propertyProvider.allProperties.length, equals(2));
      });
    });

    group('error scenarios', () {
      test('should handle concurrent operations gracefully', () async {
        // Arrange
        when(mockPropertyService.getProperties())
            .thenAnswer((_) async => [Property.fromJson(TestData.mockProperty)]);
        
        when(mockPropertyService.createProperty(any))
            .thenAnswer((_) async => Property.fromJson(TestData.mockProperty));

        // Act - simulate concurrent operations
        final futures = [
          propertyProvider.loadProperties(),
          propertyProvider.createProperty(Property.fromJson(TestData.mockProperty)),
        ];

        await Future.wait(futures);

        // Assert - should not crash and maintain consistent state
        expect(propertyProvider.allProperties.isNotEmpty, isTrue);
        expect(propertyProvider.isLoading, isFalse);
      });

      test('should reset loading state even if operation fails', () async {
        // Arrange
        when(mockPropertyService.getProperties())
            .thenThrow(Exception('Network error'));

        // Act
        await propertyProvider.loadProperties();

        // Assert
        expect(propertyProvider.isLoading, isFalse);
        expect(propertyProvider.errorMessage, isNotNull);
      });
    });
  });
}