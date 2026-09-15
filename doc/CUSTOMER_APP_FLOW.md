# CUSTOMER_APP_FLOW.md
## QR Restaurant Ordering Platform — Flutter + GetX + MVC + Supabase

> Complete customer application flow and implementation blueprint for the QR restaurant ordering platform.
>
> This document focuses only on the **customer-facing application** and explains the complete user journey, screen flow, GetX architecture, repositories, services, Supabase interaction, realtime behavior, payment flow, local state, errors, analytics, and QA requirements.

---

# 1. Customer App Goal

The customer app should let a person:

- Scan a restaurant/table QR code
- Open the restaurant immediately
- Browse the menu
- Search products
- View product details
- Select required/optional modifiers
- Add items to cart
- Update quantities
- Add notes
- Choose dine-in / takeaway / delivery
- Confirm table or pickup context
- Place an order
- Pay by cash or online payment
- Track order status in realtime
- View current and previous orders
- Sign in optionally
- Save profile information
- Save addresses later
- Use coupons later
- Use loyalty later

The ordering flow must be:

```text
FAST
SIMPLE
SECURE
LOW-FRICTION
```

Do not make customers complete unnecessary onboarding before seeing the menu.

---

# 2. Primary Product Principle

The first customer interaction should be:

```text
SCAN QR
   ↓
SEE MENU
```

Not:

```text
SCAN QR
   ↓
DOWNLOAD APP
   ↓
CREATE ACCOUNT
   ↓
VERIFY EMAIL
   ↓
COMPLETE PROFILE
   ↓
SEE MENU
```

For restaurant QR ordering, immediate access is essential.

---

# 3. Customer Application Platforms

Recommended:

```text
Flutter Android
Flutter iOS
Flutter Web
```

Best UX:

```text
QR
 ↓
Universal / App Link
 ↓
App installed?
   │
   ├── YES → open native Flutter app
   │
   └── NO  → open Flutter Web / web ordering
```

Do not force installation for table ordering.

---

# 4. Customer App High-Level Architecture

```text
Customer
   ↓
Flutter View
   ↓
GetX Controller
   ↓
Repository
   ↓
Supabase
   │
   ├── Auth
   ├── PostgreSQL
   ├── RPC
   ├── Realtime
   ├── Storage
   └── Edge Functions
```

Recommended code flow:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Supabase
```

Critical server logic:

```text
Controller
 ↓
Repository
 ↓
RPC / Edge Function
 ↓
Supabase/PostgreSQL
```

---

# 5. Customer App Folder Structure

```text
lib/
│
├── main.dart
│
├── app/
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   │
│   ├── bindings/
│   │   └── initial_binding.dart
│   │
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── formatters/
│   ├── helpers/
│   ├── services/
│   ├── storage/
│   ├── network/
│   └── widgets/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── dto/
│
└── features/
    ├── splash/
    ├── deep_link/
    ├── auth/
    ├── qr/
    ├── restaurant/
    ├── menu/
    ├── search/
    ├── product/
    ├── cart/
    ├── checkout/
    ├── payment/
    ├── order_tracking/
    ├── order_history/
    ├── profile/
    ├── addresses/
    ├── coupons/
    └── loyalty/
```

---

# 6. Core Customer Routes

Recommended routes:

```text
/splash
/qr
/restaurant
/menu
/product/:id
/cart
/checkout
/payment
/order/:id
/orders
/profile
/address
/coupons
```

Possible Flutter/GetX constants:

```dart
abstract class AppRoutes {
  static const splash = '/splash';
  static const qr = '/qr';
  static const menu = '/menu';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const payment = '/payment';
  static const orders = '/orders';
  static const profile = '/profile';

  static String product(String id) =>
      '/product/$id';

  static String order(String id) =>
      '/order/$id';
}
```

---

# 7. Main Customer Journey

```text
START
 ↓
Splash
 ↓
Resolve deep link / QR context
 ↓
Anonymous authentication if needed
 ↓
Restaurant + branch + table context
 ↓
Menu
 ↓
Product detail
 ↓
Modifiers
 ↓
Cart
 ↓
Checkout
 ↓
Secure create_order RPC
 ↓
Payment?
 ├── Cash / Pay later
 │      ↓
 │    Order placed
 │
 └── Online
        ↓
      Payment
        ↓
      Webhook verified
        ↓
      Order placed

 ↓
Realtime tracking
 ↓
Ready / Served
 ↓
Completed
 ↓
Receipt / history
```

---

# 8. App Startup Flow

When app opens:

```text
main()
 ↓
Supabase.initialize()
 ↓
InitialBinding
 ↓
SplashPage
 ↓
StartupController
```

Startup controller checks:

```text
1. Existing Supabase session
2. Pending deep link
3. Saved branch/table context
4. Current active order
5. Local cart
6. Connectivity
```

---

# 9. Splash Decision Tree

```text
App started
   ↓
Is there a deep link?
   │
   ├── YES
   │     ↓
   │   Resolve QR / restaurant
   │
   └── NO
         ↓
     Active restaurant context?
         │
         ├── YES → Menu
         └── NO  → QR/Home
```

If active order exists:

```text
show active order shortcut
```

but do not prevent normal browsing.

---

# 10. Startup Controller

Example responsibilities:

```text
restore auth
restore app session
parse link
restore branch context
restore cart
find active order
route user
```

Suggested:

```dart
class StartupController extends GetxController {
  final SessionService sessionService;
  final DeepLinkService deepLinkService;
  final LocalCartService cartService;

  final isLoading = true.obs;

  StartupController({
    required this.sessionService,
    required this.deepLinkService,
    required this.cartService,
  });

  @override
  void onReady() {
    super.onReady();
    bootstrap();
  }

  Future<void> bootstrap() async {
    try {
      await sessionService.ensureSession();

      final link =
          await deepLinkService.getInitialLink();

      if (link != null) {
        await handleLink(link);
        return;
      }

      if (sessionService.hasRestaurantContext) {
        Get.offAllNamed(AppRoutes.menu);
        return;
      }

      Get.offAllNamed(AppRoutes.qr);
    } finally {
      isLoading.value = false;
    }
  }
}
```

---

# 11. Customer Authentication Strategy

Recommended customer auth:

```text
Anonymous first
Optional phone OTP later
```

Why anonymous:

```text
low friction
auth.uid() still exists
RLS works
order ownership works
cart/order isolation works
```

Flow:

```text
Customer opens app
 ↓
No session
 ↓
signInAnonymously()
 ↓
auth.uid() created
 ↓
Browse/order
```

---

# 12. SessionService

Purpose:

```text
ensure authenticated customer session
watch auth changes
expose current user ID
handle logout
```

Example:

```dart
class SessionService extends GetxService {
  SupabaseClient get client =>
      Supabase.instance.client;

  String? get userId =>
      client.auth.currentUser?.id;

  Future<void> ensureSession() async {
    if (client.auth.currentSession != null) {
      return;
    }

    await client.auth.signInAnonymously();
  }
}
```

---

# 13. Optional Account Upgrade

After customer orders:

```text
Save your orders and rewards
 ↓
Verify phone
```

Recommended flow:

```text
Anonymous
 ↓
Phone OTP
 ↓
Identity upgrade/linking strategy
```

Exact identity-linking implementation depends on Supabase Auth capabilities and project policy.

Do not duplicate order ownership accidentally.

---

# 14. Deep Link Format

Recommended:

```text
https://order.example.com/q/<qr_token>
```

Possible native app association:

```text
order.example.com
```

QR contains only stable public resolver URL.

---

# 15. DeepLinkService

Responsibilities:

```text
read initial link
listen for runtime links
extract qr token
validate route format
send token to QR resolver
```

Never trust the token result locally.

Always call backend resolver.

---

# 16. QR Scanner Screen

Customer can also manually scan inside app.

Screen:

```text
┌─────────────────────────┐
│ Scan restaurant QR      │
│                         │
│       [ CAMERA ]        │
│                         │
│ Point camera at QR code │
└─────────────────────────┘
```

Possible package:

```text
mobile_scanner
```

---

# 17. QrController

Responsibilities:

```text
camera scanning state
duplicate scan prevention
extract QR token
resolve token through repository
save context
navigate to menu
show invalid QR error
```

Pseudo-flow:

```dart
Future<void> handleQr(String rawValue) async {
  if (isResolving.value) return;

  final token = parseQrToken(rawValue);

  if (token == null) {
    showInvalidQr();
    return;
  }

  await resolve(token);
}
```

---

# 18. QR Scan Debouncing

Camera may return same QR repeatedly.

Use:

```text
isResolving
lastScannedToken
short debounce
```

Otherwise:

```text
resolve_qr called 10 times
```

for one scan.

---

# 19. QR Resolver Repository

```text
QrController
 ↓
