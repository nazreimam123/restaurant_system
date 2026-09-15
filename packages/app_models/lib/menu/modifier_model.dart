import 'package:meta/meta.dart';

@immutable
class ModifierModel {
  final String id;
  final String name;
  final int priceDeltaMinor;
  final int sortOrder;
  final bool isAvailable;

  const ModifierModel({
    required this.id,
    required this.name,
    required this.priceDeltaMinor,
    required this.sortOrder,
    required this.isAvailable,
  });

  factory ModifierModel.fromJson(Map<String, dynamic> json) {
    return ModifierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      priceDeltaMinor: json['price_delta_minor'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price_delta_minor': priceDeltaMinor,
    'sort_order': sortOrder,
    'is_available': isAvailable,
  };
}
