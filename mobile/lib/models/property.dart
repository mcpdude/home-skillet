import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'property.g.dart';

enum PropertyType {
  @JsonValue('house')
  house,
  @JsonValue('apartment')
  apartment,
  @JsonValue('condo')
  condo,
  @JsonValue('townhouse')
  townhouse,
  @JsonValue('commercial')
  commercial,
  @JsonValue('other')
  other,
}

@JsonSerializable()
class Property extends Equatable {
  const Property({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    required this.type,
    this.yearBuilt,
    this.squareFootage,
    this.bedrooms,
    this.bathrooms,
    this.imageUrls = const [],
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final String? description;
  final PropertyType type;
  
  @JsonKey(name: 'year_built')
  final int? yearBuilt;
  
  @JsonKey(name: 'square_footage')
  final double? squareFootage;
  
  final int? bedrooms;
  final int? bathrooms;
  
  @JsonKey(name: 'image_urls')
  final List<String> imageUrls;
  
  @JsonKey(name: 'owner_id')
  final String ownerId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  factory Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);
  
  Map<String, dynamic> toJson() => _$PropertyToJson(this);

  Property copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    PropertyType? type,
    int? yearBuilt,
    double? squareFootage,
    int? bedrooms,
    int? bathrooms,
    List<String>? imageUrls,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      type: type ?? this.type,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      squareFootage: squareFootage ?? this.squareFootage,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      imageUrls: imageUrls ?? this.imageUrls,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        description,
        type,
        yearBuilt,
        squareFootage,
        bedrooms,
        bathrooms,
        imageUrls,
        ownerId,
        createdAt,
        updatedAt,
      ];
}