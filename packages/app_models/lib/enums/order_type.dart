enum OrderType {
  dineIn,
  takeaway,
  delivery;

  static OrderType fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'dine_in':
        return OrderType.dineIn;
      case 'takeaway':
        return OrderType.takeaway;
      case 'delivery':
        return OrderType.delivery;
      default:
        throw FormatException('Unknown OrderType: $value');
    }
  }

  String toJson() {
    switch (this) {
      case OrderType.dineIn:
        return 'dine_in';
      case OrderType.takeaway:
        return 'takeaway';
      case OrderType.delivery:
        return 'delivery';
    }
  }
}
