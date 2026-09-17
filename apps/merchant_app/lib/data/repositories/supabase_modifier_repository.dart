import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'modifier_repository.dart';

class SupabaseModifierRepository implements ModifierRepository {
  final SupabaseClient _client;

  SupabaseModifierRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<AdminModifierGroupModel>> getModifierGroups(
    String restaurantId,
  ) async {
    try {
      final response = await _client
          .from('modifier_groups')
          .select('*, modifiers(*)')
          .eq('restaurant_id', restaurantId)
          .order('sort_order', ascending: true);

      return (response as List<dynamic>)
          .map(
            (json) =>
                AdminModifierGroupModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminModifierGroupModel> getModifierGroupById(String groupId) async {
    try {
      final response = await _client
          .from('modifier_groups')
          .select('*, modifiers(*)')
          .eq('id', groupId)
          .single();

      return AdminModifierGroupModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminModifierGroupModel> createModifierGroup(
    CreateModifierGroupRequest request,
  ) async {
    try {
      final groupRow = await _client
          .from('modifier_groups')
          .insert(request.toJson())
          .select()
          .single();

      final groupId = groupRow['id'] as String;

      if (request.options.isNotEmpty) {
        final optionsPayload = request.options
            .map(
              (opt) => {
                'restaurant_id': request.restaurantId,
                'group_id': groupId,
                'name': opt.name,
                'price_delta_minor': opt.priceDeltaMinor,
                'sort_order': opt.sortOrder,
                'is_available': opt.isAvailable,
                'is_active': opt.isActive,
              },
            )
            .toList();

        await _client.from('modifiers').insert(optionsPayload);
      }

      return await getModifierGroupById(groupId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AdminModifierGroupModel> updateModifierGroup({
    required UpdateModifierGroupRequest request,
    required String restaurantId,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(request.toJson());
      payload['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('modifier_groups')
          .update(payload)
          .eq('id', request.groupId);

      // Handle modifiers options sync
      // Get existing options for this group
      final existingRows = await _client
          .from('modifiers')
          .select('id')
          .eq('group_id', request.groupId);

      final existingIds = (existingRows as List<dynamic>)
          .map((r) => r['id'] as String)
          .toSet();

      final submittedIds = request.options
          .map((o) => o.id)
          .whereType<String>()
          .toSet();

      // Options to remove
      final toDelete = existingIds.difference(submittedIds);
      if (toDelete.isNotEmpty) {
        await _client
            .from('modifiers')
            .delete()
            .inFilter('id', toDelete.toList());
      }

      // Upsert/Insert options
      for (final opt in request.options) {
        if (opt.id != null && existingIds.contains(opt.id)) {
          await _client
              .from('modifiers')
              .update({
                'name': opt.name,
                'price_delta_minor': opt.priceDeltaMinor,
                'sort_order': opt.sortOrder,
                'is_available': opt.isAvailable,
                'is_active': opt.isActive,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', opt.id!);
        } else {
          await _client.from('modifiers').insert({
            'restaurant_id': restaurantId,
            'group_id': request.groupId,
            'name': opt.name,
            'price_delta_minor': opt.priceDeltaMinor,
            'sort_order': opt.sortOrder,
            'is_available': opt.isAvailable,
            'is_active': opt.isActive,
          });
        }
      }

      return await getModifierGroupById(request.groupId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> toggleModifierGroupActive({
    required String groupId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('modifier_groups')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteModifierGroup(String groupId) async {
    try {
      await _client.from('modifier_groups').delete().eq('id', groupId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
