import 'package:meta/meta.dart';
import '../enums/order_status.dart';
import '../enums/order_type.dart';
import '../enums/payment_status.dart';
import 'order_item_snapshot.dart';

@immutable
class OrderDetail {
  final String id;
  final String orderNumber;
  final String branchId;
  final String? tableId;
  final String? tableName;
  final OrderType orderType;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String currencyCode;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceChargeMinor;
  final int discountMinor;
  final int totalMinor;
  final String? customerName;
  final String? customerPhone;
  final String? customerNotes;
  final List<OrderItemSnapshot> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.branchId,
    this.tableId,
    this.tableName,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    required this.currencyCode,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.serviceChargeMinor,
    required this.discountMinor,
    required this.totalMinor,
    this.customerName,
    this.customerPhone,
    this.customerNotes,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return OrderDetail(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      branchId: json['branch_id'] as String,
      tableId: json['table_id'] as String?,
      tableName: json['table_name'] as String?,
      orderType: OrderType.fromJson(json['order_type'] as String),
      status: OrderStatus.fromJson(json['status'] as String),
      paymentStatus: PaymentStatus.fromJson(json['payment_status'] as String),
      currencyCode: (json['currency_code'] as String? ?? 'INR').toUpperCase(),
      subtotalMinor: json['subtotal_minor'] as int? ?? 0,
      taxMinor: json['tax_minor'] as int? ?? 0,
      serviceChargeMinor: json['service_charge_minor'] as int? ?? 0,
      discountMinor: json['discount_minor'] as int? ?? 0,
      totalMinor: json['total_minor'] as int? ?? 0,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerNotes: json['customer_notes'] as String?,
      items: rawItems
          .map((i) => OrderItemSnapshot.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
    'currency_code': currencyCode,
    'subtotal_minor': subtotalMinor,
    'tax_minor': taxMinor,
    'service_charge_minor': serviceChargeMinor,
    'discount_minor': discountMinor,
    'total_minor': totalMinor,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'customer_notes': customerNotes,
    'items': items.map((i) => i.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
