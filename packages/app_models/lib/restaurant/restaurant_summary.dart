import 'package:meta/meta.dart';

@immutable
class RestaurantSummary {
  final String id;
  final String name;
  final String slug;
  final String? logoPath;
  final String currencyCode;
  final String timezone;
  final bool isActive;

  const RestaurantSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.logoPath,
    required this.currencyCode,
    required this.timezone,
    required this.isActive,
  });

  factory RestaurantSummary.fromJson(Map<String, dynamic> json) {
    return RestaurantSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      logoPath: json['logo_path'] as String?,
      currencyCode: (json['currency_code'] as String? ?? 'INR').toUpperCase(),
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo_path': logoPath,
    'currency_code': currencyCode,
    'timezone': timezone,
    'is_active': isActive,
  };
}
