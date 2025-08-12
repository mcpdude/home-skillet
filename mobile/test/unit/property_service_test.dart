import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'package:home_skillet_mobile/services/property_service.dart';
import 'package:home_skillet_mobile/models/property.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('PropertyService', () {
    late PropertyService propertyService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      propertyService = PropertyService(httpClient: mockHttpClient);
    });

    group('getProperties', () {
      test('should return list of properties when request is successful', () async {
        // Arrange
        final expectedResponse = Response<List<dynamic>>(
          data: [TestData.mockProperty],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.getProperties();

        // Assert
        expect(result, isA<List<Property>>());
        expect(result.length, equals(1));
        expect(result.first.name, equals('Test Property'));
        expect(result.first.address, equals('123 Test St'));
        
        verify(mockHttpClient.get('v1/properties')).called(1);
      });

      test('should throw exception when request fails', () async {
        // Arrange
        when(mockHttpClient.get(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.getProperties(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to load properties')
          )),
        );
      });
    });

    group('getProperty', () {
      test('should return property when request is successful', () async {
        // Arrange
        const propertyId = '1';
        final expectedResponse = Response<Map<String, dynamic>>(
          data: TestData.mockProperty,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.getProperty(propertyId);

        // Assert
        expect(result, isA<Property>());
        expect(result.id, equals('1'));
        expect(result.name, equals('Test Property'));
        
        verify(mockHttpClient.get('v1/properties/1')).called(1);
      });

      test('should throw exception when property not found', () async {
        // Arrange
        const propertyId = 'nonexistent';
        when(mockHttpClient.get(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.getProperty(propertyId),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to load property')
          )),
        );
      });
    });

    group('createProperty', () {
      test('should return created property when request is successful', () async {
        // Arrange
        final propertyToCreate = Property.fromJson(TestData.mockProperty);
        final expectedResponse = Response<Map<String, dynamic>>(
          data: TestData.mockProperty,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.createProperty(propertyToCreate);

        // Assert
        expect(result, isA<Property>());
        expect(result.name, equals('Test Property'));
        
        verify(mockHttpClient.post('v1/properties', data: anyNamed('data'))).called(1);
      });

      test('should throw exception when validation fails', () async {
        // Arrange
        final propertyToCreate = Property.fromJson(TestData.mockProperty);
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.createProperty(propertyToCreate),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Please check your property information')
          )),
        );
      });
    });

    group('updateProperty', () {
      test('should return updated property when request is successful', () async {
        // Arrange
        final propertyToUpdate = Property.fromJson(TestData.mockProperty);
        final updatedPropertyData = Map<String, dynamic>.from(TestData.mockProperty);
        updatedPropertyData['name'] = 'Updated Property';
        
        final expectedResponse = Response<Map<String, dynamic>>(
          data: updatedPropertyData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.put(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.updateProperty(propertyToUpdate);

        // Assert
        expect(result, isA<Property>());
        expect(result.name, equals('Updated Property'));
        
        verify(mockHttpClient.put('v1/properties/1', data: anyNamed('data'))).called(1);
      });

      test('should throw exception when property not found', () async {
        // Arrange
        final propertyToUpdate = Property.fromJson(TestData.mockProperty);
        when(mockHttpClient.put(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.updateProperty(propertyToUpdate),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Property not found')
          )),
        );
      });
    });

    group('deleteProperty', () {
      test('should complete successfully when deletion is successful', () async {
        // Arrange
        const propertyId = '1';
        final expectedResponse = Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.delete(any))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await propertyService.deleteProperty(propertyId);

        // Assert
        verify(mockHttpClient.delete('v1/properties/1')).called(1);
      });

      test('should throw exception when property not found', () async {
        // Arrange
        const propertyId = 'nonexistent';
        when(mockHttpClient.delete(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.deleteProperty(propertyId),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Property not found')
          )),
        );
      });

      test('should throw exception when property has active projects', () async {
        // Arrange
        const propertyId = '1';
        when(mockHttpClient.delete(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 409,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.deleteProperty(propertyId),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Cannot delete property with active projects')
          )),
        );
      });
    });

    group('uploadPropertyImage', () {
      test('should return image URL when upload is successful', () async {
        // Arrange
        const propertyId = '1';
        const imagePath = '/path/to/image.jpg';
        const expectedImageUrl = 'https://example.com/images/property1.jpg';
        
        final expectedResponse = Response<Map<String, dynamic>>(
          data: {'image_url': expectedImageUrl},
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.uploadPropertyImage(propertyId, imagePath);

        // Assert
        expect(result, equals(expectedImageUrl));
        
        verify(mockHttpClient.post(
          'v1/properties/1/images', 
          data: {'image_path': imagePath},
        )).called(1);
      });

      test('should throw exception when upload fails', () async {
        // Arrange
        const propertyId = '1';
        const imagePath = '/path/to/image.jpg';
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.uploadPropertyImage(propertyId, imagePath),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to upload image')
          )),
        );
      });
    });

    group('searchProperties', () {
      test('should return filtered properties when search is successful', () async {
        // Arrange
        const query = 'test';
        final expectedResponse = Response<List<dynamic>>(
          data: [TestData.mockProperty],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.searchProperties(query);

        // Assert
        expect(result, isA<List<Property>>());
        expect(result.length, equals(1));
        
        verify(mockHttpClient.get(
          'v1/properties/search',
          queryParameters: {'q': query},
        )).called(1);
      });

      test('should return empty list when no properties match search', () async {
        // Arrange
        const query = 'nonexistent';
        final expectedResponse = Response<List<dynamic>>(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.searchProperties(query);

        // Assert
        expect(result, isA<List<Property>>());
        expect(result.isEmpty, isTrue);
      });
    });

    group('filterPropertiesByType', () {
      test('should return properties filtered by type when request is successful', () async {
        // Arrange
        const type = PropertyType.house;
        final expectedResponse = Response<List<dynamic>>(
          data: [TestData.mockProperty],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.filterPropertiesByType(type);

        // Assert
        expect(result, isA<List<Property>>());
        expect(result.length, equals(1));
        expect(result.first.type, equals(PropertyType.house));
        
        verify(mockHttpClient.get(
          'v1/properties',
          queryParameters: {'type': 'house'},
        )).called(1);
      });

      test('should throw exception when filter request fails', () async {
        // Arrange
        const type = PropertyType.apartment;
        when(mockHttpClient.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.filterPropertiesByType(type),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to filter properties')
          )),
        );
      });
    });

    group('error handling', () {
      test('should handle network timeouts properly', () async {
        // Arrange
        when(mockHttpClient.get(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act & Assert
        expect(
          () => propertyService.getProperties(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to load properties')
          )),
        );
      });

      test('should handle unauthorized access properly', () async {
        // Arrange
        when(mockHttpClient.get(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => propertyService.getProperties(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to load properties')
          )),
        );
      });

      test('should handle malformed response data', () async {
        // Arrange
        final badResponse = Response<List<dynamic>>(
          data: ['invalid', 'data', 'structure'],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => badResponse);

        // Act & Assert
        expect(
          () => propertyService.getProperties(),
          throwsA(predicate((e) => 
            e is Exception
          )),
        );
      });
    });

    group('API endpoint validation', () {
      test('should use correct API version in all endpoints', () async {
        // Test all methods use the correct versioned endpoints
        const propertyId = '1';
        const query = 'test';
        const type = PropertyType.house;

        // Mock responses for all methods
        final mockResponse = Response<dynamic>(
          data: [TestData.mockProperty],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any, queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => mockResponse);
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: TestData.mockProperty,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act - test each method
        await propertyService.getProperties();
        await propertyService.getProperty(propertyId);
        await propertyService.searchProperties(query);
        await propertyService.filterPropertiesByType(type);

        // Assert - verify correct endpoints were called
        verify(mockHttpClient.get('v1/properties')).called(1);
        verify(mockHttpClient.get('v1/properties/$propertyId')).called(1);
        verify(mockHttpClient.get('v1/properties/search', queryParameters: {'q': query})).called(1);
        verify(mockHttpClient.get('v1/properties', queryParameters: {'type': 'house'})).called(1);
      });
    });

    group('data transformation', () {
      test('should properly transform JSON to Property objects', () async {
        // Arrange
        final propertyJson = {
          'id': '123',
          'name': 'Test Property',
          'address': '123 Test St',
          'description': 'A test property',
          'type': 'house',
          'year_built': 2000,
          'square_footage': 2000.0,
          'bedrooms': 3,
          'bathrooms': 2,
          'image_urls': ['image1.jpg', 'image2.jpg'],
          'owner_id': 'user123',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        final expectedResponse = Response<List<dynamic>>(
          data: [propertyJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.getProperties();

        // Assert
        expect(result.length, equals(1));
        final property = result.first;
        expect(property.id, equals('123'));
        expect(property.name, equals('Test Property'));
        expect(property.address, equals('123 Test St'));
        expect(property.type, equals(PropertyType.house));
        expect(property.yearBuilt, equals(2000));
        expect(property.squareFootage, equals(2000.0));
        expect(property.bedrooms, equals(3));
        expect(property.bathrooms, equals(2));
        expect(property.imageUrls, equals(['image1.jpg', 'image2.jpg']));
        expect(property.ownerId, equals('user123'));
      });

      test('should handle null optional fields properly', () async {
        // Arrange
        final propertyJson = {
          'id': '123',
          'name': 'Test Property',
          'address': '123 Test St',
          'description': null,
          'type': 'apartment',
          'year_built': null,
          'square_footage': null,
          'bedrooms': null,
          'bathrooms': null,
          'image_urls': [],
          'owner_id': 'user123',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        final expectedResponse = Response<List<dynamic>>(
          data: [propertyJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await propertyService.getProperties();

        // Assert
        expect(result.length, equals(1));
        final property = result.first;
        expect(property.description, isNull);
        expect(property.yearBuilt, isNull);
        expect(property.squareFootage, isNull);
        expect(property.bedrooms, isNull);
        expect(property.bathrooms, isNull);
        expect(property.imageUrls, isEmpty);
      });
    });
  });
}