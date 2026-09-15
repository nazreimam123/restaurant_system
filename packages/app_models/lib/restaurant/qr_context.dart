import 'package:meta/meta.dart';
import 'restaurant_summary.dart';
import 'branch_summary.dart';
import 'dining_table_summary.dart';
import 'qr_ordering_options.dart';

@immutable
class QrContext {
  final RestaurantSummary restaurant;
  final BranchSummary branch;
  final DiningTableSummary table;
  final QrOrderingOptions ordering;

  const QrContext({
    required this.restaurant,
    required this.branch,
    required this.table,
    required this.ordering,
  });

  factory QrContext.fromJson(Map<String, dynamic> json) {
    return QrContext(
      restaurant: RestaurantSummary.fromJson(
        json['restaurant'] as Map<String, dynamic>,
      ),
      branch: BranchSummary.fromJson(json['branch'] as Map<String, dynamic>),
      table: DiningTableSummary.fromJson(json['table'] as Map<String, dynamic>),
      ordering: QrOrderingOptions.fromJson(
        (json['ordering'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurant': restaurant.toJson(),
    'branch': branch.toJson(),
    'table': table.toJson(),
    'ordering': ordering.toJson(),
  };
}
