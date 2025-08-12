import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../services/storage_service.dart';

class PhotoService {
  final StorageService _storageService;
  final Dio _dio;

  PhotoService({required StorageService storageService})
      : _storageService = storageService,
        _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          sendTimeout: ApiConfig.sendTimeout,
        ));

  /// Upload a photo to a property
  Future<Map<String, dynamic>?> uploadPropertyPhoto({
    required String propertyId,
    required String imagePath,
    Uint8List? imageBytes, // For web support
    String? description,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Create form data
      FormData formData;

      if (kIsWeb && imageBytes != null) {
        // For web platform
        formData = FormData.fromMap({
          'photo': MultipartFile.fromBytes(
            imageBytes,
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          if (description != null) 'description': description,
        });
      } else {
        // For mobile platforms
        formData = FormData.fromMap({
          'photo': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
          if (description != null) 'description': description,
        });
      }

      final response = await _dio.post(
        '/v1/properties/$propertyId/photos',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Failed to upload photo: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. You do not own this property.');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['error'] != null) {
          throw Exception(errorData['error']['message'] ?? 'Invalid photo file');
        }
        throw Exception('Invalid photo file. Only images are allowed.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  /// Get all photos for a property
  Future<List<Map<String, dynamic>>> getPropertyPhotos(String propertyId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.get(
        '/v1/properties/$propertyId/photos',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final photos = response.data['data'] as List;
        return photos.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load photos: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. You do not own this property.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error loading photos: $e');
    }
  }

  /// Delete a photo
  Future<bool> deletePropertyPhoto({
    required String propertyId,
    required String photoId,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.delete(
        '/v1/properties/$propertyId/photos/$photoId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. You do not own this property.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Photo not found.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error deleting photo: $e');
    }
  }

  /// Update photo metadata
  Future<Map<String, dynamic>?> updatePhotoMetadata({
    required String propertyId,
    required String photoId,
    String? description,
    bool? isPrimary,
    int? displayOrder,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (isPrimary != null) data['is_primary'] = isPrimary;
      if (displayOrder != null) data['display_order'] = displayOrder;

      final response = await _dio.put(
        '/v1/properties/$propertyId/photos/$photoId',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to update photo: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. You do not own this property.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Photo not found.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error updating photo: $e');
    }
  }

  /// Get full photo URL
  String getPhotoUrl(String relativeUrl) {
    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }
    // Remove /api from base URL and add the relative URL
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl$relativeUrl';
  }
}