RestaurantRepository.resolveQr()
 ↓
Supabase RPC resolve_qr
```

Example:

```dart
Future<QrContext> resolveQr(
  String token,
) async {
  final response =
      await supabase.rpc(
    'resolve_qr',
    params: {
      'p_qr_token': token,
    },
  );

  return QrContext.fromJson(
    response,
  );
}
```

---

# 20. Restaurant Context

Store:

```text
restaurantId
restaurantName
restaurantLogoPath
branchId
branchName
tableId
tableName
currencyCode
orderType
```

Service:

```dart
class RestaurantContextService
    extends GetxService {

  final restaurantId = RxnString();
  final branchId = RxnString();
  final tableId = RxnString();
  final currencyCode = 'INR'.obs;

  bool get hasContext =>
      restaurantId.value != null &&
      branchId.value != null;
}
```

---

# 21. Context Security

Flutter context is only convenience.

Backend still validates:

```text
branch exists
table belongs to branch
restaurant active
table active
product belongs to branch
```

Never treat local context as authorization.

---

# 22. Changing Restaurant Context

If customer scans another restaurant:

```text
current cart empty?
   │
   ├── YES → switch immediately
   │
   └── NO  → ask to clear cart
```

Because:

```text
Restaurant A products
```

cannot be ordered at:

```text
Restaurant B
```

---

# 23. Context Switch Confirmation

UI:

```text
You already have items from Pizza House.

Scanning this QR will clear your current cart.

[Cancel]
[Switch restaurant]
```

If user confirms:

```text
clear cart
replace restaurant context
load new menu
```

---

# 24. Invalid QR States

Possible:

```text
QR malformed
QR token unknown
table disabled
branch disabled
restaurant disabled
network unavailable
backend error
```

User-facing examples:

```text
This QR code is not valid.
This table is currently unavailable.
This restaurant is not accepting orders right now.
Couldn’t connect. Try again.
```

---

# 25. Menu Screen

Primary customer screen.

Recommended layout:

```text
Restaurant header
Table / order type
Search
Category tabs
Promotions later
Product list
Floating cart button
```

Example:

```text
Pizza House
Table 12

[ Search dishes... ]

Popular  Pizza  Burger  Drinks

Farmhouse Pizza       ₹399
Veg Supreme           ₹349
Cheese Burger         ₹199

[ View Cart • 3 items • ₹947 ]
```

---

# 26. Menu Data Model

Recommended top-level:

```text
RestaurantMenu
  restaurant
  branch
  categories[]
    products[]
      modifierGroups[]
```

This avoids many network calls.

---

# 27. MenuRepository

Prefer:

```text
get_public_menu(branch_id)
```

instead of:

```text
get categories
then products
then modifiers individually
```

Repository:

```dart
Future<RestaurantMenu> getMenu(
  String branchId,
) async {
  final data =
      await supabase.rpc(
    'get_public_menu',
    params: {
      'p_branch_id': branchId,
    },
  );

  return RestaurantMenu.fromJson(
    data,
  );
}
```

---

# 28. MenuController

Responsibilities:

```text
load menu
refresh menu
manage selected category
search/filter
handle menu errors
expose cart badge
```

Suggested state:

```dart
final state = ViewState.initial.obs;
final menu = Rxn<RestaurantMenu>();
final selectedCategoryId = RxnString();
final searchQuery = ''.obs;
```

---

# 29. Menu Loading States

Handle:

```text
initial
loading
success
empty
error
```

Example:

```dart
enum ViewState {
  initial,
  loading,
  success,
  empty,
  error,
}
```

---

# 30. Menu Refresh

Refresh when:

```text
customer pulls to refresh
app returns from background
cart checkout says item changed
menu version changed later
```

Do not subscribe every customer to all product updates for MVP.

---

# 31. Menu Cache

Cache menu locally for:

```text
faster reopen
poor network
better perceived performance
```

But:

```text
checkout always re-validates current prices/availability server-side
```

Cached menu is never financial truth.

---

# 32. Category Navigation

Options:

```text
horizontal tabs
sticky tabs
scroll-to-section
```

Example categories:

```text
Recommended
Starters
Pizza
Burgers
Biryani
Drinks
Desserts
```

---

# 33. Search

Search fields:

```text
product name
description
tags
```

For normal menu size:

```text
client-side search after full menu load
```

is fine.

For huge menus:

```text
server search
```

may be added.

---

# 34. SearchController

Could be part of MenuController.

State:

```dart
final query = ''.obs;

List<Product> get results {
  final q =
      query.value.trim().toLowerCase();

  if (q.isEmpty) return allProducts;

  return allProducts.where((p) {
    return p.name
            .toLowerCase()
            .contains(q) ||
        (p.description ?? '')
            .toLowerCase()
            .contains(q);
  }).toList();
}
```

---

# 35. Product Card

Display:

```text
image
name
short description
veg/non-veg indicator if appropriate
price
availability
add button
```

Example:

```text
Farmhouse Pizza
Tomato, capsicum, onion...
₹399

[Add]
```

---

# 36. Product Detail Page

Display:

```text
large image
name
description
base price
tags
modifier groups
quantity
item note
add to cart
```

---

# 37. Modifier UI

Example:

```text
Choose size *
○ Small
○ Medium +₹50
○ Large +₹100

Add extras
□ Extra Cheese +₹40
□ Olives +₹30
□ Jalapeño +₹20
```

---

# 38. Modifier Group Rules

Each group may have:

```text
min_select
max_select
is_required
```

Examples:

```text
Size:
min 1
max 1
required

Extras:
min 0
max 5
optional
```

Flutter validates for UX.

Server validates again for security.

---

# 39. ProductDetailController

Responsibilities:

```text
selected modifiers
quantity
note
display price preview
modifier validation
add to cart
```

Example state:

```dart
final quantity = 1.obs;

final selectedModifiers =
    <String, Set<String>>{}.obs;

final note = ''.obs;
```

---

# 40. Product Price Preview

Flutter may calculate:

```text
base price
+
selected modifier price
×
quantity
```

for display.

Example:

```text
Pizza ₹300
Large +₹100
Extra Cheese +₹40

₹440 × 2 = ₹880
```

But server recalculates at checkout.

---

# 41. Modifier Validation

Before add:

```text
for each modifier group:
  selected count >= min_select
  selected count <= max_select
```

Show:

```text
Please choose a size.
Choose up to 3 extras.
```

---

# 42. Product Note

Optional:

```text
No onion
Less spicy
Sauce on the side
```

Do not allow unlimited length.

Recommended client limit:

```text
200–500 characters
```

Server should also enforce a limit.

---

# 43. Cart Model

Cart should store:

```text
product ID
product snapshot for display
selected modifier IDs
selected modifier display snapshot
quantity
note
local unit total preview
```

Example:

```dart
class CartItem {
  final String localId;
  final Product product;
  final List<SelectedModifier> modifiers;
  int quantity;
  String? note;
}
```

---

# 44. Why localId?

Two same products can differ:

```text
Burger
+ cheese
```

and:

```text
Burger
+ no cheese
```

They need separate cart rows.

A local cart line ID can derive from:

```text
product ID
sorted modifier IDs
note
```

or use random UUID.

---

# 45. Cart Merge Rules

Merge quantity only when:

```text
same product
same selected modifiers
same note
```

Otherwise keep separate lines.

---

# 46. CartController

Responsibilities:

```text
add item
remove item
increase quantity
decrease quantity
clear cart
calculate preview subtotal
persist cart locally
restore cart
validate restaurant context
```

Suggested:

```dart
class CartController extends GetxController {
  final items = <CartItem>[].obs;

