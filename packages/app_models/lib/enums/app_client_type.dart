enum AppClientType {
  customer,
  merchant;

  static AppClientType fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'customer':
        return AppClientType.customer;
      case 'merchant':
        return AppClientType.merchant;
      default:
        throw FormatException('Unknown AppClientType: $value');
    }
  }

  String toJson() => name;
}
