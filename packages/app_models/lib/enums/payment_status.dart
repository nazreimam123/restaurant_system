enum PaymentStatus {
  pending,
  authorized,
  paid,
  failed,
  cancelled,
  partiallyRefunded,
  refunded;

  static PaymentStatus fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'authorized':
        return PaymentStatus.authorized;
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        throw FormatException('Unknown PaymentStatus: $value');
    }
  }

  String toJson() {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.authorized:
        return 'authorized';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.partiallyRefunded:
        return 'partially_refunded';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  bool get isPaid => this == PaymentStatus.paid;
  bool get isTerminal =>
      this == PaymentStatus.paid ||
      this == PaymentStatus.failed ||
      this == PaymentStatus.cancelled ||
      this == PaymentStatus.refunded;
}
