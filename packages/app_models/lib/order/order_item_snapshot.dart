import 'package:meta/meta.dart';

@immutable
class OrderItemModifierSnapshot {
  final String id;
  final String name;
  final int priceDeltaMinor;

  const OrderItemModifierSnapshot({
    required this.id,
    required this.name,
    required this.priceDeltaMinor,
  });

  factory OrderItemModifierSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderItemModifierSnapshot(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceDeltaMinor: json['price_delta_minor'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price_delta_minor': priceDeltaMinor,
  };
}

@immutable
class OrderItemSnapshot {
  final String id;
  final String productName;
  final int basePriceMinor;
  final int unitPriceMinor;
  final int quantity;
  final int totalPriceMinor;
  final String? notes;
  final List<OrderItemModifierSnapshot> modifiers;

  const OrderItemSnapshot({
    required this.id,
    required this.productName,
    required this.basePriceMinor,
    required this.unitPriceMinor,
    required this.quantity,
    required this.totalPriceMinor,
    this.notes,
    this.modifiers = const [],
  });

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'] as List<dynamic>? ?? const [];
    return OrderItemSnapshot(
      id: json['id'] as String,
      productName: json['product_name'] as String? ?? '',
      basePriceMinor: json['base_price_minor'] as int? ?? 0,
      unitPriceMinor: json['unit_price_minor'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      totalPriceMinor: json['total_price_minor'] as int? ?? 0,
      notes: json['notes'] as String?,
      modifiers: rawModifiers
          .map(
            (m) =>
                OrderItemModifierSnapshot.fromJson(m as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name': productName,
    'base_price_minor': basePriceMinor,
    'unit_price_minor': unitPriceMinor,
    'quantity': quantity,
    'total_price_minor': totalPriceMinor,
    'notes': notes,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };
}
