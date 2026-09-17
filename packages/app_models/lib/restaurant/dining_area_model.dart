import 'package:meta/meta.dart';

@immutable
class DiningAreaModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiningAreaModel({
    required this.id,
    required this.restaurantId,
    required this.branchId,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiningAreaModel.fromJson(Map<String, dynamic> json) {
    return DiningAreaModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      branchId: json['branch_id'] as String,
      name: json['name'] as String,
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
    'sort_order': sortOrder,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
