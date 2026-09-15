import 'package:meta/meta.dart';
import 'modifier_group_model.dart';

@immutable
class ProductModel {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final int basePriceMinor;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final int sortOrder;
  final int? preparationMinutes;
  final List<String> tags;
  final List<ModifierGroupModel> modifierGroups;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.basePriceMinor,
    this.imagePath,
    this.isVeg,
    required this.isAvailable,
    required this.sortOrder,
    this.preparationMinutes,
    this.tags = const [],
    this.modifierGroups = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? const [];
    final rawGroups = json['modifier_groups'] as List<dynamic>? ?? const [];

    return ProductModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      basePriceMinor: json['base_price_minor'] as int? ?? 0,
      imagePath: json['image_path'] as String?,
      isVeg: json['is_veg'] as bool?,
      isAvailable: json['is_available'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      preparationMinutes: json['preparation_minutes'] as int?,
      tags: rawTags.map((t) => t.toString()).toList(),
      modifierGroups: rawGroups
          .map((g) => ModifierGroupModel.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'base_price_minor': basePriceMinor,
    'image_path': imagePath,
    'is_veg': isVeg,
    'is_available': isAvailable,
    'sort_order': sortOrder,
    'preparation_minutes': preparationMinutes,
    'tags': tags,
    'modifier_groups': modifierGroups.map((g) => g.toJson()).toList(),
  };
}
