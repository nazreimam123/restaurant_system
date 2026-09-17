import 'package:meta/meta.dart';
import '../enums/staff_role.dart';

@immutable
class MerchantContext {
  final String restaurantId;
  final String restaurantName;
  final String branchId;
  final String branchName;
  final StaffRole role;

  const MerchantContext({
    required this.restaurantId,
    required this.restaurantName,
    required this.branchId,
    required this.branchName,
    required this.role,
  });

  factory MerchantContext.fromJson(Map<String, dynamic> json) {
    return MerchantContext(
      restaurantId: json['restaurant_id'] as String,
      restaurantName: json['restaurant_name'] as String,
      branchId: json['branch_id'] as String,
      branchName: json['branch_name'] as String,
      role: StaffRole.fromJson(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    'restaurant_name': restaurantName,
    'branch_id': branchId,
    'branch_name': branchName,
    'role': role.toJson(),
  };
}
