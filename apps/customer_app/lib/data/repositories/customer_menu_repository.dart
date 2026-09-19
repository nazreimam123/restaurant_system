import 'package:app_models/app_models.dart';

/// Repository interface for fetching customer public restaurant menu.
abstract class CustomerMenuRepository {
  /// Fetches complete public menu tree for a branch via `get_public_menu` RPC.
  Future<RestaurantMenu> getPublicMenu(String branchId);
}
