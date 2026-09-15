import 'package:meta/meta.dart';
import 'modifier_model.dart';

@immutable
class ModifierGroupModel {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final List<ModifierModel> modifiers;

  const ModifierGroupModel({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.isRequired,
    required this.sortOrder,
    this.modifiers = const [],
  });

  factory ModifierGroupModel.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'] as List<dynamic>? ?? const [];
    return ModifierGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      minSelect: json['min_select'] as int? ?? 0,
      maxSelect: json['max_select'] as int? ?? 1,
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      modifiers: rawModifiers
          .map((m) => ModifierModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'min_select': minSelect,
    'max_select': maxSelect,
    'is_required': isRequired,
    'sort_order': sortOrder,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };
}
