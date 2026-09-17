import 'package:supabase_flutter/supabase_flutter.dart'
    hide CreateTableRequest, ErrorCode;
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'table_repository.dart';

class SupabaseTableRepository implements TableRepository {
  final SupabaseClient _client;

  SupabaseTableRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<DiningAreaModel>> getDiningAreas({
    required String restaurantId,
    required String branchId,
  }) async {
    try {
      final response = await _client
          .from('dining_areas')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('branch_id', branchId)
          .order('sort_order', ascending: true);

      return (response as List<dynamic>)
          .map((json) => DiningAreaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<DiningAreaModel> createDiningArea({
    required String restaurantId,
    required String branchId,
    required String name,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _client
          .from('dining_areas')
          .insert({
            'restaurant_id': restaurantId,
            'branch_id': branchId,
            'name': name.trim(),
            'sort_order': sortOrder,
            'is_active': true,
          })
          .select()
          .single();

      return DiningAreaModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<List<DiningTableModel>> getTables({
    required String restaurantId,
    required String branchId,
    String? diningAreaId,
  }) async {
    try {
      var query = _client
          .from('dining_tables')
          .select('*, dining_areas(name)')
          .eq('restaurant_id', restaurantId)
          .eq('branch_id', branchId);

      if (diningAreaId != null && diningAreaId.isNotEmpty) {
        query = query.eq('dining_area_id', diningAreaId);
      }

      final response = await query.order('name', ascending: true);

      return (response as List<dynamic>)
          .map(
            (json) => DiningTableModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<DiningTableModel> getTableById(String tableId) async {
    try {
      final response = await _client
          .from('dining_tables')
          .select('*, dining_areas(name)')
          .eq('id', tableId)
          .single();

      return DiningTableModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<DiningTableModel> createTable(CreateTableRequest request) async {
    try {
      // Intentionally omit qr_token: DB generates default gen_random_uuid()
      final response = await _client
          .from('dining_tables')
          .insert(request.toJson())
          .select('*, dining_areas(name)')
          .single();

      return DiningTableModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<DiningTableModel> updateTable(UpdateTableRequest request) async {
    try {
      final payload = Map<String, dynamic>.from(request.toJson());
      payload['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('dining_tables')
          .update(payload)
          .eq('id', request.tableId)
          .select('*, dining_areas(name)')
          .single();

      return DiningTableModel.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> toggleTableActive({
    required String tableId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('dining_tables')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tableId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteTable(String tableId) async {
    try {
      await _client.from('dining_tables').delete().eq('id', tableId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<QrRotationResult> rotateTableQr(String tableId) async {
    try {
      final response = await _client.rpc(
        'rotate_table_qr',
        params: {'p_table_id': tableId},
      );

      if (response is Map<String, dynamic>) {
        final ok = response['ok'] as bool? ?? false;
        if (!ok) {
          final errMap = response['error'] as Map<String, dynamic>?;
          final codeStr = errMap?['code'] as String? ?? 'OPERATION_FAILED';
          final message =
              errMap?['message'] as String? ?? 'Failed to rotate QR';
          throw ErrorMapper.fromApiError(code: codeStr, message: message);
        }

        final data = response['data'] as Map<String, dynamic>;
        return QrRotationResult.fromJson(data);
      }

      throw ServerException(
        message: 'Invalid response from rotate_table_qr RPC.',
        code: ErrorCode.serverError,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.map(e);
    }
  }
}