  int get itemCount =>
      items.fold(
        0,
        (sum, item) =>
            sum + item.quantity,
      );

  int get previewSubtotalMinor {
    // local display only
    return 0;
  }
}
```

---

# 47. Persistent Cart

Persist cart locally after every change.

Possible storage:

```text
GetStorage
Hive
Isar
SQLite
```

For small cart:

```text
GetStorage
```

is sufficient.

---

# 48. Cart Persistence Data

Store:

```text
restaurant_id
branch_id
table_id
items
last_updated_at
```

On restore:

```text
if context matches:
  restore

else:
  clear
```

---

# 49. Cart Screen

Recommended:

```text
Restaurant
Table

Items
----------------
Pizza
Large
Extra Cheese
2 × ₹440
₹880

Coke
1 × ₹80
₹80

----------------
Subtotal ₹960

[Proceed to checkout]
```

---

# 50. Cart Item Editing

Customer can:

```text
increase quantity
decrease quantity
remove item
edit modifiers
edit note
```

Editing item should reopen product detail with existing selection.

---

# 51. Empty Cart State

```text
Your cart is empty.

Browse the menu and add something you like.

[Browse menu]
```

---

# 52. Checkout Entry Validation

Before checkout:

```text
cart not empty
restaurant context exists
branch context exists
customer session exists
network available
```

Do not create order while offline.

---

# 53. Checkout Screen

Possible sections:

```text
Order type
Table / pickup
Customer details
Items
Coupon
Payment method
Price summary
Place order
```

---

# 54. Order Type

Possible:

```text
Dine-in
Takeaway
Delivery
```

Available options come from backend restaurant settings.

Do not hardcode all order types as available.

---

# 55. Dine-In Checkout

If QR came from table:

```text
Dine-in
Table 12
```

Do not allow easy manual table switching unless product requires it.

Backend validates table anyway.

---

# 56. Takeaway Checkout

Collect:

```text
customer name
phone optional/required based on rules
pickup time later
```

For MVP:

```text
ASAP pickup
```

is enough.

---

# 57. Delivery Checkout

Later:

```text
address
phone
delivery instructions
delivery fee
zone validation
```

Server determines:

```text
delivery eligibility
delivery fee
```

---

# 58. Customer Details

For guest ordering:

```text
name
phone
```

may be collected at checkout if restaurant requires it.

Do not require email unless needed.

---

# 59. CheckoutController

Responsibilities:

```text
load current checkout context
select order type
collect contact data
select payment method
apply coupon preview
create idempotency key
call create_order
handle changed menu errors
route to payment/tracking
```

---

# 60. Order Request DTO

Client should send:

```json
{
  "branch_id": "...",
  "table_id": "...",
  "order_type": "dine_in",
  "idempotency_key": "...",
  "items": [
    {
      "product_id": "...",
      "quantity": 2,
      "modifier_ids": [
        "...",
        "..."
      ],
      "note": "No onion"
    }
  ],
  "customer_note": "..."
}
```

Do not send trusted:

```text
final total
tax
discount
authoritative unit price
```

---

# 61. Server create_order Response

Example:

```json
{
  "order_id": "...",
  "order_number": 1042,
  "status": "awaiting_payment",
  "currency_code": "INR",
  "subtotal_minor": 85000,
  "tax_minor": 4250,
  "service_charge_minor": 0,
  "discount_minor": 0,
  "total_minor": 89250,
  "payment_required": true
}
```

Flutter must display server totals.

---

# 62. Price Changed Flow

Scenario:

```text
menu loaded at ₹199
restaurant changes to ₹219
customer checks out
```

Server returns updated total or a structured change error.

Recommended UX:

```text
Some prices changed.

Burger
₹199 → ₹219

Your total is now ₹xxx.

[Review cart]
[Continue]
```

Do not silently charge materially changed values without UX handling.

---

# 63. Product Unavailable Flow

Server may return:

```text
PRODUCT_UNAVAILABLE
```

UI:

```text
One item is no longer available.

Cheese Burger

[Remove item]
[Back to cart]
```

---

# 64. Modifier Changed Flow

Server may reject:

```text
modifier removed
modifier sold out
selection rule changed
```

UI should return customer to edit product.

---

# 65. Checkout Idempotency

Before calling create_order:

```text
generate UUID
```

Store it until order result is known.

If network times out:

```text
retry with same idempotency key
```

Do not generate new key on every retry.

---

# 66. Place Order Button

Prevent rapid repeated taps:

```text
isSubmitting = true
disable button
show progress
```

But backend idempotency is still mandatory.

Client button disabling is UX only.

---

# 67. Cash Payment Flow

If restaurant supports pay-later:

```text
Create order
 ↓
status placed
 ↓
payment method cash
 ↓
KDS receives order
```

Customer sees:

```text
Pay at counter / Pay when served
```

depending on restaurant policy.

---

# 68. Online Payment Flow

```text
create_order
 ↓
awaiting_payment
 ↓
create-payment Edge Function
 ↓
provider SDK / checkout
 ↓
customer completes payment
 ↓
webhook verifies
 ↓
payment paid
 ↓
order placed
 ↓
KDS
```

---

# 69. PaymentController

Responsibilities:

```text
request payment session
launch payment UI
listen for SDK callback
show pending state
query server payment/order status
handle cancellation
handle failure
route to tracking on verified success
```

Never mark order paid based only on SDK callback.

---

# 70. Payment Callback vs Webhook

Client callback:

```text
useful UX signal
```

Webhook:

```text
authoritative payment truth
```

If SDK says success but webhook not processed yet:

```text
show "Confirming payment..."
```

Then query order/payment status.

---

# 71. Payment Pending Screen

Example:

```text
Confirming payment...

Please don't close this screen.
```

But do not trap user indefinitely.

Offer:

```text
Check status
Back to order
```

Order should remain discoverable by ID.

---

# 72. Payment Failure

UI:

```text
Payment failed.

Your order has not been sent to the kitchen.

[Try again]
[Choose another payment method]
```

Exact order handling depends on backend rules.

---

# 73. Payment Cancelled

```text
Payment cancelled.
```

Allow:

```text
retry
choose cash if restaurant supports
cancel order
```

Backend controls legal transition.

---

# 74. Payment Unknown State

Network may drop after payment.

Never show:

```text
Payment failed
```

unless verified.

Use:

```text
Checking payment status...
```

because payment may have succeeded.

---

# 75. Order Tracking Screen

Main live screen:

```text
Order #1042
Table 12

✓ Order received
✓ Accepted
● Preparing
○ Ready
○ Served

Estimated status messaging

Items
Payment
Total
```

---

# 76. OrderTrackingController

Responsibilities:

```text
load order
subscribe realtime
update status
refresh manually
handle reconnect
stop subscription on dispose
```

---

# 77. Realtime Tracking

Use:

```text
orders row
```

and optionally:

```text
order_status_history
```

The database is source of truth.

Realtime only signals changes.

---

# 78. Realtime Subscription Flow

```text
screen opens
 ↓
fetch current order
 ↓
subscribe
 ↓
status changes
 ↓
update Rx state
```

If connection drops:

```text
reconnect
 ↓
