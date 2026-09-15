/// Standard API and domain error codes returned by trusted backend RPCs
/// or generated internally by repository validation.
class ErrorCode {
  // Authentication & Authorization
  static const String unauthenticated = 'UNAUTHENTICATED';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';

  // QR & Context
  static const String qrNotFound = 'QR_NOT_FOUND';
  static const String qrTableInactive = 'QR_TABLE_INACTIVE';
  static const String branchNotFound = 'BRANCH_NOT_FOUND';
  static const String branchInactive = 'BRANCH_INACTIVE';
  static const String restaurantNotFound = 'RESTAURANT_NOT_FOUND';
  static const String restaurantInactive = 'RESTAURANT_INACTIVE';
  static const String orderingPaused = 'ORDERING_PAUSED';
  static const String restaurantClosed = 'RESTAURANT_CLOSED';

  // Order & Cart
  static const String invalidOrder = 'INVALID_ORDER';
  static const String invalidOrderType = 'INVALID_ORDER_TYPE';
  static const String invalidIdempotencyKey = 'INVALID_IDEMPOTENCY_KEY';
  static const String tableNotFound = 'TABLE_NOT_FOUND';
  static const String tableInactive = 'TABLE_INACTIVE';
  static const String emptyOrder = 'EMPTY_ORDER';
  static const String productNotFound = 'PRODUCT_NOT_FOUND';
  static const String productUnavailable = 'PRODUCT_UNAVAILABLE';
  static const String invalidModifierSelection = 'INVALID_MODIFIER_SELECTION';
  static const String couponInvalid = 'COUPON_INVALID';
  static const String invalidStatusTransition = 'INVALID_STATUS_TRANSITION';
  static const String orderNotFound = 'ORDER_NOT_FOUND';

  // Concurrency & Conflicts
  static const String conflict = 'CONFLICT';

  // Payment
  static const String paymentFailed = 'PAYMENT_FAILED';
  static const String paymentPending = 'PAYMENT_PENDING';
  static const String invalidPaymentAmount = 'INVALID_PAYMENT_AMOUNT';

  // Network / Client
  static const String networkError = 'NETWORK_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String timeout = 'TIMEOUT';
  static const String parseError = 'PARSE_ERROR';
  static const String unknown = 'UNKNOWN';
}
