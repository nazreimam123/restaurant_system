import 'package:meta/meta.dart';
import '../enums/staff_role.dart';

@immutable
class RestaurantMembership {
  final String restaurantId;
  final String restaurantName;
  final String? restaurantLogoPath;
  final StaffRole role;
  final bool isActive;

  const RestaurantMembership({
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantLogoPath,
    required this.role,
    required this.isActive,
  });

  factory RestaurantMembership.fromJson(Map<String, dynamic> json) {
    return RestaurantMembership(
      restaurantId: json['restaurant_id'] as String,
      restaurantName:
          json['restaurant_name'] as String? ?? (json['name'] as String? ?? ''),
      restaurantLogoPath:
          json['restaurant_logo_path'] as String? ??
          (json['logo_path'] as String?),
      role: StaffRole.fromJson(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurant_id': restaurantId,
    'restaurant_name': restaurantName,
    'restaurant_logo_path': restaurantLogoPath,
    'role': role.toJson(),
    'is_active': isActive,
  };
}
