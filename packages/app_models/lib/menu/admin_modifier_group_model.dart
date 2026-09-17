import 'package:meta/meta.dart';
import 'admin_modifier_model.dart';

@immutable
class AdminModifierGroupModel {
  final String id;
  final String restaurantId;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final List<AdminModifierModel> modifiers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminModifierGroupModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.isRequired,
    required this.sortOrder,
    required this.isActive,
    this.modifiers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminModifierGroupModel.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'] as List<dynamic>? ?? const [];
    return AdminModifierGroupModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      minSelect: json['min_select'] as int? ?? 0,
      maxSelect: json['max_select'] as int? ?? 1,
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      modifiers: rawModifiers
          .map((m) => AdminModifierModel.fromJson(m as Map<String, dynamic>))
          .toList(),
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
    'name': name,
    'min_select': minSelect,
    'max_select': maxSelect,
    'is_required': isRequired,
    'sort_order': sortOrder,
    'is_active': isActive,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  AdminModifierGroupModel copyWith({
    String? name,
    int? minSelect,
    int? maxSelect,
    bool? isRequired,
    int? sortOrder,
    bool? isActive,
    List<AdminModifierModel>? modifiers,
  }) {
    return AdminModifierGroupModel(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ?? this.maxSelect,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      modifiers: modifiers ?? this.modifiers,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class CreateModifierOptionDraft {
  final String? id; // null if new
  final String name;
  final int priceDeltaMinor;
  final int sortOrder;
  final bool isAvailable;
  final bool isActive;

  const CreateModifierOptionDraft({
    this.id,
    required this.name,
    this.priceDeltaMinor = 0,
    this.sortOrder = 0,
    this.isAvailable = true,
    this.isActive = true,
  });
}

@immutable
class CreateModifierGroupRequest {
  final String restaurantId;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final List<CreateModifierOptionDraft> options;

  const CreateModifierGroupRequest({
    required this.restaurantId,
    required this.name,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.isRequired = false,
    this.sortOrder = 0,
    this.isActive = true,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    'name': name,
    'min_select': minSelect,
    'max_select': maxSelect,
    'is_required': isRequired,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}

@immutable
class UpdateModifierGroupRequest {
  final String groupId;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final List<CreateModifierOptionDraft> options;

  const UpdateModifierGroupRequest({
    required this.groupId,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.isRequired,
    required this.sortOrder,
    required this.isActive,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'min_select': minSelect,
    'max_select': maxSelect,
    'is_required': isRequired,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}
