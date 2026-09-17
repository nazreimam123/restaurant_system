import 'package:meta/meta.dart';

@immutable
class DiningTableModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final String? diningAreaId;
  final String? diningAreaName;
  final String name;
  final int? capacity;
  final String qrToken;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiningTableModel({
    required this.id,
    required this.restaurantId,
    required this.branchId,
    this.diningAreaId,
    this.diningAreaName,
    required this.name,
    this.capacity,
    required this.qrToken,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiningTableModel.fromJson(Map<String, dynamic> json) {
    String? areaName;
    if (json['dining_areas'] is Map<String, dynamic>) {
      areaName =
          (json['dining_areas'] as Map<String, dynamic>)['name'] as String?;
    } else if (json['dining_area_name'] is String) {
      areaName = json['dining_area_name'] as String;
    }

    return DiningTableModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      branchId: json['branch_id'] as String,
      diningAreaId: json['dining_area_id'] as String?,
      diningAreaName: areaName,
      name: json['name'] as String,
      capacity: json['capacity'] as int?,
      qrToken: json['qr_token'] as String? ?? '',
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
    'dining_area_id': diningAreaId,
    'name': name,
    'capacity': capacity,
    'qr_token': qrToken,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  DiningTableModel copyWith({
    String? diningAreaId,
    String? diningAreaName,
    String? name,
    int? capacity,
    String? qrToken,
    bool? isActive,
  }) {
    return DiningTableModel(
      id: id,
      restaurantId: restaurantId,
      branchId: branchId,
      diningAreaId: diningAreaId ?? this.diningAreaId,
      diningAreaName: diningAreaName ?? this.diningAreaName,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      qrToken: qrToken ?? this.qrToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class CreateTableRequest {
  final String restaurantId;
  final String branchId;
  final String? diningAreaId;
  final String name;
  final int? capacity;
  final bool isActive;

  const CreateTableRequest({
    required this.restaurantId,
    required this.branchId,
    this.diningAreaId,
    required this.name,
    this.capacity,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    'branch_id': branchId,
    if (diningAreaId != null) 'dining_area_id': diningAreaId,
    'name': name,
    if (capacity != null) 'capacity': capacity,
    'is_active': isActive,
  };
}

@immutable
class UpdateTableRequest {
  final String tableId;
  final String? diningAreaId;
  final String name;
  final int? capacity;
  final bool isActive;

  const UpdateTableRequest({
    required this.tableId,
    this.diningAreaId,
    required this.name,
    this.capacity,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'dining_area_id': diningAreaId,
    'name': name,
    'capacity': capacity,
    'is_active': isActive,
  };
}
