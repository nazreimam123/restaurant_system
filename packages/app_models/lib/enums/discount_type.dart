enum DiscountType {
  fixed,
  percentage;

  static DiscountType fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'fixed':
        return DiscountType.fixed;
      case 'percentage':
        return DiscountType.percentage;
      default:
        throw FormatException('Unknown DiscountType: $value');
    }
  }

  String toJson() => name;
}
