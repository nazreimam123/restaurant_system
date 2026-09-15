import 'package:meta/meta.dart';
import '../enums/order_type.dart';

@immutable
class CreateOrderItemModifierRequest {
  final String modifierId;

  const CreateOrderItemModifierRequest({required this.modifierId});

  Map<String, dynamic> toJson() => {'modifier_id': modifierId};

  factory CreateOrderItemModifierRequest.fromJson(Map<String, dynamic> json) {
    return CreateOrderItemModifierRequest(
      modifierId: json['modifier_id'] as String,
    );
  }
}

@immutable
class CreateOrderItemRequest {
  final String productId;
  final int quantity;
  final String? notes;
  final List<CreateOrderItemModifierRequest> modifiers;

  const CreateOrderItemRequest({
    required this.productId,
    required this.quantity,
    this.notes,
    this.modifiers = const [],
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'notes': notes,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };

  factory CreateOrderItemRequest.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'] as List<dynamic>? ?? const [];
    return CreateOrderItemRequest(
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
      modifiers: rawModifiers
          .map(
            (m) => CreateOrderItemModifierRequest.fromJson(
              m as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

@immutable
class CreateOrderRequest {
  final String branchId;
  final String? tableId;
  final OrderType orderType;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final String idempotencyKey;
  final List<CreateOrderItemRequest> items;

  const CreateOrderRequest({
    required this.branchId,
    this.tableId,
    required this.orderType,
    this.customerName,
    this.customerPhone,
    this.notes,
    required this.idempotencyKey,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'branch_id': branchId,
    'table_id': tableId,
    'order_type': orderType.toJson(),
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'notes': notes,
    'idempotency_key': idempotencyKey,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CreateOrderRequest(
      branchId: json['branch_id'] as String,
      tableId: json['table_id'] as String?,
      orderType: OrderType.fromJson(json['order_type'] as String),
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      notes: json['notes'] as String?,
      idempotencyKey: json['idempotency_key'] as String,
      items: rawItems
          .map(
            (i) => CreateOrderItemRequest.fromJson(i as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
