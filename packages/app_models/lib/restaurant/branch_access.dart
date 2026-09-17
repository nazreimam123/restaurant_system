import 'package:meta/meta.dart';

@immutable
class BranchAccess {
  final String branchId;
  final String branchName;
  final String restaurantId;
  final bool isActive;

  const BranchAccess({
    required this.branchId,
    required this.branchName,
    required this.restaurantId,
    required this.isActive,
  });

  factory BranchAccess.fromJson(Map<String, dynamic> json) {
    return BranchAccess(
      branchId: json['branch_id'] as String? ?? (json['id'] as String),
      branchName:
          json['branch_name'] as String? ?? (json['name'] as String? ?? ''),
      restaurantId: json['restaurant_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'branch_id': branchId,
    'branch_name': branchName,
    'restaurant_id': restaurantId,
    'is_active': isActive,
  };
}
