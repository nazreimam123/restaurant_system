import 'package:meta/meta.dart';

@immutable
class CustomerRestaurantContext {
  final String restaurantId;
  final String restaurantName;
  final String branchId;
  final String branchName;
  final String? tableId;
  final String? tableName;
  final String currencyCode;
  final DateTime resolvedAt;

  const CustomerRestaurantContext({
    required this.restaurantId,
    required this.restaurantName,
    required this.branchId,
    required this.branchName,
    this.tableId,
    this.tableName,
    required this.currencyCode,
    required this.resolvedAt,
  });

  factory CustomerRestaurantContext.fromJson(Map<String, dynamic> json) {
    return CustomerRestaurantContext(
      restaurantId: json['restaurant_id'] as String,
      restaurantName: json['restaurant_name'] as String,
      branchId: json['branch_id'] as String,
      branchName: json['branch_name'] as String,
      tableId: json['table_id'] as String?,
      tableName: json['table_name'] as String?,
      currencyCode: (json['currency_code'] as String? ?? 'INR').toUpperCase(),
      resolvedAt: DateTime.parse(json['resolved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    'restaurant_name': restaurantName,
    'branch_id': branchId,
    'branch_name': branchName,
    'table_id': tableId,
    'table_name': tableName,
    'currency_code': currencyCode,
    'resolved_at': resolvedAt.toIso8601String(),
  };
}
