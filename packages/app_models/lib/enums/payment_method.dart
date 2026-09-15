enum PaymentMethod {
  cash,
  card,
  upi,
  wallet,
  online;

  static PaymentMethod fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'upi':
        return PaymentMethod.upi;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'online':
        return PaymentMethod.online;
      default:
        throw FormatException('Unknown PaymentMethod: $value');
    }
  }

  String toJson() => name;
}
