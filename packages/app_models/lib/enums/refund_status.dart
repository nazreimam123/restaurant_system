enum RefundStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled;

  static RefundStatus fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return RefundStatus.pending;
      case 'processing':
        return RefundStatus.processing;
      case 'succeeded':
        return RefundStatus.succeeded;
      case 'failed':
        return RefundStatus.failed;
      case 'cancelled':
        return RefundStatus.cancelled;
      default:
        throw FormatException('Unknown RefundStatus: $value');
    }
  }

  String toJson() => name;
}
