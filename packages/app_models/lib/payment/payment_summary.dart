import 'package:meta/meta.dart';
import '../enums/payment_method.dart';
import '../enums/payment_status.dart';

@immutable
class PaymentSummary {
  final String id;
  final String orderId;
  final int amountMinor;
  final String currencyCode;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? gatewayOrderId;
  final DateTime createdAt;

  const PaymentSummary({
    required this.id,
    required this.orderId,
    required this.amountMinor,
    required this.currencyCode,
    required this.method,
    required this.status,
    this.gatewayOrderId,
    required this.createdAt,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amountMinor: json['amount_minor'] as int? ?? 0,
      currencyCode: (json['currency_code'] as String? ?? 'INR').toUpperCase(),
      method: PaymentMethod.fromJson(json['method'] as String),
      status: PaymentStatus.fromJson(json['status'] as String),
      gatewayOrderId: json['gateway_order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'amount_minor': amountMinor,
    'currency_code': currencyCode,
    'method': method.toJson(),
    'status': status.toJson(),
    'gateway_order_id': gatewayOrderId,
    'created_at': createdAt.toIso8601String(),
  };
}