refetch
```

---

# 79. Customer Order Access

Customer may only read:

```text
orders where customer_id = auth.uid()
```

RLS must enforce this.

Do not rely on:

```text
.eq('id', orderId)
```

as security.

---

# 80. Order Status UI

Possible mapping:

```text
awaiting_payment → Waiting for payment
placed → Order received
accepted → Restaurant accepted
preparing → Preparing your order
ready → Ready
served → Served
completed → Completed
cancelled → Cancelled
```

---

# 81. Order Type-Specific Status UI

Dine-in:

```text
ready → Your order is ready to serve
served → Served
```

Takeaway:

```text
ready → Ready for pickup
completed → Picked up
```

Delivery later:

```text
preparing
ready
out_for_delivery
delivered
```

Delivery may require expanded enum later.

---

# 82. Order Timeline

Use status history if available.

Example:

```text
6:31 PM  Order placed
6:32 PM  Accepted
6:37 PM  Preparing
6:48 PM  Ready
```

---

# 83. Active Order Persistence

Save active order ID locally.

If app restarts:

```text
restore auth
 ↓
load active order
 ↓
show "Track current order"
```

---

# 84. Multiple Active Orders

Possible in some restaurants.

Instead of one:

```text
activeOrderId
```

eventually support:

```text
activeOrders[]
```

For MVP one active order per branch/session may be sufficient.

---

# 85. Order History Screen

Requires user/session ownership.

Display:

```text
Order #1042
Pizza House
₹892.50
Completed
12 Sep 2026

Order #1037
Pizza House
₹430
Completed
11 Sep 2026
```

---

# 86. Order History Pagination

Do not load all orders.

Use:

```text
limit
date range
pagination
```

Example:

```text
20 orders at a time
```

---

# 87. Order Detail History

Show immutable snapshot:

```text
order number
restaurant
branch
table/order type
items
modifier snapshots
price snapshots
tax
discount
total
payment method
status history
date/time
```

Do not regenerate historical details from current menu.

---

# 88. Profile Screen

MVP:

```text
name
phone
avatar later
order history
sign in / verify phone
logout
```

---

# 89. Anonymous Profile UX

If anonymous:

```text
Guest
```

Show:

```text
Verify phone to keep your order history across devices.
```

---

# 90. Phone OTP Flow

Screens:

```text
Enter phone
 ↓
Send OTP
 ↓
Enter OTP
 ↓
Verify
 ↓
Profile
```

Controller handles:

```text
sending
countdown
verification
error
resend
```

---

# 91. Phone Input

Use proper international format.

For India:

```text
+91xxxxxxxxxx
```

Do not store only local digits without country code.

---

# 92. OTP Error States

Examples:

```text
invalid number
too many requests
wrong OTP
expired OTP
network error
```

User-facing messages should be clear but not leak internal security details.

---

# 93. Logout Flow

On logout:

```text
unsubscribe realtime
clear auth session
clear sensitive local user data
decide whether restaurant context remains
clear private order cache
```

Cart behavior depends on product decision.

---

# 94. Address Module Later

Screens:

```text
Address list
Add address
Edit address
Set default
Delete address
```

Delivery checkout references selected address.

---

# 95. Coupon Module Later

Flow:

```text
Enter coupon
 ↓
server validation
 ↓
display preview
 ↓
final create_order revalidates
```

Do not trust coupon preview as final.

---

# 96. Loyalty Module Later

Display:

```text
points balance
earn history
redeem history
available rewards
```

Server validates earn/redemption.

---

# 97. Restaurant Information

Optional screen:

```text
logo
name
address
hours
phone
about
policies
```

Can be opened from menu header.

---

# 98. Opening Status

Display:

```text
Open
Closing soon
Closed
```

But checkout must verify server-side.

Client clock can be wrong.

---

# 99. Restaurant Closed UX

Allow:

```text
view menu
```

but disable ordering if policy requires.

Message:

```text
This restaurant is currently closed for orders.
```

---

# 100. Sold Out UX

Show product:

```text
Sold out
```

instead of removing entirely if business wants visibility.

Prevent Add button.

Server still rechecks.

---

# 101. Image Loading

Use:

```text
cached_network_image
```

or similar.

Provide:

```text
placeholder
error placeholder
cache
```

Avoid blocking menu on image loading.

---

# 102. Image Failure

Product still usable if image fails.

Never make:

```text
image error
```

break ordering.

---

# 103. Currency Formatting

Create centralized formatter.

Example:

```dart
String formatMoney(
  int minor,
  String currency,
)
```

For INR:

```text
89250 → ₹892.50
```

Avoid:

```text
minor / 100
```

scattered throughout UI.

---

# 104. Accessibility

Customer app should support:

```text
large text
screen readers
button labels
adequate tap areas
semantic labels
color contrast
```

Do not communicate order status only by color.

---

# 105. Localization

Future:

```text
English
Hindi
Arabic
other restaurant markets
```

Do not hardcode user-facing strings.

Use localization files.

---

# 106. Menu Translation

If restaurant menu supports multiple languages:

```text
restaurant provides translations
or
AI-assisted translation later
```

Always preserve original menu data.

---

# 107. Error Architecture

Create standardized app errors:

```text
NetworkError
UnauthorizedError
NotFoundError
ValidationError
PaymentError
ServerError
UnknownError
```

Repositories translate raw Supabase exceptions into domain errors.

---

# 108. Repository Error Mapping

Example:

```dart
try {
  ...
} on PostgrestException catch (e) {
  throw ApiException.fromPostgrest(e);
}
```

Controller receives domain-friendly error.

---

# 109. Backend Error Codes

Map:

```text
INVALID_QR
BRANCH_INACTIVE
RESTAURANT_CLOSED
PRODUCT_UNAVAILABLE
INVALID_MODIFIER
COUPON_INVALID
ORDER_DUPLICATE
PAYMENT_FAILED
INVALID_STATUS_TRANSITION
```

to UX.

---

# 110. Global Error Widget

Reusable:

```text
Something went wrong.

[Try again]
```

but feature-specific errors are better where possible.

---

# 111. ConnectivityService

Responsibilities:

```text
observe network connectivity
expose online/offline state
show offline banner
trigger reconnect behavior
```

Connectivity signal does not prove internet/API works.

Treat it as hint.

---

# 112. Offline Menu

If cached menu exists:

```text
show menu
```

but disable checkout.

Message:

```text
You're offline. Reconnect to place an order.
```

---

# 113. Offline Cart

Cart remains usable locally.

Customer can:

```text
browse cached menu
edit cart
```

But final order requires server.

---

# 114. App Resume

When app returns foreground:

```text
check auth
check network
refresh active order
optionally refresh menu
reconnect realtime
```

---

# 115. App Lifecycle Service

Useful for:

```text
resumed
paused
detached
```

Use to manage:

```text
realtime
payment recovery
active order refresh
```

---

# 116. GetX Services

Recommended global services:

```text
SessionService
RestaurantContextService
DeepLinkService
ConnectivityService
LocalCartService
AppLifecycleService
AnalyticsService
```

---

# 117. GetX Controllers

Customer MVP:

```text
StartupController
QrController
MenuController
ProductDetailController
CartController
CheckoutController
PaymentController
OrderTrackingController
OrderHistoryController
ProfileController
AuthController
```

---

# 118. Repositories

Recommended:

```text
AuthRepository
RestaurantRepository
MenuRepository
OrderRepository
PaymentRepository
ProfileRepository
AddressRepository
CouponRepository
```

---

# 119. Models

Recommended:

```text
QrContext
Restaurant
Branch
DiningTable
RestaurantMenu
Category
Product
ModifierGroup
Modifier
SelectedModifier
CartItem
CheckoutDraft
Order
OrderItem
OrderItemModifier
Payment
OrderStatusEvent
Profile
Address
Coupon
```

---

# 120. DTO vs Domain Model

For larger project:

```text
API DTO
 ↓
Domain model
 ↓
