import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/property.dart';
import '../../providers/property_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/form_validators.dart';
import '../../services/photo_service.dart';
import '../../services/storage_service.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final String? propertyId;
  final bool isEdit;
  final PropertyType? preselectedType;

  const AddEditPropertyScreen({
    Key? key,
    this.propertyId,
    this.isEdit = false,
    this.preselectedType,
  }) : super(key: key);

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _squareFootageController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  PropertyType _selectedType = PropertyType.house;
  Property? _originalProperty;
  List<String> _imageUrls = [];
  List<Map<String, dynamic>> _uploadedPhotos = []; // Store actual photo data
  bool _isLoading = false;
  String? _errorMessage;
  late PhotoService _photoService;

  @override
  void initState() {
    super.initState();
    _photoService = PhotoService(storageService: StorageService());
    if (widget.isEdit && widget.propertyId != null) {
      _loadPropertyData();
    } else if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _yearBuiltController.dispose();
    _squareFootageController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  void _loadPropertyData() async {
    final propertyProvider = context.read<PropertyProvider>();
    _originalProperty = propertyProvider.getPropertyById(widget.propertyId!);
    
    if (_originalProperty != null) {
      _nameController.text = _originalProperty!.name;
      _addressController.text = _originalProperty!.address;
      _descriptionController.text = _originalProperty!.description ?? '';
      _yearBuiltController.text = _originalProperty!.yearBuilt?.toString() ?? '';
      _squareFootageController.text = _originalProperty!.squareFootage?.toString() ?? '';
      _bedroomsController.text = _originalProperty!.bedrooms?.toString() ?? '';
      _bathroomsController.text = _originalProperty!.bathrooms?.toString() ?? '';
      _selectedType = _originalProperty!.type;
      _imageUrls = List.from(_originalProperty!.imageUrls);
      
      // Load photos from server
      await _loadPropertyPhotos();
    }
  }

  Future<void> _loadPropertyPhotos() async {
    try {
      final photos = await _photoService.getPropertyPhotos(widget.propertyId!);
      if (mounted) {
        setState(() {
          _uploadedPhotos = photos;
          _imageUrls = photos
              .map((photo) => _photoService.getPhotoUrl(photo['url'] as String))
              .toList();
        });
      }
    } catch (e) {
      // Silently fail for now - photos are optional
      print('Error loading photos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? 'Edit Property' : 'Add Property'),
          actions: [
            if (widget.isEdit)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _errorMessage = null),
                          color: Colors.red.shade700,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ],

                // Property Images Section
                _buildImagesSection(),
                const SizedBox(height: 24),

                // Basic Information
                Text(
                  'Basic Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Property Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Property Name *',
                    hintText: 'e.g., Main Residence, Rental Property',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: FormValidators.required,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Property Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    hintText: '123 Main St, City, State ZIP',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: FormValidators.required,
                  textCapitalization: TextCapitalization.words,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Property Type
                DropdownButtonFormField<PropertyType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Property Type *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: PropertyType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getPropertyTypeText(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                  validator: (value) => value == null ? 'Please select a property type' : null,
                ),
                const SizedBox(height: 16),

                // Property Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the property',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // Property Details
                Text(
                  'Property Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Two-column layout for numeric fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearBuiltController,
                        decoration: const InputDecoration(
                          labelText: 'Year Built',
                          hintText: 'e.g., 1995',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final year = int.tryParse(value);
                            if (year == null || year < 1800 || year > DateTime.now().year + 5) {
                              return 'Enter valid year';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _squareFootageController,
                        decoration: const InputDecoration(
                          labelText: 'Square Footage',
                          hintText: 'e.g., 2500',
                          prefixIcon: Icon(Icons.square_foot),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final sqft = int.tryParse(value);
                            if (sqft == null || sqft <= 0) {
                              return 'Enter valid square footage';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsController,
                        decoration: const InputDecoration(
                          labelText: 'Bedrooms',
                          hintText: 'e.g., 3',
                          prefixIcon: Icon(Icons.bed),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final bedrooms = int.tryParse(value);
                            if (bedrooms == null || bedrooms < 0 || bedrooms > 50) {
                              return 'Enter valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bathroomsController,
                        decoration: const InputDecoration(
                          labelText: 'Bathrooms',
                          hintText: 'e.g., 2',
                          prefixIcon: Icon(Icons.bathtub),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final bathrooms = int.tryParse(value);
                            if (bathrooms == null || bathrooms < 0 || bathrooms > 50) {
                              return 'Enter valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveProperty,
                        child: Text(widget.isEdit ? 'Update Property' : 'Create Property'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Images',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _addImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Photo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_imageUrls.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add photos to showcase your property',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == _imageUrls.length) {
                  // Add image button
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: _addImage,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 32,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(_imageUrls[index]),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getPropertyTypeText(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return 'House';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.other:
        return 'Other';
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      // Network image
      return Image.network(
        imagePath,
        width: 100,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: Icon(
              Icons.broken_image,
              size: 32,
              color: Colors.grey.shade600,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Local file
      if (kIsWeb) {
        // Web doesn't support File.fromPath
        return Container(
          color: Colors.grey.shade300,
          child: Icon(
            Icons.image,
            size: 32,
            color: Colors.grey.shade600,
          ),
        );
      } else {
        // Mobile platforms
        return Image.file(
          File(imagePath),
          width: 100,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: Icon(
                Icons.broken_image,
                size: 32,
                color: Colors.grey.shade600,
              ),
            );
          },
        );
      }
    }
  }

  void _addImage() async {
    // If editing an existing property, upload immediately
    if (widget.isEdit && widget.propertyId != null) {
      await _uploadImageForExistingProperty();
    } else {
      // If creating new property, just select and store locally
      await _selectImageForNewProperty();
    }
  }

  Future<void> _uploadImageForExistingProperty() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // Upload the image
        final photoData = await _photoService.uploadPropertyPhoto(
          propertyId: widget.propertyId!,
          imagePath: image.path,
        );

        if (photoData != null && mounted) {
          setState(() {
            _uploadedPhotos.add(photoData);
            _imageUrls.add(_photoService.getPhotoUrl(photoData['url']));
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectImageForNewProperty() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageUrls.add(image.path); // Store local path for new properties
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo selected. It will be uploaded when you save the property.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _removeImage(int index) async {
    // If it's an uploaded photo (has ID), delete from server
    if (widget.isEdit && index < _uploadedPhotos.length) {
      final photo = _uploadedPhotos[index];
      try {
        setState(() => _isLoading = true);
        
        await _photoService.deletePropertyPhoto(
          propertyId: widget.propertyId!,
          photoId: photo['id'],
        );
        
        setState(() {
          _uploadedPhotos.removeAt(index);
          _imageUrls.removeAt(index);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Just remove from local list for new properties
      setState(() {
        _imageUrls.removeAt(index);
      });
    }
  }

  void _saveProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final propertyProvider = context.read<PropertyProvider>();
      
      if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final currentUser = authProvider.currentUser!;
      final now = DateTime.now();

      final property = Property(
        id: widget.isEdit ? _originalProperty!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        type: _selectedType,
        yearBuilt: _yearBuiltController.text.isNotEmpty 
            ? int.tryParse(_yearBuiltController.text) 
            : null,
        squareFootage: _squareFootageController.text.isNotEmpty 
            ? double.tryParse(_squareFootageController.text) 
            : null,
        bedrooms: _bedroomsController.text.isNotEmpty 
            ? int.tryParse(_bedroomsController.text) 
            : null,
        bathrooms: _bathroomsController.text.isNotEmpty 
            ? int.tryParse(_bathroomsController.text) 
            : null,
        imageUrls: _imageUrls,
        ownerId: currentUser.id,
        createdAt: widget.isEdit ? _originalProperty!.createdAt : now,
        updatedAt: now,
      );

      bool success;
      if (widget.isEdit) {
        success = await propertyProvider.updateProperty(property);
      } else {
        success = await propertyProvider.createProperty(property);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit 
                ? 'Property updated successfully!' 
                : 'Property created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() {
          _errorMessage = propertyProvider.errorMessage ?? 
              'Failed to ${widget.isEdit ? 'update' : 'create'} property';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDelete() {
    if (_originalProperty == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "${_originalProperty!.name}"?\n\n'
          'This action cannot be undone and will also delete all associated projects and tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProperty();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty() async {
    if (_originalProperty == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final propertyProvider = context.read<PropertyProvider>();
      final success = await propertyProvider.deleteProperty(_originalProperty!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() {
          _errorMessage = propertyProvider.errorMessage ?? 'Failed to delete property';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting property: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}