import 'package:meta/meta.dart';

@immutable
class AdminModifierModel {
  final String id;
  final String restaurantId;
  final String groupId;
  final String name;
  final int priceDeltaMinor;
  final int sortOrder;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminModifierModel({
    required this.id,
    required this.restaurantId,
    required this.groupId,
    required this.name,
    required this.priceDeltaMinor,
    required this.sortOrder,
    required this.isAvailable,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminModifierModel.fromJson(Map<String, dynamic> json) {
    return AdminModifierModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      priceDeltaMinor: json['price_delta_minor'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
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
    'group_id': groupId,
    'name': name,
    'price_delta_minor': priceDeltaMinor,
    'sort_order': sortOrder,
    'is_available': isAvailable,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  AdminModifierModel copyWith({
    String? name,
    int? priceDeltaMinor,
    int? sortOrder,
    bool? isAvailable,
    bool? isActive,
  }) {
    return AdminModifierModel(
      id: id,
      restaurantId: restaurantId,
      groupId: groupId,
      name: name ?? this.name,
      priceDeltaMinor: priceDeltaMinor ?? this.priceDeltaMinor,
      sortOrder: sortOrder ?? this.sortOrder,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
