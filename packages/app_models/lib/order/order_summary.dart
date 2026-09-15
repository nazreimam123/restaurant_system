import 'package:meta/meta.dart';
import '../enums/order_status.dart';
import '../enums/order_type.dart';
import '../enums/payment_status.dart';

@immutable
class OrderSummary {
  final String id;
  final String orderNumber;
  final String branchId;
  final String? tableId;
  final String? tableName;
  final OrderType orderType;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final int totalMinor;
  final String currencyCode;
  final int itemCount;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.branchId,
    this.tableId,
    this.tableName,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    required this.totalMinor,
    required this.currencyCode,
    required this.itemCount,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      branchId: json['branch_id'] as String,
      tableId: json['table_id'] as String?,
      tableName: json['table_name'] as String?,
      orderType: OrderType.fromJson(json['order_type'] as String),
      status: OrderStatus.fromJson(json['status'] as String),
      paymentStatus: PaymentStatus.fromJson(json['payment_status'] as String),
      totalMinor: json['total_minor'] as int? ?? 0,
      currencyCode: (json['currency_code'] as String? ?? 'INR').toUpperCase(),
      itemCount: json['item_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'branch_id': branchId,
    'table_id': tableId,
    'table_name': tableName,
    'order_type': orderType.toJson(),
    'status': status.toJson(),
    'payment_status': paymentStatus.toJson(),
    'total_minor': totalMinor,
    'currency_code': currencyCode,
    'item_count': itemCount,
    'created_at': createdAt.toIso8601String(),
  };
}
