import 'package:meta/meta.dart';

@immutable
class DiningTableSummary {
  final String id;
  final String branchId;
  final String name;
  final int? capacity;
  final bool isActive;

  const DiningTableSummary({
    required this.id,
    required this.branchId,
    required this.name,
    this.capacity,
    required this.isActive,
  });

  factory DiningTableSummary.fromJson(Map<String, dynamic> json) {
    return DiningTableSummary(
      id: json['id'] as String,
      branchId: json['branch_id'] as String? ?? '',
      name: json['name'] as String,
      capacity: json['capacity'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'name': name,
    'capacity': capacity,
    'is_active': isActive,
  };
}
