import 'package:meta/meta.dart';
import 'cart_item_modifier.dart';

@immutable
class CartItem {
  final String lineId;
  final String productId;
  final String productName;
  final int basePriceMinor;
  final int quantity;
  final String? notes;
  final List<CartItemModifier> modifiers;

  const CartItem({
    required this.lineId,
    required this.productId,
    required this.productName,
    required this.basePriceMinor,
    required this.quantity,
    this.notes,
    this.modifiers = const [],
  });

  /// Minor unit price for a single configured product item.
  int get unitPriceMinor {
    final modifierTotal = modifiers.fold<int>(
      0,
      (sum, m) => sum + m.priceDeltaMinor,
    );
    return basePriceMinor + modifierTotal;
  }

  /// Total minor unit price for this line item.
  int get lineTotalMinor => unitPriceMinor * quantity;

  CartItem copyWith({
    String? lineId,
    String? productId,
    String? productName,
    int? basePriceMinor,
    int? quantity,
    String? notes,
    List<CartItemModifier>? modifiers,
  }) {
    return CartItem(
      lineId: lineId ?? this.lineId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      basePriceMinor: basePriceMinor ?? this.basePriceMinor,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      modifiers: modifiers ?? this.modifiers,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'] as List<dynamic>? ?? const [];
    return CartItem(
      lineId: json['line_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      basePriceMinor: json['base_price_minor'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
      modifiers: rawModifiers
          .map((m) => CartItemModifier.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'line_id': lineId,
    'product_id': productId,
    'product_name': productName,
    'base_price_minor': basePriceMinor,
    'quantity': quantity,
    'notes': notes,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };
}
