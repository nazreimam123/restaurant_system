import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'product_repository.dart';

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client;

  SupabaseProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<AdminProductModel>> getProducts({
    required String restaurantId,
    String? branchId,
    String? categoryId,
    String? search,
  }) async {
    try {
      var query = _client
          .from('products')
          .select('''
            *,
            categories(name),
            product_modifier_groups(
              modifier_group_id,
              modifier_groups(*, modifiers(*))
            )
          ''')
          .eq('restaurant_id', restaurantId);

      if (branchId != null) {
        query = query.or('branch_id.eq.$branchId,branch_id.is.null');
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%${search.trim()}%');
      }

      final response = await query.order('sort_order', ascending: true);
      return (response as List<dynamic>)
          .map((json) => _mapProductJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminProductModel> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select('''
            *,
            categories(name),
            product_modifier_groups(
              modifier_group_id,
              modifier_groups(*, modifiers(*))
            )
          ''')
          .eq('id', productId)
          .single();

      return _mapProductJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminProductModel> createProduct(CreateProductRequest request) async {
    try {
      final row = await _client
          .from('products')
          .insert(request.toJson())
          .select()
          .single();

      final productId = row['id'] as String;

      if (request.modifierGroupIds.isNotEmpty) {
        final links = request.modifierGroupIds.asMap().entries.map((entry) {
          return {
            'restaurant_id': request.restaurantId,
            'product_id': productId,
            'modifier_group_id': entry.value,
            'sort_order': entry.key * 10,
          };
        }).toList();

        await _client.from('product_modifier_groups').insert(links);
      }

      return await getProductById(productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminProductModel> updateProduct({
    required UpdateProductRequest request,
    required String restaurantId,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(request.toJson());
      payload['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('products')
          .update(payload)
          .eq('id', request.productId);

      // Re-sync product modifier group links
      await _client
          .from('product_modifier_groups')
          .delete()
          .eq('product_id', request.productId);

      if (request.modifierGroupIds.isNotEmpty) {
        final links = request.modifierGroupIds.asMap().entries.map((entry) {
          return {
            'restaurant_id': restaurantId,
            'product_id': request.productId,
            'modifier_group_id': entry.value,
            'sort_order': entry.key * 10,
          };
        }).toList();

        await _client.from('product_modifier_groups').insert(links);
      }

      return await getProductById(request.productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> toggleProductAvailability({
    required String productId,
    required bool isAvailable,
  }) async {
    try {
      await _client
          .from('products')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> toggleProductActive({
    required String productId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('products')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  AdminProductModel _mapProductJson(Map<String, dynamic> json) {
    final rawLinks =
        json['product_modifier_groups'] as List<dynamic>? ?? const [];
    final List<String> groupIds = [];
    final List<AdminModifierGroupModel> groups = [];

    for (final item in rawLinks) {
      if (item is Map<String, dynamic>) {
        final gId = item['modifier_group_id'] as String?;
        if (gId != null) groupIds.add(gId);

        final groupData = item['modifier_groups'];
        if (groupData is Map<String, dynamic>) {
          groups.add(AdminModifierGroupModel.fromJson(groupData));
        }
      }
    }

    final enrichedJson = Map<String, dynamic>.from(json);
    enrichedJson['modifier_group_ids'] = groupIds;
    enrichedJson['modifier_groups'] = groups.map((g) => g.toJson()).toList();

    return AdminProductModel.fromJson(enrichedJson);
  }
}
