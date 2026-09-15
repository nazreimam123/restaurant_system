# DATA_MODELS.md
## QR Restaurant Ordering Platform
### Shared Dart Data Model Specification
### Customer App + Admin/Merchant App
### Flutter + GetX + MVC + Supabase
### For Codex, Cursor, Claude Code, Copilot, and Human Developers

> This document is the **authoritative Dart data-model specification** for the project.
>
> It defines:
>
> - enums
> - API DTOs
> - domain models
> - JSON field names
> - nullability
> - money representation
> - date/time representation
> - local cart models
> - local recovery models
> - customer models
> - admin models
> - payment/refund models
> - dashboard/report models
> - Realtime models
> - API result/error models
> - mapping conventions
> - serialization rules
> - equality/copy semantics
> - AI implementation rules
>
> Use this file together with:
>
> - `DATABASE_SCHEMA.sql`
> - `API_CONTRACTS.md`
> - `CUSTOMER_APP_FLOW.md`
> - `ADMIN_APP_FLOW.md`
> - `CUSTOMER_SCREEN_SPEC.md`
> - `ADMIN_SCREEN_SPEC.md`
> - `APP_DESIGN_SYSTEM_AND_UI_SPEC.md`
>
> If a generated model conflicts with this file or `API_CONTRACTS.md`, stop and resolve the mismatch before implementation.

---

# 1. Model Architecture

Recommended layering:

```text
Backend JSON
   ↓
DTO
   ↓
Domain Model
   ↓
Controller/UI
```

For a smaller MVP, DTO and domain model may be combined where they are identical.

However, keep separate models when:

```text
API shape differs from UI/domain shape
local-only fields are needed
historical snapshot differs from live entity
provider-specific payload must stay isolated
```

---

# 2. Shared Package Location

Recommended:

```text
packages/app_models/lib/
```

Suggested structure:

```text
app_models/
├── enums/
├── common/
├── auth/
├── restaurant/
├── menu/
├── cart/
├── order/
├── payment/
├── staff/
├── reports/
├── realtime/
└── local/
```

---

# 3. File Naming

Use:

```text
snake_case.dart
```

Examples:

```text
order_status.dart
product_model.dart
create_order_request.dart
payment_summary.dart
api_error.dart
```

---

# 4. Class Naming

Use:

```text
PascalCase
```

Examples:

```text
ProductModel
OrderSummary
PaymentSummary
CreateOrderRequest
ApiError
```

Avoid vague names:

```text
Data
ItemData
Model1
ResponseData
```

---

# 5. JSON Naming

Backend JSON:

```text
snake_case
```

Dart property:

```text
camelCase
```

Example:

```json
{
  "total_minor": 89250
}
```

Dart:

```dart
final int totalMinor;
```

---

# 6. Money Representation

All money values:

```dart
int
```

representing minor currency units.

Example:

```text
₹199.50
→ 19950
```

Never use:

```dart
double
```

for:

```text
price
subtotal
tax
discount
service charge
delivery fee
refund amount
revenue
```

---

# 7. Currency Representation

Use:

```dart
String currencyCode;
```

Example:

```text
INR
USD
AED
```

Expected format:

```text
ISO-style uppercase 3-letter code
```

---

# 8. Date / Time Representation

Use:

```dart
DateTime
```

for timestamps.

JSON:

```text
ISO-8601
```

Example:

```json
"2026-09-12T13:15:42.123456+00:00"
```

Parser:

```dart
DateTime.parse(...)
```

Convert to user/restaurant timezone only in presentation/formatting layer.

---

# 9. Nullable Date Rules

Backend nullable timestamp:

```json
"completed_at": null
```

Dart:

```dart
DateTime? completedAt;
```

---

# 10. Collection Rules

Backend empty collection:

```json
[]
```

Dart:

```dart
List<T>
```

Prefer non-null collection with default empty list.

Do not use:

```dart
List<T>?
```

unless API truly distinguishes null from empty.

---

# 11. Enum Parsing Rule

Enums must have explicit backend string mapping.

Do not rely on:

```dart
enumValue.name
```

without a controlled converter.

Reason:

```text
backend enum names are contract values
```

---

# 12. `StaffRole`

```dart
enum StaffRole {
  owner,
  manager,
  cashier,
  waiter,
  kitchen,
}
```

Backend values:

```text
owner
manager
cashier
waiter
kitchen
```

---

# 13. `OrderType`

```dart
enum OrderType {
  dineIn,
  takeaway,
  delivery,
}
```

Mapping:

```text
dineIn   ↔ dine_in
takeaway ↔ takeaway
delivery ↔ delivery
```

---

# 14. `OrderStatus`

```dart
enum OrderStatus {
  awaitingPayment,
  placed,
  accepted,
  preparing,
  ready,
  served,
  completed,
  cancelled,
}
```

Mapping:

```text
awaitingPayment ↔ awaiting_payment
placed          ↔ placed
accepted        ↔ accepted
preparing       ↔ preparing
ready           ↔ ready
served          ↔ served
completed       ↔ completed
cancelled       ↔ cancelled
```

---

# 15. `PaymentStatus`

```dart
enum PaymentStatus {
  pending,
  authorized,
  paid,
  failed,
  cancelled,
  partiallyRefunded,
  refunded,
}
```

Mapping:

```text
partiallyRefunded ↔ partially_refunded
```

---

# 16. `PaymentMethod`

```dart
enum PaymentMethod {
  cash,
  card,
  upi,
  wallet,
  online,
}
```

---

# 17. `RefundStatus`

```dart
enum RefundStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
}
```

---

# 18. `DiscountType`

```dart
enum DiscountType {
  fixed,
  percentage,
}
```

---

# 19. `AppClientType`

```dart
enum AppClientType {
  customer,
  merchant,
}
```

---

# 20. Enum Converter Contract

Create one centralized converter per enum or a safe generic helper.

Example:

```dart
OrderStatus orderStatusFromJson(
  String value,
) {
  switch (value) {
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
      throw FormatException(
        'Unknown order status: $value',
      );
  }
}
```

Do not silently map unknown values to a valid business state.

---

# 21. `ApiError`

```dart
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic> details;
}
```

JSON:

```json
{
  "code": "PRODUCT_UNAVAILABLE",
  "message": "One or more products are unavailable.",
  "details": {
    "product_ids": ["uuid"]
  }
}
```

---

# 22. `ApiResult<T>`

Recommended:

```dart
class ApiResult<T> {
  final bool ok;
  final T? data;
  final ApiError? error;
}
```

Invariant:

```text
ok = true  → data != null, error == null
ok = false → data == null, error != null
```

Repositories should validate this invariant.

---

# 23. `ProfileModel`

