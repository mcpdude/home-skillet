// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
      type: $enumDecode(_$PropertyTypeEnumMap, json['type']),
      yearBuilt: (json['year_built'] as num?)?.toInt(),
      squareFootage: (json['square_footage'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'description': instance.description,
      'type': _$PropertyTypeEnumMap[instance.type]!,
      'year_built': instance.yearBuilt,
      'square_footage': instance.squareFootage,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'image_urls': instance.imageUrls,
      'owner_id': instance.ownerId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$PropertyTypeEnumMap = {
  PropertyType.house: 'house',
  PropertyType.apartment: 'apartment',
  PropertyType.condo: 'condo',
  PropertyType.townhouse: 'townhouse',
  PropertyType.commercial: 'commercial',
  PropertyType.other: 'other',
};
