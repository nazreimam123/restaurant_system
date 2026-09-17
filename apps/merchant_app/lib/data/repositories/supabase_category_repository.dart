import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'category_repository.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client;

  SupabaseCategoryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<AdminCategoryModel>> getCategories({
    required String restaurantId,
    String? branchId,
  }) async {
    try {
      var query = _client
          .from('categories')
          .select()
          .eq('restaurant_id', restaurantId);

      if (branchId != null) {
        query = query.or('branch_id.eq.$branchId,branch_id.is.null');
      }

      final response = await query.order('sort_order', ascending: true);
      return (response as List<dynamic>)
          .map(
            (json) => AdminCategoryModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminCategoryModel> getCategoryById(String categoryId) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('id', categoryId)
          .single();

      return AdminCategoryModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminCategoryModel> createCategory(
    CreateCategoryRequest request,
  ) async {
    try {
      final response = await _client
          .from('categories')
          .insert(request.toJson())
          .select()
          .single();

      return AdminCategoryModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminCategoryModel> updateCategory(
    UpdateCategoryRequest request,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(request.toJson());
      payload['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('categories')
          .update(payload)
          .eq('id', request.categoryId)
          .select()
          .single();

      return AdminCategoryModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> toggleCategoryActive({
    required String categoryId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('categories')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> reorderCategories(List<String> categoryIdsInOrder) async {
    try {
      for (int i = 0; i < categoryIdsInOrder.length; i++) {
        await _client
            .from('categories')
            .update({
              'sort_order': i * 10,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', categoryIdsInOrder[i]);
      }
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _client.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