```dart
class ProfileModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

JSON:

```json
{
  "id": "uuid",
  "full_name": "Rahul Kumar",
  "phone": "+919876543210",
  "avatar_path": "avatars/uuid/avatar.webp",
  "created_at": "...",
  "updated_at": "..."
}
```

---

# 24. `RestaurantSummary`

```dart
class RestaurantSummary {
  final String id;
  final String name;
  final String slug;
  final String? logoPath;
  final String currencyCode;
  final String timezone;
  final bool isActive;
}
```

---

# 25. `BranchSummary`

```dart
class BranchSummary {
  final String id;
  final String restaurantId;
  final String name;
  final String? code;
  final String? phone;
  final String? city;
  final String? state;
  final String countryCode;
  final bool isActive;
  final int menuVersion;
}
```

---

# 26. `DiningTableSummary`

```dart
class DiningTableSummary {
  final String id;
  final String branchId;
  final String name;
  final int? capacity;
  final bool isActive;
}
```

---

# 27. `QrOrderingOptions`

```dart
class QrOrderingOptions {
  final bool allowDineIn;
  final bool allowTakeaway;
  final bool allowDelivery;
  final bool isOrderingPaused;
}
```

Optional:

```dart
final String? pauseReason;
```

when returned by backend.

---

# 28. `QrContext`

```dart
class QrContext {
  final RestaurantSummary restaurant;
  final BranchSummary branch;
  final DiningTableSummary table;
  final QrOrderingOptions ordering;
}
```

This model is safe public ordering context.

---

# 29. `CategoryModel`

```dart
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final List<ProductModel> products;
}
```

For admin CRUD version, add:

```dart
final String restaurantId;
final String branchId;
final bool isActive;
final DateTime createdAt;
final DateTime updatedAt;
```

Recommended to separate:

```text
PublicCategory
AdminCategory
```

if the distinction becomes useful.

---

# 30. `ProductTag`

Simplest public representation:

```dart
typedef ProductTag = String;
```

Admin representation may use:

```dart
class ProductTagModel {
  final String id;
  final String restaurantId;
  final String name;
}
```

---

# 31. `ModifierModel`

```dart
class ModifierModel {
  final String id;
  final String name;
  final int priceDeltaMinor;
  final int sortOrder;
  final bool isAvailable;
}
```

Admin model adds:

```dart
final String restaurantId;
final String groupId;
final bool isActive;
final DateTime createdAt;
final DateTime updatedAt;
```

---

# 32. `ModifierGroupModel`

```dart
class ModifierGroupModel {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final List<ModifierModel> modifiers;
}
```

Admin version adds:

```dart
final String restaurantId;
final bool isActive;
```

---

# 33. `ProductModel`

Customer/public:

```dart
class ProductModel {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final int basePriceMinor;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final int sortOrder;
  final int? preparationMinutes;
  final List<String> tags;
  final List<ModifierGroupModel> modifierGroups;
}
```

---

# 34. `AdminProductModel`

```dart
class AdminProductModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final String categoryId;
  final String name;
  final String? description;
  final String? sku;
  final int basePriceMinor;
  final int? taxBasisPointsOverride;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final bool isActive;
  final int sortOrder;
  final int? preparationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 35. `RestaurantMenu`

```dart
class RestaurantMenu {
  final RestaurantSummary restaurant;
  final BranchSummary branch;
  final MenuOrderingConfig ordering;
  final List<CategoryModel> categories;
}
```

---

# 36. `MenuOrderingConfig`

```dart
class MenuOrderingConfig {
  final bool allowDineIn;
  final bool allowTakeaway;
  final bool allowDelivery;
  final bool isOrderingPaused;
  final String? pauseReason;
}
```

---

# 37. `SelectedModifier`

Local/domain model:

```dart
class SelectedModifier {
  final String id;
  final String name;
  final int priceDeltaMinor;
}
```

Do not rely only on ID locally because UI must continue to display a readable cart if menu cache refresh changes.

---

# 38. `CartItem`

```dart
class CartItem {
  final String localId;
  final String productId;
  final String productName;
  final int basePriceMinorPreview;
  final int quantity;
  final List<SelectedModifier> modifiers;
  final String? note;
}
```

Derived:

```dart
int get modifiersTotalMinor;
int get unitPreviewMinor;
int get linePreviewMinor;
```

These are UI previews only.

---

# 39. `CartState`

```dart
class CartState {
  final int version;
  final String restaurantId;
  final String branchId;
  final String? tableId;
  final DateTime updatedAt;
  final List<CartItem> items;
}
```

Persist locally.

---

# 40. Cart Merge Equality

Two cart rows are mergeable only if:

```text
productId same
selected modifier IDs same
item note same
```

Quantity is then combined.

---

# 41. `CheckoutDraft`

Local only:

```dart
class CheckoutDraft {
  final OrderType orderType;
  final String? customerName;
  final String? customerPhone;
  final String? customerNote;
  final String? couponCode;
  final PaymentMethod? paymentMethod;
}
```

No trusted totals here.

---

# 42. `CreateOrderItemRequest`

```dart
class CreateOrderItemRequest {
  final String productId;
  final int quantity;
  final List<String> modifierIds;
  final String? note;
}
```

JSON:

```json
{
  "product_id": "uuid",
  "quantity": 2,
  "modifier_ids": ["uuid"],
  "note": "No onion"
}
```

---

# 43. `CreateOrderRequest`

```dart
class CreateOrderRequest {
  final String branchId;
  final String? tableId;
  final OrderType orderType;
  final String idempotencyKey;
  final String? customerName;
  final String? customerPhone;
  final String? customerNote;
  final String? couponCode;
  final List<CreateOrderItemRequest> items;
}
```

JSON must be nested under:

```text
p_request
```

when calling the `create_order(jsonb)` RPC.

---

# 44. `CreateOrderResult`

```dart
class CreateOrderResult {
  final OrderSummary order;
  final CreateOrderPaymentState payment;
  final List<OrderResourceChange> changes;
}
```

---

# 45. `CreateOrderPaymentState`

```dart
class CreateOrderPaymentState {
  final bool required;
  final PaymentStatus status;
}
```

---

# 46. `OrderResourceChange`

```dart
class OrderResourceChange {
  final String? productId;
  final String changeType;
  final int? oldPriceMinor;
  final int? newPriceMinor;
}
```

Known `changeType` values:

```text
price_changed
product_unavailable
modifier_unavailable
modifier_rule_changed
```

Keep as String initially unless contract becomes strict enum.

---

# 47. `MoneySummary`

```dart
class MoneySummary {
  final String currencyCode;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceChargeMinor;
  final int deliveryFeeMinor;
  final int discountMinor;
  final int totalMinor;
}
```

