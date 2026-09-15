import 'package:meta/meta.dart';

@immutable
class BranchSummary {
  final String id;
  final String restaurantId;
  final String name;
  final String? code;
  final String? phone;
  final String? city;
  final String? state;
  final String countryCode;
  final bool isActive;
  final int menuVersion;

  const BranchSummary({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.code,
    this.phone,
    this.city,
    this.state,
    required this.countryCode,
    required this.isActive,
    required this.menuVersion,
  });

  factory BranchSummary.fromJson(Map<String, dynamic> json) {
    return BranchSummary(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      countryCode: json['country_code'] as String? ?? 'IN',
      isActive: json['is_active'] as bool? ?? true,
      menuVersion: json['menu_version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurant_id': restaurantId,
    'name': name,
    'code': code,
    'phone': phone,
    'city': city,
    'state': state,
    'country_code': countryCode,
    'is_active': isActive,
    'menu_version': menuVersion,
  };
}
