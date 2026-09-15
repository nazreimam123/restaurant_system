import 'package:meta/meta.dart';

@immutable
class CartItemModifier {
  final String modifierId;
  final String name;
  final int priceDeltaMinor;

  const CartItemModifier({
    required this.modifierId,
    required this.name,
    required this.priceDeltaMinor,
  });

  factory CartItemModifier.fromJson(Map<String, dynamic> json) {
    return CartItemModifier(
      modifierId: json['modifier_id'] as String,
      name: json['name'] as String,
      priceDeltaMinor: json['price_delta_minor'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'modifier_id': modifierId,
    'name': name,
    'price_delta_minor': priceDeltaMinor,
  };
}
