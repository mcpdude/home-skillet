import '../config/api_config.dart';
import '../models/property.dart';
import '../services/http_client.dart';

class PropertyService {
  final HttpClient _httpClient;

  PropertyService({required HttpClient httpClient}) : _httpClient = httpClient;

  // Get all properties for the authenticated user
  Future<List<Property>> getProperties() async {
    try {
      final response = await _httpClient.get('${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load properties: $e');
    }
  }

  // Get a specific property by ID
  Future<Property> getProperty(String propertyId) async {
    try {
      final response = await _httpClient.get('${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}/$propertyId');

      if (response.statusCode == 200) {
        return Property.fromJson(response.data);
      } else {
        throw Exception('Failed to load property: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load property: $e');
    }
  }

  // Create a new property
  Future<Property> createProperty(Property property) async {
    try {
      // Remove ID for creation as backend will generate it
      final propertyData = property.toJson();
      propertyData.remove('id');
      propertyData.remove('created_at');
      propertyData.remove('updated_at');
      
      final response = await _httpClient.post(
        '${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}',
        data: propertyData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Property.fromJson(response.data);
      } else {
        throw Exception('Failed to create property: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Please check your property information');
      } else {
        throw Exception('Failed to create property: $e');
      }
    }
  }

  // Update an existing property
  Future<Property> updateProperty(Property property) async {
    try {
      // Don't update timestamps - let backend handle them
      final propertyData = property.toJson();
      propertyData.remove('created_at');
      propertyData.remove('updated_at');
      
      final response = await _httpClient.put(
        '${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}/${property.id}',
        data: propertyData,
      );

      if (response.statusCode == 200) {
        return Property.fromJson(response.data);
      } else {
        throw Exception('Failed to update property: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Please check your property information');
      } else if (e.toString().contains('404')) {
        throw Exception('Property not found');
      } else {
        throw Exception('Failed to update property: $e');
      }
    }
  }

  // Delete a property
  Future<void> deleteProperty(String propertyId) async {
    try {
      final response = await _httpClient.delete('${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}/$propertyId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete property: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Property not found');
      } else if (e.toString().contains('409')) {
        throw Exception('Cannot delete property with active projects');
      } else {
        throw Exception('Failed to delete property: $e');
      }
    }
  }

  // Upload property image
  Future<String> uploadPropertyImage(String propertyId, String imagePath) async {
    try {
      // This would typically use FormData for file upload
      // For now, returning a placeholder implementation
      final response = await _httpClient.post(
        '${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}/$propertyId/images',
        data: {'image_path': imagePath}, // This would be FormData in real implementation
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['image_url'] as String;
      } else {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete property image
  Future<void> deletePropertyImage(String propertyId, String imageUrl) async {
    try {
      final response = await _httpClient.delete(
        '${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}/$propertyId/images',
        data: {'image_url': imageUrl},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete image: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Search properties
  Future<List<Property>> searchProperties(String query) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search properties: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  // Filter properties by type
  Future<List<Property>> filterPropertiesByType(PropertyType type) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.apiVersion}${ApiConfig.propertiesEndpoint}',
        queryParameters: {'type': type.name},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to filter properties: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to filter properties: $e');
    }
  }
}