UI
```

Example:

```text
ProductDto
Product
```

For MVP, one typed model layer can be sufficient.

---

# 121. Controller Rule

Controller may:

```text
manage UI state
call repository
navigate
coordinate feature
```

Controller should not:

```text
contain raw SQL concepts
store secret keys
perform payment signature verification
decide authoritative price
```

---

# 122. Repository Rule

Repository may:

```text
call Supabase table
call RPC
call Edge Function
open Realtime stream
map response
```

Repository should not:

```text
render UI
show dialogs directly
```

---

# 123. View Rule

View:

```text
reads Rx state
calls controller methods
renders widgets
```

Avoid:

```dart
Supabase.instance.client
```

inside UI widgets.

---

# 124. Menu Binding

Example:

```dart
class MenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => MenuController(
        Get.find<MenuRepository>(),
        Get.find<RestaurantContextService>(),
      ),
    );
  }
}
```

---

# 125. Checkout Binding

Example:

```dart
class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CheckoutController(
        orderRepository:
            Get.find<OrderRepository>(),
        cartController:
            Get.find<CartController>(),
        contextService:
            Get.find<RestaurantContextService>(),
      ),
    );
  }
}
```

---

# 126. Route Arguments

Avoid passing huge objects through routes.

Prefer:

```text
/product/:id
```

Then controller looks up product from menu cache.

For order:

```text
/order/:id
```

load securely from repository.

---

# 127. Navigation Flow

Typical:

```text
Splash
 ↓
Menu
 ↓
Product
 ↓
Menu
 ↓
Cart
 ↓
Checkout
 ↓
Payment
 ↓
Order Tracking
```

Back navigation should not accidentally create duplicate orders.

---

# 128. Post-Checkout Navigation

After order creation:

```text
clear cart only when order is safely created
```

Then:

```text
Get.offAllNamed(orderRoute)
```

or keep restaurant menu beneath depending on UX.

---

# 129. Cart Clear Timing

Do not clear cart:

```text
before create_order response
```

Otherwise a network failure loses cart.

Recommended:

```text
create order successful
 ↓
save order ID
 ↓
clear cart
```

For online payment requiring retry, order already contains snapshot items.

---

# 130. Payment Retry After Cart Clear

Because order exists server-side:

```text
retry payment using order ID
```

Do not recreate cart/order.

---

# 131. Cancelled Payment and Order

If order is awaiting payment:

```text
payment cancelled
```

may leave order pending temporarily.

Backend can:

```text
allow retry
expire automatically
cancel through explicit action
```

Document this behavior.

---

# 132. Order Expiry Later

Possible field:

```text
payment_expires_at
```

Background job can cancel unpaid orders.

---

# 133. Loading UX

Prefer:

```text
skeleton menu cards
inline button spinner
```

over full-screen blocking spinner for everything.

---

# 134. Add-to-Cart UX

After add:

```text
button becomes quantity control
or
snackbar "Added"
cart bar updates
```

Do not navigate to cart after every add.

---

# 135. Floating Cart Bar

Example:

```text
3 items             ₹947
[View Cart]
```

Only show if cart not empty.

---

# 136. Cart Badge

App header can show:

```text
cart icon
item count
```

Use total quantity or line count consistently.

---

# 137. Customer Notes

Two levels:

```text
item note
order note
```

Examples:

```text
Item: No onion
Order: Please bring extra plates
```

Both need server limits.

---

# 138. Restaurant Request Safety

Do not imply restaurant can guarantee:

```text
allergen safety
medical dietary safety
```

unless merchant explicitly provides verified information.

---

# 139. Allergen Information

If product stores allergens:

```text
display as merchant-provided information
```

Example:

```text
Contains: milk, wheat
```

Use proper disclaimers if product needs it.

---

# 140. Analytics Events

Useful customer analytics:

```text
app_open
qr_scan
qr_resolved
menu_view
category_view
product_view
search
add_to_cart
remove_from_cart
checkout_started
order_created
payment_started
payment_succeeded
payment_failed
order_tracking_view
order_completed
```

---

# 141. Analytics Privacy

Do not log unnecessary PII.

Prefer:

```text
restaurant_id
branch_id
product_id
event
anonymous session ID
```

Avoid:

```text
full phone
address
payment payload
```

---

# 142. Crash Reporting

Production should include crash/error reporting.

Log context:

```text
screen
route
restaurant ID
branch ID
order ID
error code
```

Do not log secrets.

---

# 143. Feature Flags

Future backend-controlled flags:

```text
delivery enabled
loyalty enabled
coupons enabled
online payment enabled
guest ordering enabled
```

Customer app reads safe config.

---

# 144. App Config

Potential server response:

```json
{
  "maintenance": false,
  "min_supported_version": "1.2.0",
  "features": {
    "delivery": false,
    "loyalty": true
  }
}
```

---

# 145. Maintenance Mode

If backend in maintenance:

```text
Restaurant ordering is temporarily unavailable.
```

Optionally still show menu.

---

# 146. Minimum App Version

If native app too old:

```text
Update required
```

For web, deployment updates automatically.

---

# 147. Customer Home Without QR

Optional future:

```text
recent restaurants
nearby restaurants
search restaurants
orders
profile
```

But QR ordering MVP does not require marketplace discovery.

---

# 148. QR-First MVP

Initial home can simply be:

```text
Scan restaurant QR
```

plus:

```text
My Orders
```

if authenticated.

---

# 149. Restaurant Link Without Table

Restaurants may share:

```text
https://order.example.com/r/pizza-house
```

Flow:

```text
restaurant
 ↓
choose branch
 ↓
takeaway
```

Different from table QR.

---

# 150. Link Types

Support later:

```text
/q/<table-token>
/r/<restaurant-slug>
/b/<branch-slug>
/order/<id>
```

DeepLinkService routes each type.

---

# 151. Table QR vs Restaurant Link

Table QR:

```text
auto dine-in
auto branch
auto table
```

Restaurant link:

```text
may require branch/order type selection
```

---

# 152. Menu Version

If backend provides menu version:

```text
cache menu with version
```

On reopen:

```text
compare
 ↓
reuse or refresh
```

Optional optimization.

---

# 153. Performance Targets

Customer menu should feel immediate.

Focus:

```text
single menu request
image caching
local cart
minimal startup work
avoid excessive rebuilds
avoid N+1 queries
```

---

# 154. GetX Reactive Performance

Avoid wrapping entire screen with one huge `Obx`.

Prefer smaller reactive areas:

```text
cart badge
loading state
category selection
quantity control
```

---

# 155. List Performance

For large menus:

```text
ListView.builder
slivers
image cache
avoid expensive widgets
```

---

# 156. Product Image Optimization

Merchant/backend should provide optimized images.

Target:

```text
WebP/AVIF where supported
reasonable dimensions
compressed file
```

Customer app should not download 8 MB photos per item.

---

# 157. Search Debounce

If server search later:

```text
300–500ms debounce
```

Avoid request per keystroke.

---

# 158. Currency Precision

Keep:

```text
int minor units
```

in app model too.

Never convert to double for financial state.

Only format at UI boundary.

---

# 159. Local Preview Total

Example:

```dart
int calculateLinePreviewMinor(
  Product product,
  List<SelectedModifier> modifiers,
  int quantity,
) {
  final extras = modifiers.fold<int>(
    0,
    (sum, item) =>
        sum + item.priceDeltaMinor,
  );

  return (
    product.basePriceMinor + extras
  ) * quantity;
}
```

Still not authoritative.

---

# 160. Checkout Price Summary

Display server result:

```text
Subtotal        ₹850.00
Tax              ₹42.50
Service charge    ₹0.00
Discount         -₹50.00
Delivery          ₹0.00
------------------------
Total            ₹842.50
```

---

# 161. Tax Detail

If legally required:

```text
CGST
SGST
VAT
```

show backend-calculated breakdown.

Do not calculate legal tax only in Flutter.

---

# 162. Receipt

After completed order:

```text
Order #1042
Restaurant
Items
Taxes
Payment
Total
Date
```

Receipt data comes from order snapshots.

---

# 163. Share Receipt

Future:

```text
share text/PDF
email
WhatsApp
```

Do not expose private receipt URL publicly without access protection.

---

# 164. Cancellation Request

Customer cancellation may be allowed only in early status.

Flow:

```text
Cancel order
 ↓
server validates status/rules
 ↓
cancel
 ↓
refund if applicable
```

Do not update status directly.

---

# 165. Cancel Confirmation

```text
Cancel this order?

The restaurant may already be preparing it.

