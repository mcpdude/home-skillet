import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../services/property_service.dart';

class PropertyProvider with ChangeNotifier {
  PropertyProvider({
    required PropertyService propertyService,
  }) : _propertyService = propertyService;

  final PropertyService _propertyService;

  List<Property> _properties = [];
  List<Property> _allProperties = []; // Cache all properties for local filtering
  Property? _selectedProperty;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  PropertyType? _selectedTypeFilter;

  // Getters
  List<Property> get properties => List.unmodifiable(_properties);
  List<Property> get allProperties => List.unmodifiable(_allProperties);
  Property? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PropertyType? get selectedTypeFilter => _selectedTypeFilter;
  bool get hasFilters => _searchQuery.isNotEmpty || _selectedTypeFilter != null;

  // Load all properties for the user
  Future<void> loadProperties() async {
    try {
      _setLoading(true);
      _clearError();

      final properties = await _propertyService.getProperties();
      _allProperties = properties;
      _applyFilters();
      
      // Set first property as selected if none selected
      if (_selectedProperty == null && _properties.isNotEmpty) {
        _selectedProperty = _properties.first;
      }
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create a new property
  Future<bool> createProperty(Property property) async {
    try {
      _setLoading(true);
      _clearError();

      final createdProperty = await _propertyService.createProperty(property);
      _allProperties.add(createdProperty);
      _applyFilters();
      
      // Set as selected if it's the first property
      if (_allProperties.length == 1) {
        _selectedProperty = createdProperty;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing property
  Future<bool> updateProperty(Property property) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedProperty = await _propertyService.updateProperty(property);
      
      final index = _allProperties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _allProperties[index] = updatedProperty;
        _applyFilters();
        
        // Update selected property if it's the same
        if (_selectedProperty?.id == property.id) {
          _selectedProperty = updatedProperty;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a property
  Future<bool> deleteProperty(String propertyId) async {
    try {
      _setLoading(true);
      _clearError();

      await _propertyService.deleteProperty(propertyId);
      
      _allProperties.removeWhere((p) => p.id == propertyId);
      _applyFilters();
      
      // Clear selected property if it was deleted
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = _properties.isNotEmpty ? _properties.first : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Select a property
  void selectProperty(Property property) {
    _selectedProperty = property;
    notifyListeners();
  }

  // Get property by ID
  Property? getPropertyById(String propertyId) {
    try {
      return _allProperties.firstWhere((p) => p.id == propertyId);
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Search and filter functionality
  void searchProperties(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByType(PropertyType? type) {
    _selectedTypeFilter = type;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTypeFilter = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _properties = _allProperties.where((property) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = property.name.toLowerCase().contains(_searchQuery) ||
            property.address.toLowerCase().contains(_searchQuery) ||
            (property.description?.toLowerCase().contains(_searchQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Apply type filter
      if (_selectedTypeFilter != null && property.type != _selectedTypeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  // Local search (without API call)
  List<Property> searchPropertiesLocal(String query) {
    if (query.isEmpty) return _allProperties;
    
    final lowerQuery = query.toLowerCase();
    return _allProperties.where((property) {
      return property.name.toLowerCase().contains(lowerQuery) ||
          property.address.toLowerCase().contains(lowerQuery) ||
          (property.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get properties by type
  List<Property> getPropertiesByType(PropertyType type) {
    return _allProperties.where((property) => property.type == type).toList();
  }

  // Get properties count by type
  Map<PropertyType, int> getPropertiesCountByType() {
    final counts = <PropertyType, int>{};
    for (final type in PropertyType.values) {
      counts[type] = _allProperties.where((p) => p.type == type).length;
    }
    return counts;
  }
}