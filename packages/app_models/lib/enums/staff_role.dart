enum StaffRole {
  owner,
  manager,
  cashier,
  waiter,
  kitchen;

  static StaffRole fromJson(String value) {
    switch (value.toLowerCase().trim()) {
      case 'owner':
        return StaffRole.owner;
      case 'manager':
        return StaffRole.manager;
      case 'cashier':
        return StaffRole.cashier;
      case 'waiter':
        return StaffRole.waiter;
      case 'kitchen':
        return StaffRole.kitchen;
      default:
        throw FormatException('Unknown StaffRole: $value');
    }
  }

  String toJson() => name;
}