[Keep order]
[Request cancellation]
```

Backend decides allowed state.

---

# 166. Refund Status

If payment refund occurs:

```text
Refund initiated
Refund completed
Refund failed
```

Customer should see server payment/refund state.

---

# 167. Support

Future order support actions:

```text
Call restaurant
WhatsApp restaurant
Report issue
```

Only expose business-approved contact information.

---

# 168. Reorder

Future:

```text
Order again
```

Must:

```text
load current menu
validate current availability
map old items to current products
not trust old prices
```

---

# 169. Favorites

Future:

```text
favorite products
favorite restaurants
```

Not needed for MVP.

---

# 170. Push Notifications

Useful events:

```text
order accepted
order ready
payment confirmed
order cancelled
refund processed
```

---

# 171. Device Token Registration

After notification permission:

```text
get push token
 ↓
save to device_tokens
```

Associate with:

```text
auth.uid()
app_type = customer
```

---

# 172. Notification Permission UX

Do not ask on first frame without context.

Better:

```text
after order:
"Get notified when your order is ready"
```

Then request permission.

---

# 173. Notification Deep Link

Tap:

```text
Order #1042 is ready
```

opens:

```text
/order/<id>
```

Order RLS still validates ownership.

---

# 174. Push Token Refresh

Update backend if token changes.

Remove/disable token on logout if appropriate.

---

# 175. Background Realtime

Do not assume WebSocket stays alive in background.

Use push for background.

Realtime for foreground.

---

# 176. Active Order Banner

On menu screen:

```text
Order #1042 • Preparing
[Track]
```

Very useful after customer navigates away.

---

# 177. Customer Feedback Later

After completed:

```text
Rate your order
```

Possible:

```text
1–5 stars
comment
```

Store separate feedback table.

---

# 178. Review Moderation

If publishing public reviews later:

```text
moderation
spam protection
privacy
```

becomes required.

---

# 179. UX for Table Service

For dine-in:

```text
Table 12
```

should remain clearly visible so customer trusts they are ordering to correct table.

---

# 180. Manual Table Change

Avoid customer editing table via free text.

If supported:

```text
scan another table QR
```

rather than choose arbitrary table ID.

---

# 181. Shared Table

Multiple customers at same table may create separate orders.

This is fine.

Do not assume one order per table.

---

# 182. Table Session Later

Future:

```text
table_session
```

could group:

```text
multiple customer orders
shared bill
waiter actions
```

Not necessary for MVP.

---

# 183. Group Ordering Later

Possible:

```text
share cart/session link
multiple people add items
one payer
```

Complex. Delay.

---

# 184. Tips Later

If market supports tipping:

```text
tip amount
tip percentage
```

Server validates and payment amount includes tip.

Keep as separate field.

---

# 185. Scheduled Orders Later

For takeaway/delivery:

```text
ASAP
Scheduled
```

Backend validates opening hours/capacity.

---

# 186. Delivery Tracking Later

Future statuses:

```text
ready
assigned
picked_up
out_for_delivery
delivered
```

Requires delivery model.

---

# 187. Home Screen Components Later

```text
Current order
Recent restaurants
Order history
Scan QR
Offers
Profile
```

MVP can remain minimal.

---

# 188. App Theme

Customer app should support restaurant branding carefully.

Possible:

```text
restaurant logo
accent color
cover image
```

Do not dynamically theme every text/background to colors that break accessibility.

---

# 189. White Label Future

If selling white-label customer apps:

```text
brand configuration
app icons
splash
domains
store listings
```

Backend architecture can remain shared multi-tenant or dedicated based on business model.

---

# 190. Security: Never Store Secrets

Customer app must not contain:

```text
Supabase secret key
service role key
payment secret
webhook secret
FCM server secret
```

Public/publishable keys are okay with correct RLS.

---

# 191. Security: Never Trust Route IDs

User may manually open:

```text
/order/another-user-order
```

Backend RLS must reject.

---

# 192. Security: Never Trust Cart Price

User may modify local storage.

Backend ignores client total.

---

# 193. Security: Never Trust Table ID

User may tamper with context.

Backend validates table/branch.

---

# 194. Security: Never Trust Payment Callback

Backend webhook verifies.

---

# 195. Security: Do Not Expose Private Menu Fields

Customer menu API must not expose:

```text
cost price
profit margin
supplier
internal stock cost
staff notes
```

Use public RPC/DTO.

---

# 196. Security: Image URLs

Public menu images can be public.

Private customer documents should use private buckets/signed URLs.

---

# 197. Error Recovery

Every critical flow should be resumable.

Examples:

```text
payment app closed
network timeout
app killed after order
realtime disconnect
```

Use server IDs/local persistence.

---

# 198. Checkout Recovery

Persist:

```text
pending order ID
idempotency key
payment state
```

locally.

On app restart:

```text
query backend
```

before creating anything new.

---

# 199. Pending Payment Recovery

If local state says:

```text
order awaiting payment
```

show:

```text
Resume payment
```

after confirming server state.

---

# 200. Completed Payment Recovery

If payment succeeded externally and app died:

```text
app opens
 ↓
query order
 ↓
order placed
 ↓
tracking
```

No duplicate payment.

---

# 201. Customer App State Layers

Use three layers:

```text
Persistent backend state:
order/payment/profile

Persistent local state:
cart/context/pending IDs

Ephemeral UI state:
selected tab/loading/dialog
```

Do not confuse them.

---

# 202. Local Data Cleanup

Clear stale:

```text
old cart
old restaurant context
expired pending payment
obsolete cached menu
```

using timestamps/version rules.

---

# 203. Cart Expiration

Optional:

```text
cart older than 24 hours
```

show:

```text
Menu may have changed. Refreshing...
```

Then validate current products.

---

# 204. Testing Pyramid

Customer app tests:

```text
unit
widget
integration
end-to-end
```

---

# 205. Unit Tests

Test:

```text
money formatter
cart total preview
modifier validation
cart merge
route parsing
QR parsing
controller states
error mapping
```

---

# 206. Repository Tests

Mock Supabase calls.

Test:

```text
menu success
menu error
resolve QR
create order
payment function
order stream mapping
```

---

# 207. Controller Tests

Example:

```text
MenuController loading → success
MenuController loading → error
CheckoutController duplicate tap
PaymentController pending
OrderTrackingController realtime update
```

---

# 208. Widget Tests

Test:

```text
empty menu
loading skeleton
product sold out
modifier required
empty cart
checkout validation
order status timeline
```

---

# 209. Integration Tests

Critical:

```text
QR → Menu
Menu → Product
Product → Cart
Cart → Checkout
Checkout → Order
Order → Tracking
```

---

# 210. Payment Integration Tests

Test:

```text
success
failure
cancel
timeout
duplicate callback
webhook delayed
app killed during payment
```

---

# 211. Realtime Tests

Test:

```text
status update
disconnect/reconnect
wrong customer rejected
multiple active orders
logout cleanup
```

---

# 212. Deep Link Tests

Test:

```text
cold start QR link
warm app QR link
invalid token
unknown path
order notification deep link
app already in another restaurant
```

---

# 213. Offline Tests

Test:

```text
open cached menu offline
edit cart offline
checkout disabled
network restored
menu refresh
order tracking reconnect
```

---

# 214. Low Network Tests

Simulate:

```text
2G/slow 3G
high latency
packet loss
```

Ensure:

```text
no duplicate orders
no lost cart
clear progress states
```

---

# 215. Accessibility Tests

Test:

```text
large text
screen reader
button labels
contrast
tap targets
status timeline semantics
```

---

# 216. Device Tests

At minimum:

```text
small Android
large Android
older Android supported version
iPhone small screen
iPhone large screen
tablet if supported
Flutter Web mobile browser
```

---

# 217. Analytics QA

Ensure:

```text
one event per action
no duplicate events from rebuild
no PII leakage
correct restaurant/branch IDs
```

---

# 218. Customer MVP Screen List

Required:

```text
SplashPage
QrScannerPage
MenuPage
ProductDetailPage
CartPage
CheckoutPage
PaymentPage/flow
OrderTrackingPage
OrderHistoryPage
ProfilePage
PhoneOtpPage
```

---

# 219. Optional MVP Screens

Useful:

```text
RestaurantInfoPage
SearchPage
PaymentStatusPage
OrderDetailPage
OfflinePage
```

---

# 220. Phase 2 Customer Screens

```text
AddressListPage
AddressFormPage
CouponPage
LoyaltyPage
NotificationSettingsPage
FeedbackPage
```

---

# 221. Phase 3 Customer Screens

```text
DeliveryTrackingPage
ReservationsPage
FavoritesPage
OffersPage
RestaurantDiscoveryPage
```

---

# 222. Implementation Order

Build customer app in this order:

```text
1. Flutter project setup
2. Supabase initialization
3. GetX routing
4. SessionService
5. RestaurantContextService
6. DeepLinkService
7. QR scanner
8. resolve_qr
9. Menu models
10. get_public_menu
11. Menu screen
12. Product detail
13. Modifier selection
14. Cart
15. Local cart persistence
16. Checkout UI
17. create_order RPC integration
18. Cash order
19. Order tracking
20. Realtime
21. Order history
22. Online payment
23. Payment recovery
24. Phone OTP
25. Push notifications
26. Analytics
27. Crash reporting
28. QA/hardening
```

---

# 223. First Milestone

First working customer milestone:

```text
Open app
 ↓
