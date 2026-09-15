enum OrderStatus {
  awaitingPayment,
  placed,
  accepted,
  preparing,
  ready,
  served,
  completed,
  cancelled;

  static OrderStatus fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'awaiting_payment':
        return OrderStatus.awaitingPayment;
      case 'placed':
        return OrderStatus.placed;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        throw FormatException('Unknown OrderStatus: $value');
    }
  }

  String toJson() {
    switch (this) {
      case OrderStatus.awaitingPayment:
        return 'awaiting_payment';
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.served:
        return 'served';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;
  bool get isActive => !isTerminal;
}
