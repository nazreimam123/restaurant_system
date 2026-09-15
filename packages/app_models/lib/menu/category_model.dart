import 'package:meta/meta.dart';
import 'product_model.dart';

@immutable
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final List<ProductModel> products;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.sortOrder,
    this.products = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? const [];
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      products: rawProducts
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image_path': imagePath,
    'sort_order': sortOrder,
    'products': products.map((p) => p.toJson()).toList(),
  };
}