Scan table QR
 ↓
See restaurant menu
 ↓
Open product
 ↓
Choose modifier
 ↓
Add to cart
 ↓
Checkout
 ↓
Place cash order
 ↓
See realtime status
```

Do this before:

```text
loyalty
delivery
AI
recommendations
reservations
```

---

# 224. Second Milestone

Add:

```text
online payment
payment recovery
order history
phone verification
push notification
```

---

# 225. Third Milestone

Add:

```text
takeaway
coupons
addresses
delivery
loyalty
```

---

# 226. Sample Customer Feature Architecture

```text
features/menu/
│
├── bindings/
│   └── menu_binding.dart
│
├── controllers/
│   └── menu_controller.dart
│
├── views/
│   └── menu_page.dart
│
└── widgets/
    ├── category_tabs.dart
    ├── product_card.dart
    ├── search_bar.dart
    └── cart_bar.dart
```

---

# 227. Product Feature Architecture

```text
features/product/
│
├── bindings/
│   └── product_binding.dart
│
├── controllers/
│   └── product_detail_controller.dart
│
├── views/
│   └── product_detail_page.dart
│
└── widgets/
    ├── modifier_group_widget.dart
    ├── quantity_selector.dart
    └── item_note_field.dart
```

---

# 228. Checkout Feature Architecture

```text
features/checkout/
│
├── bindings/
│   └── checkout_binding.dart
│
├── controllers/
│   └── checkout_controller.dart
│
├── views/
│   └── checkout_page.dart
│
└── widgets/
    ├── order_type_selector.dart
    ├── price_summary.dart
    ├── payment_method_selector.dart
    └── customer_details_form.dart
```

---

# 229. Tracking Feature Architecture

```text
features/order_tracking/
│
├── bindings/
│   └── order_tracking_binding.dart
│
├── controllers/
│   └── order_tracking_controller.dart
│
├── views/
│   └── order_tracking_page.dart
│
└── widgets/
    ├── order_status_timeline.dart
    ├── active_order_card.dart
    └── order_items_summary.dart
```

---

# 230. Repositories Folder

```text
data/repositories/
│
├── auth_repository.dart
├── restaurant_repository.dart
├── menu_repository.dart
├── order_repository.dart
├── payment_repository.dart
├── profile_repository.dart
└── address_repository.dart
```

---

# 231. Services Folder

```text
core/services/
│
├── session_service.dart
├── restaurant_context_service.dart
├── deep_link_service.dart
├── connectivity_service.dart
├── local_cart_service.dart
├── app_lifecycle_service.dart
├── notification_service.dart
└── analytics_service.dart
```

---

# 232. Local Storage Keys

Centralize:

```text
customer_cart_v1
restaurant_context_v1
pending_order_id
pending_payment_order_id
last_menu_cache
```

Version keys to handle schema changes.

---

# 233. Cache Migration

If cart model changes:

```text
customer_cart_v1
→
customer_cart_v2
```

either migrate or clear old safely.

Do not crash on stale local JSON.

---

# 234. Model Parsing

Be defensive with nullable fields.

Avoid:

```dart
json['description'] as String
```

if backend allows null.

Use typed factories carefully.

---

# 235. Server Date Parsing

Store UTC/timestamptz.

Flutter:

```text
parse ISO timestamp
convert to local timezone
format
```

---

# 236. Order Date Formatting

Examples:

```text
Today, 6:32 PM
Yesterday, 8:10 PM
12 Sep 2026, 5:20 PM
```

Use centralized formatting.

---

# 237. Loading Order Detail

Repository:

```text
fetch order
fetch order items
fetch modifier snapshots
fetch payment summary
fetch status history
```

Could be one RPC for fewer calls.

---

# 238. get_order_details RPC

Recommended response:

```json
{
  "order": {},
  "items": [],
  "payment": {},
  "status_history": []
}
```

RLS/server validates ownership.

---

# 239. Customer Home State

Potential:

```text
active order?
restaurant context?
cart?
```

Use those to show useful shortcuts.

---

# 240. No Restaurant Context

Show:

```text
Scan a restaurant QR to start ordering.

[Scan QR]
```

---

# 241. Active Restaurant Context

Show:

```text
Continue ordering from Pizza House

