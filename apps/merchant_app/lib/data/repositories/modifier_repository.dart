import 'package:app_models/app_models.dart';

abstract class ModifierRepository {
  Future<List<AdminModifierGroupModel>> getModifierGroups(String restaurantId);

  Future<AdminModifierGroupModel> getModifierGroupById(String groupId);

  Future<AdminModifierGroupModel> createModifierGroup(
    CreateModifierGroupRequest request,
  );

  Future<AdminModifierGroupModel> updateModifierGroup({
    required UpdateModifierGroupRequest request,
    required String restaurantId,
  });

  Future<void> toggleModifierGroupActive({
    required String groupId,
    required bool isActive,
  });

  Future<void> deleteModifierGroup(String groupId);
}