---

# 48. `OrderSummary`

```dart
class OrderSummary {
  final String id;
  final int orderNumber;
  final String restaurantId;
  final String branchId;
  final String? tableId;
  final OrderType orderType;
  final OrderStatus status;
  final String currencyCode;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceChargeMinor;
  final int deliveryFeeMinor;
  final int discountMinor;
  final int totalMinor;
  final DateTime? placedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 49. `OrderItemModifierSnapshot`

```dart
class OrderItemModifierSnapshot {
  final String id;
  final String? modifierId;
  final String modifierName;
  final int priceDeltaMinor;
}
```

---

# 50. `OrderItemSnapshot`

```dart
class OrderItemSnapshot {
  final String id;
  final String? productId;
  final String productName;
  final int unitPriceMinor;
  final int quantity;
  final int modifiersTotalMinor;
  final int lineTotalMinor;
  final String? itemNote;
  final List<OrderItemModifierSnapshot> modifiers;
}
```

---

# 51. `OrderStatusEvent`

```dart
class OrderStatusEvent {
  final String id;
  final String orderId;
  final OrderStatus? oldStatus;
  final OrderStatus newStatus;
  final String? changedBy;
  final String? reason;
  final DateTime createdAt;
}
```

Customer DTO may omit `changedBy`.

Parser must support absent/null field.

---

# 52. `PaymentSummary`

```dart
class PaymentSummary {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final String? provider;
  final int amountMinor;
  final String currencyCode;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime? refundedAt;
}
```

---

# 53. `RefundSummary`

```dart
class RefundSummary {
  final String id;
  final String paymentId;
  final int amountMinor;
  final String? reason;
  final RefundStatus status;
  final String? providerRefundId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 54. `OrderDetails`

```dart
class OrderDetails {
  final OrderSummary order;
  final RestaurantSummary restaurant;
  final BranchSummary branch;
  final DiningTableSummary? table;
  final List<OrderItemSnapshot> items;
  final PaymentSummary? payment;
  final List<OrderStatusEvent> statusHistory;
}
```

Admin-specific details may extend with:

```text
customer snapshot
refunds
additional audit/payment data
```

---

# 55. `CustomerOrderHistoryItem`

```dart
class CustomerOrderHistoryItem {
  final String id;
  final int orderNumber;
  final String restaurantName;
  final String branchName;
  final OrderType orderType;
  final OrderStatus status;
  final String currencyCode;
  final int totalMinor;
  final DateTime createdAt;
}
```

---

# 56. `OrderCursor`

```dart
class OrderCursor {
  final DateTime beforeCreatedAt;
  final String beforeId;
}
```

---

# 57. `OrderPage`

```dart
class OrderPage {
  final List<CustomerOrderHistoryItem> items;
  final bool hasMore;
  final OrderCursor? nextCursor;
}
```

---

# 58. `CreatePaymentRequest`

```dart
class CreatePaymentRequest {
  final String orderId;
  final PaymentMethod paymentMethod;
  final String idempotencyKey;
}
```

For online payment request:

```text
paymentMethod = online
```

---

# 59. `PaymentCheckoutData`

Provider-neutral wrapper:

```dart
class PaymentCheckoutData {
  final String? publicKey;
  final String? sessionId;
  final String? customerReference;
  final Map<String, dynamic> extra;
}
```

Provider-specific values must stay safe/public.

---

# 60. `CreatePaymentResult`

```dart
class CreatePaymentResult {
  final String orderId;
  final String paymentId;
  final String provider;
  final String providerOrderId;
  final int amountMinor;
  final String currencyCode;
  final PaymentCheckoutData checkout;
}
```

---

# 61. `PaymentRecoveryState`

Local only:

```dart
class PaymentRecoveryState {
  final String orderId;
  final String? paymentId;
  final String? providerOrderId;
  final DateTime startedAt;
}
```

Never store secrets.

---

# 62. `CheckoutRecoveryState`

```dart
class CheckoutRecoveryState {
  final String idempotencyKey;
  final String branchId;
  final DateTime createdAt;
  final String? orderId;
  final bool paymentPending;
}
```

---

# 63. `RestaurantMembership`

```dart
class RestaurantMembership {
  final String restaurantId;
  final String restaurantName;
  final String? restaurantLogoPath;
  final StaffRole role;
  final bool isActive;
}
```

---

# 64. `BranchAccess`

```dart
class BranchAccess {
  final String branchId;
  final String branchName;
  final String restaurantId;
  final bool isActive;
}
```

---

# 65. `MerchantContext`

Local/domain model:

```dart
class MerchantContext {
  final String restaurantId;
  final String restaurantName;
  final String branchId;
  final String branchName;
  final StaffRole role;
}
```

UI convenience only.

Not authorization truth.

---

# 66. `CustomerRestaurantContext`

Local/domain model:

```dart
class CustomerRestaurantContext {
  final String restaurantId;
  final String restaurantName;
  final String branchId;
  final String branchName;
  final String? tableId;
  final String? tableName;
  final String currencyCode;
  final DateTime resolvedAt;
}
```

---

# 67. `AdminOrderItemPreview`

```dart
class AdminOrderItemPreview {
  final String name;
  final int quantity;
}
```

---

# 68. `AdminPaymentBrief`

```dart
class AdminPaymentBrief {
  final PaymentMethod method;
  final PaymentStatus status;
}
```

---

# 69. `AdminActiveOrder`

```dart
class AdminActiveOrder {
  final String id;
  final int orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final String? tableId;
  final String? tableName;
  final String currencyCode;
  final int totalMinor;
  final int itemCount;
  final List<AdminOrderItemPreview> itemPreview;
  final AdminPaymentBrief? payment;
  final DateTime createdAt;
}
```

---

# 70. `KdsModifierSnapshot`

```dart
class KdsModifierSnapshot {
  final String modifierName;
}
```

---

# 71. `KdsOrderItem`

```dart
class KdsOrderItem {
  final String id;
  final String productName;
  final int quantity;
  final String? itemNote;
  final List<KdsModifierSnapshot> modifiers;
}
```

---

# 72. `KdsOrder`

```dart
class KdsOrder {
  final String id;
  final int orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final String? tableName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final List<KdsOrderItem> items;
  final String? customerNote;
}
```

Derived:

```dart
Duration get elapsed;
```

Do not persist timer state.

---

# 73. `DashboardStatusCounts`

```dart
class DashboardStatusCounts {
  final int placed;
  final int accepted;
  final int preparing;
  final int ready;
}
```

If API later returns dynamic status map, model may change to:

```dart
Map<OrderStatus, int>
```

For MVP explicit fields are easier.

---

# 74. `PaymentMethodTotal`

```dart
class PaymentMethodTotal {
  final PaymentMethod method;
  final int amountMinor;
}
```

---

# 75. `TopProductMetric`

```dart
class TopProductMetric {
  final String? productId;
  final String productName;
  final int quantity;
  final int salesMinor;
}
```

`productId` can be null if product was deleted and report is snapshot-based.

---

# 76. `DashboardSummary`

```dart
class DashboardSummary {
  final String currencyCode;
  final int ordersCount;
  final int grossOrderValueMinor;
  final int paidRevenueMinor;
  final int refundsMinor;
  final int netRevenueMinor;
  final int averageOrderValueMinor;
  final int activeOrdersCount;
  final DashboardStatusCounts statusCounts;
  final List<PaymentMethodTotal> paymentMethodTotals;
  final List<TopProductMetric> topProducts;
}
```

---

# 77. `SalesReportSummary`

```dart
class SalesReportSummary {
  final int ordersCount;
  final int grossOrderValueMinor;
  final int paidRevenueMinor;
  final int refundsMinor;
  final int netRevenueMinor;
  final int averageOrderValueMinor;
}
```

---

# 78. `SalesSeriesPoint`

```dart
class SalesSeriesPoint {
  final DateTime bucketStart;
  final int ordersCount;
  final int netRevenueMinor;
}
```

---

# 79. `SalesReport`

```dart
class SalesReport {
  final SalesReportSummary summary;
  final List<SalesSeriesPoint> series;
}
```

---

# 80. `AdminCategoryModel`

```dart
class AdminCategoryModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 81. `AdminModifierGroupModel`

```dart
class AdminModifierGroupModel {
  final String id;
  final String restaurantId;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final List<AdminModifierModel> modifiers;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 82. `AdminModifierModel`

```dart
class AdminModifierModel {
  final String id;
  final String restaurantId;
  final String groupId;
  final String name;
  final int priceDeltaMinor;
  final int sortOrder;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 83. `DiningAreaModel`

```dart
class DiningAreaModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 84. `DiningTableModel`

Admin version:

```dart
class DiningTableModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final String? diningAreaId;
  final String name;
  final int? capacity;
  final String qrToken;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Do not expose `qrToken` in ordinary customer DTOs.

---

# 85. `QrRotationResult`

```dart
class QrRotationResult {
  final String tableId;
  final String qrToken;
  final String qrUrl;
}
```

---

# 86. `StaffMemberModel`

```dart
class StaffMemberModel {
  final String restaurantId;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? email;
  final StaffRole role;
  final bool isActive;
  final List<BranchAccess> branches;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

`email` may require server aggregation because it belongs to Auth, not public profiles.

Do not assume direct client access to `auth.users`.

---

# 87. `StaffInvitation`

```dart
class StaffInvitation {
  final String id;
  final String restaurantId;
  final String? email;
  final String? phone;
  final StaffRole role;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final List<String> branchIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Never include:

```text
token_hash
```

in client DTO.

---

# 88. `InviteStaffRequest`

```dart
class InviteStaffRequest {
  final String restaurantId;
  final String? email;
  final String? phone;
  final StaffRole role;
  final List<String> branchIds;
}
```

Require at least one of:

```text
email
phone
```

---

# 89. `InviteStaffResult`

```dart
class InviteStaffResult {
  final String invitationId;
  final DateTime expiresAt;
}
```

---

# 90. `PaymentAdminModel`

```dart
class PaymentAdminModel {
  final String id;
  final String orderId;
  final int? orderNumber;
  final PaymentMethod method;
  final String? provider;
  final String? providerOrderId;
  final String? providerPaymentId;
  final int amountMinor;
  final String currencyCode;
  final PaymentStatus status;
  final String? failureCode;
  final String? failureMessage;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Avoid exposing raw `providerMetadata` unless a controlled admin diagnostics screen needs safe fields.

---

# 91. `RefundRequest`

```dart
class RefundRequest {
  final String paymentId;
  final int amountMinor;
  final String? reason;
  final String idempotencyKey;
}
```

---

# 92. `RefundResult`

```dart
class RefundResult {
  final RefundSummary refund;
}
```

---

# 93. `RestaurantSettingsModel`

```dart
class RestaurantSettingsModel {
  final String restaurantId;
  final bool allowDineIn;
  final bool allowTakeaway;
  final bool allowDelivery;
  final bool allowGuestCheckout;
  final bool requirePaymentBeforeKitchen;
  final int serviceChargeBasisPoints;
  final int defaultTaxBasisPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 94. `BranchSettingsModel`

```dart
class BranchSettingsModel {
  final String branchId;
  final String restaurantId;
  final bool? allowDineIn;
  final bool? allowTakeaway;
  final bool? allowDelivery;
  final bool? requirePaymentBeforeKitchen;
  final int? serviceChargeBasisPoints;
  final int? defaultTaxBasisPoints;
  final bool isOrderingPaused;
  final String? orderingPauseReason;
  final int? minimumOrderMinor;
  final int? defaultPrepMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Nullable settings mean:

```text
inherit restaurant setting
```

---

# 95. `BranchOpeningHoursModel`

```dart
class BranchOpeningHoursModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final int weekday;
  final int slotOrder;
  final String? opensAt;
  final String? closesAt;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

For MVP, keep `opensAt`/`closesAt` as normalized `HH:mm:ss` strings or introduce a dedicated time-of-day type.

Do not use `DateTime` for time-only values unless intentionally anchored.

---

# 96. `BranchClosureModel`

```dart
class BranchClosureModel {
  final String id;
  final String restaurantId;
  final String branchId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
  final String? createdBy;
  final DateTime createdAt;
}
```

---

# 97. `CouponModel`

```dart
class CouponModel {
  final String id;
  final String restaurantId;
  final String code;
  final DiscountType discountType;
  final int discountValue;
  final int minimumOrderMinor;
  final int? maximumDiscountMinor;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? maxTotalUses;
  final int? maxUsesPerCustomer;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Interpretation:

```text
fixed:
discountValue = minor units

percentage:
discountValue = basis points
```

---

# 98. `OrderDiscountSnapshot`

```dart
class OrderDiscountSnapshot {
  final String id;
  final String orderId;
  final String? couponId;
  final String? codeSnapshot;
  final DiscountType? discountType;
  final int? discountValueSnapshot;
  final int discountMinor;
  final DateTime createdAt;
}
```

---

# 99. `CustomerAddressModel`

```dart
class CustomerAddressModel {
  final String id;
  final String userId;
  final String? label;
  final String? contactName;
  final String? contactPhone;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? city;
  final String? state;
  final String? postalCode;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Latitude/longitude may use `double` because they are not financial values.

---

# 100. `DeviceTokenModel`

```dart
class DeviceTokenModel {
  final String id;
  final String userId;
  final String token;
  final String? platform;
  final AppClientType appType;
  final bool isActive;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 101. `AuditLogModel`

Admin-only future:

```dart
class AuditLogModel {
  final String id;
  final String? restaurantId;
  final String? branchId;
  final String? actorUserId;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}
```

---

# 102. `RealtimeEventType`

```dart
enum RealtimeEventType {
  insert,
  update,
  delete,
}
```

Map from Supabase raw event.

---

# 103. `OrderRealtimeEvent`

```dart
class OrderRealtimeEvent {
  final RealtimeEventType eventType;
  final String table;
  final String recordId;
  final OrderSummary? record;
  final Map<String, dynamic> oldRecord;
}
```

Repository maps raw Supabase payload to this type.

Views never process raw Realtime payload.

---

# 104. `ConnectionStateModel`

Useful app/domain state:

```dart
enum LiveConnectionState {
  connected,
  reconnecting,
  offline,
}
```

Not persisted.

---

# 105. `ViewState`

Optional common controller UI state:

```dart
enum ViewState {
  initial,
  loading,
  success,
  empty,
  error,
}
```

Use only for UI state, not domain state.

---

# 106. `PaginationCursor`

Generic:

```dart
class PaginationCursor {
  final DateTime createdAt;
  final String id;
}
```

---

# 107. `PageInfo<TCursor>`

```dart
class PageInfo<TCursor> {
  final bool hasMore;
  final TCursor? nextCursor;
}
```

---

# 108. `PagedResult<T, TCursor>`

```dart
class PagedResult<T, TCursor> {
  final List<T> items;
  final PageInfo<TCursor> page;
}
```

---

# 109. `AdminOrderFilter`

```dart
class AdminOrderFilter {
  final String branchId;
  final List<OrderStatus> statuses;
  final List<OrderType> orderTypes;
  final List<PaymentStatus> paymentStatuses;
  final String? search;
  final DateTime? startAt;
  final DateTime? endAt;
  final int limit;
  final PaginationCursor? cursor;
}
```

---

# 110. `ReportRange`

```dart
class ReportRange {
  final DateTime startAt;
  final DateTime endAt;
}
```

---

# 111. `ReportGroupBy`

```dart
enum ReportGroupBy {
  hour,
  day,
  week,
  month,
}
```

Backend string matches enum name.

---

# 112. Equality Strategy

Recommended options:

```text
Equatable
freezed
manual ==/hashCode
```

Choose one project-wide.

For AI-generated implementation, recommended:

```text
freezed + json_serializable
```

only if the project intentionally adds these dependencies.

Otherwise use:

```text
plain immutable Dart classes
factory fromJson
toJson
copyWith
```

Do not mix strategies randomly.

---

# 113. Recommended Model Style

Use immutable fields:

```dart
final
```

Constructors:

```dart
const
```

when possible.

Models should not contain repository/network logic.

---

# 114. `copyWith`

Models frequently mutated in UI state should expose:

```dart
copyWith(...)
```

Useful:

```text
CartItem
CheckoutDraft
Product form draft
Filter models
Context models
```

Not mandatory for all server snapshots.

---

# 115. Serialization Strategy

Recommended project-wide choice:

Option A:

```text
manual fromJson/toJson
```

Pros:

```text
no codegen
transparent
AI-friendly
```

Option B:

```text
json_serializable/freezed
```

Pros:

```text
less boilerplate
safer generated mapping
```

Whichever is selected must be used consistently.

---

# 116. Manual `fromJson` Rules

Required String:

```dart
final id = json['id'] as String;
```

Nullable String:

```dart
final name = json['name'] as String?;
```

Integer from Postgres:

Supabase JSON generally returns integer numeric values as Dart-compatible numbers.

Parse robustly:

```dart
int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'Expected integer, got $value',
  );
}
```

This is useful for `bigint` / numeric interoperability.

---

# 117. Timestamp Parser

Central helper:

```dart
DateTime readDateTime(
  dynamic value,
) {
  if (value is! String) {
    throw FormatException(
      'Expected timestamp string',
    );
  }

  return DateTime.parse(value);
}
```

Nullable:

```dart
DateTime? readNullableDateTime(
  dynamic value,
) {
  if (value == null) return null;
  return readDateTime(value);
}
```

---

# 118. JSON List Parser

Never blindly cast nested lists.

Example:

```dart
final items = (json['items'] as List<dynamic>? ?? const [])
    .map(
      (e) => OrderItemSnapshot.fromJson(
        e as Map<String, dynamic>,
      ),
    )
    .toList();
```

---

# 119. Unknown Fields

Clients should ignore unknown response fields.

This allows additive backend changes.

---

# 120. Missing Required Fields

Required contract field missing:

```text
parsing/domain error
```

Do not silently invent default IDs/prices/status.

---

# 121. Null vs Empty String

Nullable backend field:

```text
null
```

Prefer not to encode missing value as:

```text
""
```

Parser may normalize blank user-entered optional fields to null before submission.

---

# 122. Local Model Versioning

Every persisted local complex object should include:

```text
version
```

Example cart:

```json
{
  "version": 1
}
```

If local schema changes:

```text
migrate
or
clear safely
```

---

# 123. Local Storage Models

Persist only:

```text
cart
customer restaurant context
merchant context
pending checkout
pending payment recovery
small preferences
```

Do not persist:

```text
auth access token manually
service key
payment secret
raw card data
webhook payloads
```

Supabase SDK manages its auth session.

---

# 124. Product Form Draft Model

Recommended admin local form model:

```dart
class ProductFormDraft {
  final String? id;
  final String name;
  final String? description;
  final String? sku;
  final String? categoryId;
  final int? basePriceMinor;
  final int? taxBasisPointsOverride;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final bool isActive;
  final int sortOrder;
  final int? preparationMinutes;
  final List<String> modifierGroupIds;
}
```

This is not the same as persisted `AdminProductModel`.

---

# 125. Category Form Draft

```dart
class CategoryFormDraft {
  final String? id;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;
}
```

---

# 126. Modifier Group Form Draft

```dart
class ModifierGroupFormDraft {
  final String? id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final List<ModifierFormDraft> modifiers;
}
```

---

# 127. Modifier Form Draft

```dart
class ModifierFormDraft {
  final String? id;
  final String name;
  final int priceDeltaMinor;
  final int sortOrder;
  final bool isAvailable;
  final bool isActive;
}
```

---

# 128. Table Form Draft

```dart
class TableFormDraft {
  final String? id;
  final String name;
  final String? diningAreaId;
  final int? capacity;
  final bool isActive;
}
```

No client-supplied QR token.

---

# 129. Staff Invite Form Draft

```dart
class StaffInviteFormDraft {
  final String? email;
  final String? phone;
  final StaffRole role;
  final List<String> branchIds;
}
```

---

# 130. Refund Form Draft

```dart
class RefundFormDraft {
  final int amountMinor;
  final String? reason;
}
```

The idempotency key is created when submitting the logical operation.

---

# 131. Customer Phone Auth Draft

```dart
class PhoneAuthDraft {
  final String countryCode;
  final String nationalNumber;
}
```

Derived normalized:

```text
+919876543210
```

---

# 132. Model Responsibility Rule

A model may contain:

```text
data
pure computed properties
copyWith
serialization
simple validation helpers
```

A model must not:

```text
call Supabase
navigate
show snackbar/dialog
read GetX dependencies
call payment gateway
```

---

# 133. Computed Money Properties

Okay:

```dart
int get cartLinePreviewMinor;
```

Not okay:

```dart
Future<int> fetchAuthoritativeTotal();
```

Server is authoritative.

---

# 134. Domain Validation vs Server Validation

Local/domain model may validate for UX:

```text
quantity >= 1
modifier selection
form required fields
```

But backend revalidates.

Do not treat local validation as security.

---

# 135. Model Immutability

Preferred:

```text
immutable domain models
```

Controller replaces state using:

```text
copyWith
new list
Rx assignment
```

Avoid mutating deeply shared model instances.

---

# 136. Cart Mutation Rule

Even if `CartItem` is immutable:

```text
increase quantity
→ replace item with copyWith(quantity: n)
```

This improves predictable GetX updates.

---

# 137. Admin Realtime Merge Rule

Merge by:

```text
order.id
```

Do not merge by:

```text
order_number
table_id
```

UUID is canonical identity.

---

# 138. Human Order Number

Type:

```dart
int orderNumber;
```

Used for display only.

Do not use as private lookup identity.

---

# 139. Public ID Rule

Backend resource identity:

```text
UUID String
```

Human display:

```text
order number
table name
restaurant name
```

---

# 140. Model Security Rule

Never create client models containing server-only secrets such as:

```text
Supabase service role
gateway secret
webhook secret
private signing key
staff invitation token hash
```

---

# 141. Customer-Safe Payment Model

Customer UI needs:

```text
method
amount
currency
status
paid_at
refunded_at
```

Customer UI does not need:

```text
provider metadata
failure internals
gateway secret fields
```

---

# 142. Kitchen-Safe Order Model

Kitchen model should contain:

```text
order number
table/order type
status
elapsed timestamps
items
modifiers
notes
```

It should not require:

```text
customer phone
refund data
provider IDs
reports
```

---

# 143. Role-Specific DTO Principle

Where privacy matters, prefer server-shaped DTOs:

```text
CustomerOrderDetails
KitchenOrder
CashierOrderDetails
ManagerOrderDetails
```

rather than always returning a huge object and hiding fields in Flutter.

MVP may share models where safe, but backend should never overexpose sensitive data unnecessarily.

---

# 144. Example `ProductModel.fromJson`

```dart
factory ProductModel.fromJson(
  Map<String, dynamic> json,
) {
  return ProductModel(
    id: json['id'] as String,
    categoryId:
        json['category_id'] as String,
    name: json['name'] as String,
    description:
        json['description'] as String?,
    basePriceMinor:
        readInt(json['base_price_minor']),
    imagePath:
        json['image_path'] as String?,
    isVeg:
        json['is_veg'] as bool?,
    isAvailable:
        json['is_available'] as bool,
    sortOrder:
        readInt(json['sort_order']),
    preparationMinutes:
        json['preparation_minutes'] == null
            ? null
            : readInt(
                json['preparation_minutes'],
              ),
    tags:
        (json['tags'] as List<dynamic>? ??
                const [])
            .map((e) => e as String)
            .toList(),
    modifierGroups:
        (json['modifier_groups']
                    as List<dynamic>? ??
                const [])
            .map(
              (e) =>
                  ModifierGroupModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
  );
}
```

---

# 145. Example `CreateOrderRequest.toJson`

```dart
Map<String, dynamic> toJson() {
  return {
    'branch_id': branchId,
    'table_id': tableId,
    'order_type':
        orderTypeToJson(orderType),
    'idempotency_key':
        idempotencyKey,
    'customer_name':
        customerName,
    'customer_phone':
        customerPhone,
    'customer_note':
        customerNote,
    'coupon_code':
        couponCode,
    'items': items
        .map((item) => item.toJson())
        .toList(),
  };
}
```

RPC call:

```dart
supabase.rpc(
  'create_order',
  params: {
    'p_request': request.toJson(),
  },
);
```

---

# 146. Example `ApiResult<T>` Parsing

Recommended repository helper:

```dart
ApiResult<T> parseApiResult<T>(
  Map<String, dynamic> json,
  T Function(
    Map<String, dynamic> data,
  ) parseData,
) {
  final ok = json['ok'] as bool;

  if (ok) {
    return ApiResult(
      ok: true,
      data: parseData(
        json['data']
            as Map<String, dynamic>,
      ),
      error: null,
    );
  }

  return ApiResult(
    ok: false,
    data: null,
    error: ApiError.fromJson(
      json['error']
          as Map<String, dynamic>,
    ),
  );
}
```

---

# 147. Model-Level Formatting Rule

Models should not format:

```text
₹892.50
12 Sep 2026
2 minutes ago
```

Use formatter utilities.

Model contains raw values.

---

# 148. Money Formatter Input

Formatter accepts:

```dart
int minor;
String currencyCode;
```

No model-specific formatting methods required.

---

# 149. Date Formatter Input

Formatter accepts:

```dart
DateTime
```

plus optional timezone/context.

---

# 150. Realtime Serialization Rule

Realtime update may provide partial/old record behavior depending event/config.

Repository should not assume a complete aggregate DTO.

Recommended:

```text
use event as signal
refetch aggregate where needed
```

Especially:

```text
customer order tracking
order detail
KDS complex item content
```

---

# 151. Admin Live Order Optimization

`AdminActiveOrder` may come from:

```text
RPC/view
```

rather than raw `orders` row.

Realtime order row can trigger:

```text
refetch active-order aggregate
```

This avoids trying to encode item previews in the `orders` table.

---

# 152. Form Models vs Persisted Models

Do not bind persisted models directly to mutable text fields if it causes mutation complexity.

Preferred:

```text
Persisted model
→ FormDraft
→ Controller
→ Repository payload
```

---

# 153. DTO vs Form Payload

Example:

```text
AdminProductModel
```

contains:

```text
created_at
updated_at
```

But product save request should not include those.

Use explicit request payload.

---

# 154. `CreateProductRequest`

```dart
class CreateProductRequest {
  final String restaurantId;
  final String branchId;
  final String categoryId;
  final String name;
  final String? description;
  final String? sku;
  final int basePriceMinor;
  final int? taxBasisPointsOverride;
  final String? imagePath;
  final bool? isVeg;
  final bool isAvailable;
  final bool isActive;
  final int sortOrder;
  final int? preparationMinutes;
}
```

---

# 155. `UpdateProductRequest`

Same editable fields, but identity is separate:

```dart
class UpdateProductRequest {
  final String productId;
  // editable fields...
}
```

Do not allow request to change tenant identity casually.

---

# 156. `CreateCategoryRequest`

```dart
class CreateCategoryRequest {
  final String restaurantId;
  final String branchId;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;
}
```

---

# 157. `UpdateCategoryRequest`

```dart
class UpdateCategoryRequest {
  final String categoryId;
  final String name;
  final String? description;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;
}
```

---

# 158. `CreateTableRequest`

```dart
class CreateTableRequest {
  final String restaurantId;
  final String branchId;
  final String? diningAreaId;
  final String name;
  final int? capacity;
  final bool isActive;
}
```

No QR token.

---

# 159. `UpdateTableRequest`

```dart
class UpdateTableRequest {
  final String tableId;
  final String? diningAreaId;
  final String name;
  final int? capacity;
  final bool isActive;
}
```

---

# 160. `ChangeOrderStatusRequest`

```dart
class ChangeOrderStatusRequest {
  final String orderId;
  final OrderStatus newStatus;
  final String? reason;
}
```

---

# 161. `OrderStatusChangeResult`

```dart
class OrderStatusChangeResult {
  final String orderId;
  final OrderStatus oldStatus;
  final OrderStatus newStatus;
  final DateTime updatedAt;
}
```

---

# 162. `CancelOrderResult`

```dart
class CancelOrderResult {
  final String orderId;
  final OrderStatus status;
  final DateTime cancelledAt;
  final bool refundRequired;
}
```

---

# 163. `CashPaymentConfirmationResult`

```dart
class CashPaymentConfirmationResult {
  final PaymentSummary payment;
}
```

---

# 164. `OrderPaymentState`

Useful derived domain model:

```dart
class OrderPaymentState {
  final bool required;
  final PaymentStatus? status;
  final PaymentMethod? method;
}
```

---

# 165. `NotificationPayload`

```dart
class NotificationPayload {
  final String type;
  final String? orderId;
  final String? branchId;
  final Map<String, dynamic> extra;
}
```

Known types:

```text
order_ready
new_order
payment_confirmed
order_cancelled
refund_processed
```

---

# 166. Notification Routing

Do not put navigation logic inside model.

Controller/service maps:

```text
type + IDs
→ route
```

---

# 167. `AppEnvironment`

Configuration model may include:

```dart
class AppEnvironment {
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String orderBaseUrl;
  final String environmentName;
}
```

Do not include server secrets.

---

# 168. `FeatureFlags`

Safe config:

```dart
class FeatureFlags {
  final bool deliveryEnabled;
  final bool loyaltyEnabled;
  final bool couponsEnabled;
  final bool onlinePaymentEnabled;
}
```

Can come from server config later.

---

# 169. `AppConfig`

```dart
class AppConfig {
  final bool maintenance;
  final String? minSupportedVersion;
  final FeatureFlags features;
}
```

---

# 170. Model Package Dependency Rule

`app_models` should depend on:

```text
Dart standard library
optional serialization/equality packages
```

It should not depend on:

```text
GetX
Supabase Flutter
Flutter widgets
payment SDK
```

This keeps models reusable/testable.

---

# 171. UI-Specific View Models

If needed, feature layer can create:

```text
ProductCardViewModel
OrderTimelineStep
DashboardMetricViewModel
```

These belong in app feature/UI layer, not shared backend model package.

---

# 172. `OrderTimelineStep`

Example UI model:

```dart
class OrderTimelineStep {
  final String label;
  final bool completed;
  final bool current;
}
```

Derived from `OrderStatus`.

Not serialized.

---

# 173. `DashboardMetricViewModel`

UI only:

```dart
class DashboardMetricViewModel {
  final String label;
  final String displayValue;
  final String? helperText;
}
```

Formatting happens before constructing this.

---

# 174. Model Tests

Every parser must test:

```text
valid full JSON
valid nullable JSON
empty arrays
invalid enum
missing required field
timestamp parsing
integer parsing
```

---

# 175. Money Model Tests

Test:

```text
0
1
19950
very large safe bigint value used by app
```

Ensure no floating conversion.

---

# 176. Enum Tests

Test every backend value.

Example:

```text
awaiting_payment
partially_refunded
dine_in
```

---

# 177. Local Cart Tests

Test:

```text
serialize
restore
merge
different modifiers
different note
version mismatch
corrupt JSON
```

---

# 178. Order Model Tests

Test:

```text
dine-in with table
takeaway without table
completed timestamps
cancelled timestamps
payment null
```

---

# 179. Dashboard Model Tests

Test:

```text
empty topProducts
zero sales
multiple payment methods
```

---

# 180. Model Compatibility Rule

When backend adds optional field:

```text
old app should continue working
```

When backend changes required enum/value:

```text
requires coordinated app update
```

---

# 181. Backward-Compatible Parsing

Ignore unknown keys.

Do not reject entire object because extra fields exist.

---

# 182. Breaking Model Changes

Examples:

```text
renaming total_minor
changing int to string
changing order status meaning
removing required id
```

Require API contract version change or coordinated rollout.

---

# 183. Recommended Dart Directory

```text
packages/app_models/lib/
├── app_models.dart
│
├── enums/
│   ├── staff_role.dart
│   ├── order_type.dart
│   ├── order_status.dart
│   ├── payment_status.dart
│   ├── payment_method.dart
│   ├── refund_status.dart
│   ├── discount_type.dart
│   └── app_client_type.dart
│
├── common/
│   ├── api_error.dart
│   ├── api_result.dart
│   ├── pagination_cursor.dart
│   └── page_info.dart
│
├── auth/
│   └── profile_model.dart
│
├── restaurant/
│   ├── restaurant_summary.dart
│   ├── branch_summary.dart
│   ├── dining_table_summary.dart
│   ├── qr_context.dart
│   ├── restaurant_membership.dart
│   └── branch_access.dart
│
├── menu/
│   ├── restaurant_menu.dart
│   ├── category_model.dart
│   ├── product_model.dart
│   ├── modifier_group_model.dart
│   └── modifier_model.dart
│
├── cart/
│   ├── selected_modifier.dart
│   ├── cart_item.dart
│   └── cart_state.dart
│
├── order/
│   ├── create_order_request.dart
│   ├── create_order_result.dart
│   ├── order_summary.dart
│   ├── order_details.dart
│   ├── order_item_snapshot.dart
│   ├── order_status_event.dart
│   └── order_page.dart
│
├── payment/
│   ├── payment_summary.dart
│   ├── refund_summary.dart
│   ├── create_payment_request.dart
│   └── create_payment_result.dart
│
├── admin/
│   ├── admin_product_model.dart
│   ├── staff_member_model.dart
│   ├── admin_active_order.dart
│   ├── kds_order.dart
│   ├── dashboard_summary.dart
│   └── sales_report.dart
│
├── realtime/
│   └── order_realtime_event.dart
│
└── local/
    ├── checkout_recovery_state.dart
    ├── payment_recovery_state.dart
    ├── merchant_context.dart
    └── customer_restaurant_context.dart
```

---

# 184. Barrel Export

`app_models.dart` may export all stable public models:

```dart
export 'enums/order_status.dart';
export 'menu/product_model.dart';
export 'order/order_summary.dart';
```

Avoid exposing internal helper parsers unnecessarily.

---

# 185. AI Coding Rule — Do Not Invent Fields

If a model field is not in:

```text
DATABASE_SCHEMA.sql
API_CONTRACTS.md
or this document
```

do not add it without explicitly updating the contract.

---

# 186. AI Coding Rule — No Dynamic Everywhere

Avoid:

```dart
Map<String, dynamic>
```

as the main application model.

Use typed models.

Dynamic maps are acceptable only for:

```text
raw JSON boundary
provider-specific extra metadata
audit metadata
generic error details
```

---

# 187. AI Coding Rule — No Double for Money

Never generate:

```dart
double price;
double total;
```

Use:

```dart
int priceMinor;
int totalMinor;
```

---

# 188. AI Coding Rule — No Flutter Imports in Shared Models

Shared models should not import:

```text
package:flutter/material.dart
package:get/get.dart
package:supabase_flutter/supabase_flutter.dart
```

unless explicitly separated into UI layer.

---

# 189. AI Coding Rule — Immutable First

Prefer:

```dart
final
const constructor
copyWith
```

---

# 190. AI Coding Rule — Parse at Repository Boundary

Raw backend JSON should become typed DTO/model inside repository/data layer.

Controllers should receive typed objects.

Views should never parse JSON.

---

# 191. AI Coding Rule — Error Parsing

Backend `error.code` must remain exact string contract.

Do not localize or rename backend codes inside data model.

UI may map code to localized copy.

---

# 192. AI Coding Rule — Sensitive Fields

Do not add server-only fields to client DTO for convenience.

Examples:

```text
token_hash
service_role
provider_secret
webhook_secret
raw auth password
```

---

# 193. AI Coding Rule — Historical Snapshots

Order UI must use:

```text
OrderItemSnapshot
OrderItemModifierSnapshot
```

not current `ProductModel` to display historical order.

---

# 194. AI Coding Rule — Context Is Not Authorization

Models:

```text
MerchantContext
CustomerRestaurantContext
```

must not be treated as security proof.

---

# 195. AI Coding Rule — Realtime Is Not Aggregate Truth

Raw Realtime row is not a replacement for:

```text
OrderDetails
KdsOrder
AdminActiveOrder
```

Refetch aggregate when needed.

---

# 196. AI Coding Rule — Local Prices Are Preview

Fields such as:

```text
basePriceMinorPreview
modifier price preview
cart subtotal preview
```

must never be sent as trusted server totals.

---

# 197. AI Coding Rule — Optional IDs

Historical snapshot references can be null:

```text
productId
modifierId
couponId
```

because source records may later be removed/archived.

Snapshot names/prices remain required.

---

# 198. AI Coding Rule — Unknown Enum

Unknown enum should result in a controlled parse error.

Do not silently map unknown order status to:

```text
placed
```

or another valid state.

---

# 199. Final Shared Model Inventory

Core MVP shared models:

```text
ApiError
ApiResult
ProfileModel

StaffRole
OrderType
OrderStatus
PaymentStatus
PaymentMethod
RefundStatus
DiscountType
AppClientType

RestaurantSummary
BranchSummary
DiningTableSummary
QrOrderingOptions
QrContext

RestaurantMenu
CategoryModel
ProductModel
ModifierGroupModel
ModifierModel

SelectedModifier
CartItem
CartState
CheckoutDraft

CreateOrderItemRequest
CreateOrderRequest
CreateOrderResult
CreateOrderPaymentState
OrderResourceChange

MoneySummary
OrderSummary
OrderItemSnapshot
OrderItemModifierSnapshot
OrderStatusEvent
OrderDetails
CustomerOrderHistoryItem
OrderCursor
OrderPage

PaymentSummary
RefundSummary
CreatePaymentRequest
PaymentCheckoutData
CreatePaymentResult

RestaurantMembership
BranchAccess
MerchantContext
CustomerRestaurantContext

AdminProductModel
AdminCategoryModel
AdminModifierGroupModel
AdminModifierModel
DiningAreaModel
DiningTableModel
QrRotationResult

StaffMemberModel
StaffInvitation
InviteStaffRequest
InviteStaffResult

AdminActiveOrder
KdsOrder
KdsOrderItem

DashboardSummary
DashboardStatusCounts
PaymentMethodTotal
TopProductMetric
SalesReport
SalesReportSummary
SalesSeriesPoint

RestaurantSettingsModel
BranchSettingsModel
BranchOpeningHoursModel
BranchClosureModel

CouponModel
OrderDiscountSnapshot
CustomerAddressModel
DeviceTokenModel

OrderRealtimeEvent
PaymentRecoveryState
CheckoutRecoveryState
```

---

# 200. Definition of DATA_MODELS Complete

The data-model layer is correctly implemented when:

```text
[ ] every API response has a typed model
[ ] every API request has an explicit request model
[ ] backend snake_case maps consistently to Dart camelCase
[ ] all money uses integer minor units
[ ] timestamps use DateTime
[ ] nullable fields match backend
[ ] arrays default to empty lists
[ ] enums map explicitly
[ ] unknown enum values fail safely
[ ] local cart models are versioned
[ ] historical order snapshots are separate from current products
[ ] admin/customer privacy boundaries are respected
[ ] raw JSON does not leak into Views
[ ] models contain no network/navigation logic
[ ] model tests cover parsing and edge cases
```

The central model rule is:

```text
Backend JSON
→ Typed Model
→ Controller
→ UI
```

not:

```text
Backend JSON
→ dynamic maps everywhere
→ fragile UI
```