[Open Menu]
```

with:

```text
Scan another QR
```

---

# 242. Table Context Expiry

Optional:

```text
clear table context after completed order + inactivity
```

Avoid accidental next-day ordering to old table.

---

# 243. QR Context Expiration Strategy

Possible:

```text
table context expires after 4–12 hours
```

or after:

```text
completed order + app close
```

Business decision.

Backend still validates table.

---

# 244. Session + Context

Auth anonymous user can outlive table context.

Keep separate:

```text
auth session
restaurant session
```

---

# 245. Customer Contact Snapshot

Checkout may send:

```text
name
phone
```

Backend snapshots into order.

Profile changes later do not change historical order.

---

# 246. Payment Method UI

Options returned from backend/config:

```text
Cash
UPI
Card
Online
```

Do not show methods unsupported by restaurant.

---

# 247. Payment Provider Abstraction

Flutter payment layer should hide provider-specific details.

Interface concept:

```dart
abstract class PaymentGateway {
  Future<PaymentResult> start(
    PaymentSession session,
  );
}
```

Then:

```text
RazorpayGateway
StripeGateway
CashfreeGateway
```

---

# 248. Payment Result Model

```text
success callback
failure callback
cancelled
unknown/pending
```

But final verification still server-side.

---

# 249. Payment Timeout

If provider UI hangs:

```text
allow customer to return
```

Order remains recoverable.

---

# 250. Duplicate Payment Prevention

Before creating a new payment:

```text
query order/payment state
```

Backend also prevents duplicate successful charge.

---

# 251. Customer Order Number

Display human-friendly:

```text
#1042
```

Never use order number alone to fetch sensitive order.

Use UUID internally.

---

# 252. Status Colors

May use colors, but always add:

```text
icon
text
```

for accessibility.

---

# 253. Estimated Time

If restaurant provides estimated preparation time:

```text
10–15 minutes
```

show as estimate.

Do not promise exact time unless backend/business guarantees it.

---

# 254. Waiter Call Later

Possible dine-in feature:

```text
Call waiter
Request water
Request bill
```

Would need server events/table requests.

Not part of MVP.

---

# 255. Bill Request Later

If restaurant uses postpaid dine-in:

```text
Request bill
```

creates staff notification.

Separate from order payment architecture.

---

# 256. Multi-Order Table Bill Later

Shared bill across multiple orders requires:

```text
table sessions
billing sessions
payment allocation
```

Complex; defer.

---

# 257. Customer App Security Checklist

```text
[ ] no service role key
[ ] no payment secret
[ ] no webhook secret
[ ] no trusted local role
[ ] no trusted local price
[ ] no trusted local table
[ ] no direct payment status update
[ ] no direct order financial update
[ ] RLS protects orders
[ ] deep-link order IDs protected
[ ] local cart cannot influence final server price
```

---

# 258. Menu UX Checklist

```text
[ ] restaurant identity clear
[ ] table clear
[ ] search available
[ ] categories easy to navigate
[ ] sold-out clear
[ ] modifiers clear
[ ] price deltas clear
[ ] add button easy to find
[ ] cart visible
```

---

# 259. Cart UX Checklist

```text
[ ] quantity editable
[ ] modifiers visible
[ ] notes visible
[ ] line totals visible
[ ] remove easy
[ ] subtotal preview
[ ] restaurant context visible
[ ] checkout CTA visible
```

---

# 260. Checkout UX Checklist

```text
[ ] order type clear
[ ] table/pickup context clear
[ ] customer info validation
[ ] payment method clear
[ ] server total shown
[ ] no double submit
[ ] price change handled
[ ] unavailable item handled
```

---

# 261. Payment UX Checklist

```text
[ ] loading state
[ ] cancel state
[ ] failure state
[ ] pending verification
[ ] retry
[ ] restore after app restart
[ ] no duplicate payment
```

---

# 262. Tracking UX Checklist

```text
[ ] order number
[ ] restaurant
[ ] status timeline
[ ] item summary
[ ] total
[ ] payment state
[ ] manual refresh
[ ] reconnect behavior
[ ] push deep link
```

---

# 263. Production Checklist

```text
[ ] cold-start deep link works
[ ] warm deep link works
[ ] anonymous auth works
[ ] QR resolver handles invalid code
[ ] cart survives restart
[ ] restaurant switch clears cart safely
[ ] checkout is idempotent
[ ] price change is handled
[ ] sold-out item handled
[ ] online payment verified server-side
[ ] payment recovery works
[ ] Realtime reconnect works
[ ] wrong customer order is blocked by RLS
[ ] order history paginated
[ ] push opens correct order
[ ] offline state is clear
[ ] analytics contain no sensitive PII
[ ] crash logs contain no secrets
```

---

# 264. Full Customer Flow Diagram

```text
                         APP OPEN
                            │
                            ▼
                         SPLASH
                            │
                ┌───────────┴───────────┐
                │                       │
             Deep link?              No link
                │                       │
               YES                      ▼
                │                Saved context?
                ▼                       │
          Resolve QR                    ├── YES → MENU
                │                       │
        ┌───────┴────────┐              └── NO → QR SCANNER
        │                │
     Valid             Invalid
        │                │
        ▼                ▼
   Save context       Error UI
        │
        ▼
       MENU
        │
        ├──────────── Search
        │
        ├──────────── Category
        │
        ▼
   PRODUCT DETAIL
        │
        ▼
    MODIFIERS
        │
        ▼
       CART
        │
        ▼
     CHECKOUT
        │
        ▼
 create_order RPC
        │
        ├───────────── Error
        │                │
        │                ▼
        │          Fix cart / retry
        │
        ▼
 Payment required?
        │
   ┌────┴────┐
   │         │
  NO        YES
   │         │
   │         ▼
   │      PAYMENT
   │         │
   │      webhook
   │         │
   └────┬────┘
        ▼
      PLACED
        │
        ▼
 REALTIME TRACKING
        │
        ▼
     ACCEPTED
        │
        ▼
    PREPARING
        │
        ▼
       READY
        │
        ▼
      SERVED
        │
        ▼
    COMPLETED
        │
        ▼
  ORDER HISTORY
```

---

# 265. Customer App Data Ownership

```text
Backend truth:
- user identity
- restaurant validity
- branch validity
- table validity
- product price
- availability
- modifiers
- tax
- discount
- order total
- payment
- order status

Flutter state:
- selected category
- selected modifiers
- local cart
- text input
- current screen
- loading state
- cached menu
```

---

# 266. Final Architecture

```text
CUSTOMER
   │
   ▼
FLUTTER UI
   │
   ▼
GETX CONTROLLER
   │
   ▼
REPOSITORY
   │
   ├───────────── SUPABASE AUTH
   │
   ├───────────── SUPABASE RPC
   │
   ├───────────── DATA API
   │
   ├───────────── REALTIME
   │
   └───────────── EDGE FUNCTIONS
                         │
                         ▼
                  POSTGRESQL + RLS
                         │
                         ▼
                    SOURCE OF TRUTH
```

---

# 267. Final Rules

1. **Scan → menu must be fast.**
2. **Do not force signup before browsing.**
3. **Use anonymous auth for guest ownership and RLS.**
4. **Store restaurant/table context separately from auth.**
5. **Use one menu payload instead of N+1 queries.**
6. **Keep cart local until checkout.**
7. **Use integer minor units for money.**
8. **Client totals are previews only.**
9. **create_order must recalculate everything server-side.**
10. **Use idempotency for checkout.**
11. **Do not trust payment SDK callbacks.**
12. **Use webhook/server payment verification.**
13. **Persist pending order/payment state for recovery.**
14. **Use Realtime for live order status.**
15. **Refetch after reconnect.**
16. **PostgreSQL is durable truth.**
17. **Use RLS to protect every private customer order.**
18. **Never place secrets in Flutter.**
19. **Make all critical flows recoverable after app restart.**
20. **Build QR → menu → cart → order → tracking before advanced features.**

---

# 268. Definition of Customer MVP Complete

The customer app MVP is complete when:

```text
[ ] App initializes Supabase
[ ] Anonymous session works
[ ] QR scanner works
[ ] Deep links work
[ ] resolve_qr works
[ ] Restaurant/table context is saved
[ ] Menu loads
[ ] Search works
[ ] Categories work
[ ] Product detail works
[ ] Modifier validation works
[ ] Cart works
[ ] Cart persists locally
[ ] Restaurant switching is safe
[ ] Checkout works
[ ] create_order integration works
[ ] Server total is displayed
[ ] Cash order works
[ ] Online payment works if enabled
[ ] Payment recovery works
[ ] Order tracking works
[ ] Realtime reconnect works
[ ] Order history works
[ ] Customer cannot access another user's order
[ ] Error states are handled
[ ] Offline UX is handled
[ ] App is tested on real devices
```

---

# 269. Suggested Companion Files

Create next:

```text
CUSTOMER_APP_FOLDER_STRUCTURE.md
CUSTOMER_APP_MODELS.md
CUSTOMER_APP_GETX_CONTROLLERS.md
CUSTOMER_APP_REPOSITORIES.md
CUSTOMER_APP_SUPABASE_INTEGRATION.md
CUSTOMER_APP_PAYMENT_FLOW.md
CUSTOMER_APP_REALTIME_FLOW.md
CUSTOMER_APP_UI_SCREEN_SPEC.md
CUSTOMER_APP_TEST_PLAN.md
CUSTOMER_APP_TASK_LIST.md
```

---

# 270. Final Recommendation

Implement the customer app in this exact priority:

```text
SESSION
 ↓
QR / DEEP LINK
 ↓
RESTAURANT CONTEXT
 ↓
MENU
 ↓
PRODUCT + MODIFIERS
 ↓
CART
 ↓
CHECKOUT
 ↓
SECURE ORDER CREATION
 ↓
TRACKING
 ↓
ONLINE PAYMENT
 ↓
ORDER HISTORY
 ↓
PHONE ACCOUNT
 ↓
PUSH
 ↓
DELIVERY / LOYALTY / COUPONS
```

The customer experience should feel simple even though the backend is strict.

The ideal customer perception is:

```text
Scan
Choose
Order
Track
```

while the system internally performs:

```text
authentication
tenant validation
table validation
menu validation
price validation
modifier validation
transactional order creation
payment verification
RLS authorization
Realtime synchronization
```

That separation is what makes the product both **easy to use** and **safe to operate**.
