import 'package:meta/meta.dart';
import '../enums/staff_role.dart';

/// Request parameters for the `create_restaurant` RPC function.
@immutable
class CreateBranchInput {
  final String name;
  final String? code;
  final String? phone;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? postalCode;
  final String countryCode;

  const CreateBranchInput({
    required this.name,
    this.code,
    this.phone,
    this.addressLine1,
    this.city,
    this.state,
    this.postalCode,
    this.countryCode = 'IN',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (code != null && code!.trim().isNotEmpty) 'code': code!.trim(),
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (addressLine1 != null && addressLine1!.trim().isNotEmpty)
        'address_line1': addressLine1!.trim(),
      if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
      if (state != null && state!.trim().isNotEmpty) 'state': state!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty)
        'postal_code': postalCode!.trim(),
      'country_code': countryCode.trim().toUpperCase(),
    };
  }

  factory CreateBranchInput.fromJson(Map<String, dynamic> json) {
    return CreateBranchInput(
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      phone: json['phone'] as String?,
      addressLine1: json['address_line1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      countryCode: json['country_code'] as String? ?? 'IN',
    );
  }
}

@immutable
class CreateRestaurantRequest {
  final String name;
  final String slug;
  final String currencyCode;
  final String timezone;
  final CreateBranchInput branch;

  const CreateRestaurantRequest({
    required this.name,
    required this.slug,
    this.currencyCode = 'INR',
    this.timezone = 'Asia/Kolkata',
    required this.branch,
  });

  /// Formats the parameters to match the RPC `public.create_restaurant` signature.
  Map<String, dynamic> toRpcParams() {
    return {
      'p_name': name.trim(),
      'p_slug': slug.trim().toLowerCase(),
      'p_currency_code': currencyCode.trim().toUpperCase(),
      'p_timezone': timezone.trim(),
      'p_branch': branch.toJson(),
    };
  }
}

@immutable
class CreateRestaurantResult {
  final String restaurantId;
  final String branchId;
  final StaffRole role;

  const CreateRestaurantResult({
    required this.restaurantId,
    required this.branchId,
    required this.role,
  });

  factory CreateRestaurantResult.fromJson(Map<String, dynamic> json) {
    return CreateRestaurantResult(
      restaurantId: json['restaurant_id'] as String,
      branchId: json['branch_id'] as String,
      role: StaffRole.fromJson(json['role'] as String? ?? 'owner'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'branch_id': branchId,
      'role': role.toJson(),
    };
  }
}
