import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:app_models/app_models.dart';

/// Long-lived service managing customer restaurant & table context.
///
/// IMPORTANT (AGENTS.md rule 29 & Part F):
/// RestaurantContextService is UX/convenience state only.
/// It is NOT proof of authorization or price authority.
/// The backend RPCs and RLS validate every tenant-sensitive operation.
class RestaurantContextService extends GetxService {
  static const String _storageKey = 'customer_restaurant_context';
  final GetStorage _storage = GetStorage();

  final Rxn<CustomerRestaurantContext> _context =
      Rxn<CustomerRestaurantContext>();

  CustomerRestaurantContext? get currentContext => _context.value;

  bool get hasValidContext => _context.value != null;

  String? get restaurantId => _context.value?.restaurantId;
  String? get restaurantName => _context.value?.restaurantName;
  String? get branchId => _context.value?.branchId;
  String? get branchName => _context.value?.branchName;
  String? get tableId => _context.value?.tableId;
  String? get tableName => _context.value?.tableName;
  String get currencyCode => _context.value?.currencyCode ?? 'INR';

  Future<RestaurantContextService> init() async {
    restoreContext();
    return this;
  }

  /// Sets active restaurant context and persists safe snapshot locally.
  void setContext(CustomerRestaurantContext context) {
    _context.value = context;
    try {
      _storage.write(_storageKey, context.toJson());
      developer.log(
        'RestaurantContextService: Saved context for branch: ${context.branchId}, table: ${context.tableId}',
        name: 'RestaurantContextService',
      );
    } catch (e) {
      developer.log(
        'RestaurantContextService: Failed to persist context: $e',
        name: 'RestaurantContextService',
      );
    }
  }

  /// Restores persisted context from local storage if available.
  CustomerRestaurantContext? restoreContext() {
    try {
      final raw = _storage.read<Map<String, dynamic>>(_storageKey);
      if (raw != null) {
        final restored = CustomerRestaurantContext.fromJson(
          Map<String, dynamic>.from(raw),
        );
        _context.value = restored;
        return restored;
      }
    } catch (e) {
      developer.log(
        'RestaurantContextService: Corrupted context in local storage, clearing: $e',
        name: 'RestaurantContextService',
      );
      clearContext();
    }
    return null;
  }

  /// Clears stored context when leaving restaurant or invalidating table.
  void clearContext() {
    _context.value = null;
    try {
      _storage.remove(_storageKey);
    } catch (_) {}
  }
}
