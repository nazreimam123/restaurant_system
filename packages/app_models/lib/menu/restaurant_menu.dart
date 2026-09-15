import 'package:meta/meta.dart';
import '../restaurant/restaurant_summary.dart';
import '../restaurant/branch_summary.dart';
import '../restaurant/qr_ordering_options.dart';
import 'category_model.dart';

@immutable
class RestaurantMenu {
  final RestaurantSummary restaurant;
  final BranchSummary branch;
  final QrOrderingOptions ordering;
  final List<CategoryModel> categories;

  const RestaurantMenu({
    required this.restaurant,
    required this.branch,
    required this.ordering,
    this.categories = const [],
  });

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List<dynamic>? ?? const [];
    return RestaurantMenu(
      restaurant: RestaurantSummary.fromJson(
        json['restaurant'] as Map<String, dynamic>,
      ),
      branch: BranchSummary.fromJson(json['branch'] as Map<String, dynamic>),
      ordering: QrOrderingOptions.fromJson(
        (json['ordering'] as Map<String, dynamic>?) ?? const {},
      ),
      categories: rawCategories
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurant': restaurant.toJson(),
    'branch': branch.toJson(),
    'ordering': ordering.toJson(),
    'categories': categories.map((c) => c.toJson()).toList(),
  };
}
