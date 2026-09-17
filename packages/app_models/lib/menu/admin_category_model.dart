import 'package:meta/meta.dart';

@immutable
class AdminCategoryModel {
  final String id;
  final String restaurantId;
  final String? branchId;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminCategoryModel({
    required this.id,
    required this.restaurantId,
    this.branchId,
    required this.name,
    this.description,
    this.imagePath,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      branchId: json['branch_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
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
    'name': name,
    'description': description,
    'image_path': imagePath,
    'sort_order': sortOrder,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  AdminCategoryModel copyWith({
    String? name,
    String? description,
    String? imagePath,
    int? sortOrder,
    bool? isActive,
  }) {
    return AdminCategoryModel(
      id: id,
      restaurantId: restaurantId,
      branchId: branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class CreateCategoryRequest {
  final String restaurantId;
  final String? branchId;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;

  const CreateCategoryRequest({
    required this.restaurantId,
    this.branchId,
    required this.name,
    this.description,
    this.imagePath,
    this.sortOrder = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    if (branchId != null) 'branch_id': branchId,
    'name': name,
    'description': description,
    'image_path': imagePath,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}

@immutable
class UpdateCategoryRequest {
  final String categoryId;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;

  const UpdateCategoryRequest({
    required this.categoryId,
    required this.name,
    this.description,
    this.imagePath,
    required this.sortOrder,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'image_path': imagePath,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}
