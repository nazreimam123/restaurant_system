import 'package:meta/meta.dart';

@immutable
class QrRotationResult {
  final String tableId;
  final String qrToken;
  final String qrUrl;

  const QrRotationResult({
    required this.tableId,
    required this.qrToken,
    required this.qrUrl,
  });

  factory QrRotationResult.fromJson(Map<String, dynamic> json) {
    return QrRotationResult(
      tableId: json['table_id'] as String,
      qrToken: json['qr_token'] as String,
      qrUrl: json['qr_url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'table_id': tableId,
    'qr_token': qrToken,
    'qr_url': qrUrl,
  };
}
