import 'package:meta/meta.dart';

@immutable
class QrOrderingOptions {
  final bool allowDineIn;
  final bool allowTakeaway;
  final bool allowDelivery;
  final bool isOrderingPaused;
  final String? pauseReason;

  const QrOrderingOptions({
    required this.allowDineIn,
    required this.allowTakeaway,
    required this.allowDelivery,
    required this.isOrderingPaused,
    this.pauseReason,
  });

  factory QrOrderingOptions.fromJson(Map<String, dynamic> json) {
    return QrOrderingOptions(
      allowDineIn: json['allow_dine_in'] as bool? ?? true,
      allowTakeaway: json['allow_takeaway'] as bool? ?? false,
      allowDelivery: json['allow_delivery'] as bool? ?? false,
      isOrderingPaused: json['is_ordering_paused'] as bool? ?? false,
      pauseReason: json['pause_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'allow_dine_in': allowDineIn,
    'allow_takeaway': allowTakeaway,
    'allow_delivery': allowDelivery,
    'is_ordering_paused': isOrderingPaused,
    'pause_reason': pauseReason,
  };
}
