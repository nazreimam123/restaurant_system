import 'package:meta/meta.dart';
import 'admin_modifier_group_model.dart';

@immutable
class AdminProductModel {
  final String id;
  final String restaurantId;
  final String? branchId;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final String? sku;
  final int basePriceMinor;
  final int? taxBasisPointsOverride;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final bool isActive;
  final int sortOrder;
  final int? preparationMinutes;
  final List<String> modifierGroupIds;
  final List<AdminModifierGroupModel> modifierGroups;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminProductModel({
    required this.id,
    required this.restaurantId,
    this.branchId,
    required this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    this.sku,
    required this.basePriceMinor,
    this.taxBasisPointsOverride,
    this.imagePath,
    this.isVeg,
    required this.isAvailable,
    required this.isActive,
    required this.sortOrder,
    this.preparationMinutes,
    this.modifierGroupIds = const [],
    this.modifierGroups = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    final rawGroupIds = json['modifier_group_ids'] as List<dynamic>?;
    final rawGroups = json['modifier_groups'] as List<dynamic>?;

    String? categoryName;
    if (json['categories'] is Map<String, dynamic>) {
      categoryName =
          (json['categories'] as Map<String, dynamic>)['name'] as String?;
    } else if (json['category_name'] is String) {
      categoryName = json['category_name'] as String;
    }

    return AdminProductModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      branchId: json['branch_id'] as String?,
      categoryId: json['category_id'] as String,
      categoryName: categoryName,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      basePriceMinor: json['base_price_minor'] as int? ?? 0,
      taxBasisPointsOverride: json['tax_basis_points_override'] as int?,
      imagePath: json['image_path'] as String?,
      isVeg: json['is_veg'] as bool?,
      isAvailable: json['is_available'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      preparationMinutes: json['preparation_minutes'] as int?,
      modifierGroupIds: rawGroupIds != null
          ? rawGroupIds.map((e) => e.toString()).toList()
          : const [],
      modifierGroups: rawGroups != null
          ? rawGroups
                .map(
                  (g) => AdminModifierGroupModel.fromJson(
                    g as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurant_id': restaurantId,
    'branch_id': branchId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'sku': sku,
    'base_price_minor': basePriceMinor,
    'tax_basis_points_override': taxBasisPointsOverride,
    'image_path': imagePath,
    'is_veg': isVeg,
    'is_available': isAvailable,
    'is_active': isActive,
    'sort_order': sortOrder,
    'preparation_minutes': preparationMinutes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  AdminProductModel copyWith({
    String? categoryId,
    String? categoryName,
    String? name,
    String? description,
    String? sku,
    int? basePriceMinor,
    int? taxBasisPointsOverride,
    String? imagePath,
    bool? isVeg,
    bool? isAvailable,
    bool? isActive,
    int? sortOrder,
    int? preparationMinutes,
    List<String>? modifierGroupIds,
    List<AdminModifierGroupModel>? modifierGroups,
  }) {
    return AdminProductModel(
      id: id,
      restaurantId: restaurantId,
      branchId: branchId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      basePriceMinor: basePriceMinor ?? this.basePriceMinor,
      taxBasisPointsOverride:
          taxBasisPointsOverride ?? this.taxBasisPointsOverride,
      imagePath: imagePath ?? this.imagePath,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class CreateProductRequest {
  final String restaurantId;
  final String? branchId;
  final String categoryId;
  final String name;
  final String? description;
  final String? sku;
  final int basePriceMinor;
  final int? taxBasisPointsOverride;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final bool isActive;
  final int sortOrder;
  final int? preparationMinutes;
  final List<String> modifierGroupIds;

  const CreateProductRequest({
    required this.restaurantId,
    this.branchId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sku,
    required this.basePriceMinor,
    this.taxBasisPointsOverride,
    this.imagePath,
    this.isVeg,
    this.isAvailable = true,
    this.isActive = true,
    this.sortOrder = 0,
    this.preparationMinutes,
    this.modifierGroupIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    if (branchId != null) 'branch_id': branchId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'sku': sku,
    'base_price_minor': basePriceMinor,
    'tax_basis_points_override': taxBasisPointsOverride,
    'image_path': imagePath,
    'is_veg': isVeg,
    'is_available': isAvailable,
    'is_active': isActive,
    'sort_order': sortOrder,
    'preparation_minutes': preparationMinutes,
  };
}

@immutable
class UpdateProductRequest {
  final String productId;
  final String categoryId;
  final String name;
  final String? description;
  final String? sku;
  final int basePriceMinor;
  final int? taxBasisPointsOverride;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final bool isActive;
  final int sortOrder;
  final int? preparationMinutes;
  final List<String> modifierGroupIds;

  const UpdateProductRequest({
    required this.productId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sku,
    required this.basePriceMinor,
    this.taxBasisPointsOverride,
    this.imagePath,
    this.isVeg,
    required this.isAvailable,
    required this.isActive,
    required this.sortOrder,
    this.preparationMinutes,
    this.modifierGroupIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'name': name,
    'description': description,
    'sku': sku,
    'base_price_minor': basePriceMinor,
    'tax_basis_points_override': taxBasisPointsOverride,
    'image_path': imagePath,
    'is_veg': isVeg,
    'is_available': isAvailable,
    'is_active': isActive,
    'sort_order': sortOrder,
    'preparation_minutes': preparationMinutes,
  };
}
