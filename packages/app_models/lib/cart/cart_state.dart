import 'package:meta/meta.dart';
import 'cart_item.dart';

@immutable
class CartState {
  final String? restaurantId;
  final String? branchId;
  final String? tableId;
  final List<CartItem> items;
  final String? notes;

  const CartState({
    this.restaurantId,
    this.branchId,
    this.tableId,
    this.items = const [],
    this.notes,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Estimated subtotal in integer minor units.
  /// NOTE: Authoritative calculation is performed server-side by create_order RPC.
  int get estimatedSubtotalMinor =>
      items.fold<int>(0, (sum, item) => sum + item.lineTotalMinor);

  bool isCompatibleWith({required String targetBranchId}) {
    if (branchId == null || branchId!.isEmpty) return true;
    return branchId == targetBranchId;
  }

  CartState copyWith({
    String? restaurantId,
    String? branchId,
    String? tableId,
    List<CartItem>? items,
    String? notes,
  }) {
    return CartState(
      restaurantId: restaurantId ?? this.restaurantId,
      branchId: branchId ?? this.branchId,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CartState(
      restaurantId: json['restaurant_id'] as String?,
      branchId: json['branch_id'] as String?,
      tableId: json['table_id'] as String?,
      items: rawItems
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    'branch_id': branchId,
    'table_id': tableId,
    'items': items.map((i) => i.toJson()).toList(),
    'notes': notes,
  };
}
