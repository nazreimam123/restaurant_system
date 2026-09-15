# QR Restaurant Ordering Platform
## Flutter + GetX + MVC + Supabase — Project Blueprint

> A production-oriented architecture for building a restaurant QR ordering platform similar in concept to FoodKlick, ClickyMenu, and Smart QR Order.

---

# 1. Project Goal

Build a complete restaurant ordering platform with:

- Customer mobile app
- Restaurant/admin mobile app
- QR-based dine-in ordering
- Takeaway ordering
- Optional delivery ordering
- Menu management
- Product variants and modifiers
- Cart and checkout
- Cash and online payments
- Kitchen Display System (KDS)
- Realtime order updates
- Customer order tracking
- Staff roles and permissions
- Multi-branch support
- Basic analytics
- Future inventory, CRM, loyalty, reservations, and AI features

Main stack:

- **Flutter**
- **GetX**
- **MVC-inspired architecture**
- **Repository layer**
- **Supabase**
  - Auth
  - PostgreSQL
  - Realtime
  - Storage
  - RPC / PostgreSQL Functions
  - Edge Functions

---

# 2. High-Level Architecture

```text
                        INTERNET
                           │
                           │
               ┌───────────▼───────────┐
               │       SUPABASE        │
               │                       │
               │ Auth                  │
               │ PostgreSQL            │
               │ Realtime              │
               │ Storage               │
               │ Edge Functions        │
               └───────────┬───────────┘
                           │
              ┌────────────┴─────────────┐
              │                          │
              │                          │
      CUSTOMER FLUTTER APP       ADMIN FLUTTER APP
              │                          │
        GetX + MVC                 GetX + MVC
              │                          │
        Menu / Cart            Orders / KDS / Menu
       Checkout / QR          Dashboard / Inventory
```

Recommended application architecture:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Supabase
```

For sensitive business logic:

```text
Flutter
 ↓
Repository
 ↓
Supabase RPC / Edge Function
 ↓
PostgreSQL
```

Do **not** put important security or financial logic only inside Flutter.

---

# 3. Recommended Repository Structure

```text
restaurant_system/
│
├── apps/
│   │
│   ├── customer_app/
│   │   ├── lib/
│   │   └── pubspec.yaml
│   │
│   └── merchant_app/
│       ├── lib/
│       └── pubspec.yaml
│
├── packages/
│   │
│   ├── app_core/
│   │   ├── errors/
│   │   ├── constants/
│   │   ├── helpers/
│   │   └── services/
│   │
│   ├── app_models/
│   │   ├── restaurant.dart
│   │   ├── branch.dart
│   │   ├── product.dart
│   │   ├── order.dart
│   │   └── ...
│   │
│   └── app_widgets/
│
└── supabase/
    ├── migrations/
    ├── seed.sql
    └── functions/
```

Two Flutter apps should share models and utilities but keep business-specific UI separate.

---

# 4. Customer App Features

Core modules:

```text
Startup
Authentication
QR Scanner
Restaurant Context
Menu
Category
Product Detail
Modifiers
Cart
Checkout
Payment
Order Tracking
Order History
Profile
Loyalty (later)
Coupons (later)
Delivery (later)
```

Primary customer flow:

```text
Scan table QR
     ↓
Resolve restaurant
     ↓
Resolve branch
     ↓
Resolve table
     ↓
Load menu
     ↓
Browse categories
     ↓
Select product
     ↓
Select modifiers
     ↓
Add to cart
     ↓
Checkout
     ↓
Backend validates prices
     ↓
Create order
     ↓
Payment
     ↓
Kitchen receives order
     ↓
Customer sees live status
```

---

# 5. Admin / Merchant App Features

Primary users:

- Owner
- Manager
- Cashier
- Waiter
- Kitchen staff

Modules:

```text
Authentication
Restaurant Selection
Branch Selection
Dashboard
Live Orders
Order Detail
Kitchen Display System
Categories
Products
Modifiers
Tables
QR Generation
Staff Management
Reports
Settings
Payments
Inventory (later)
CRM (later)
Loyalty (later)
Reservations (later)
```

Live order flow:

```text
Customer places order
        ↓
Supabase
        ↓
Realtime
        ↓
Admin/KDS app
        ↓
PLACED
        ↓
ACCEPTED
        ↓
PREPARING
        ↓
READY
        ↓
SERVED
        ↓
COMPLETED
```

---

# 6. Flutter Folder Structure

## Customer App

```text
lib/
│
├── main.dart
│
├── app/
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   ├── bindings/
│   │   └── initial_binding.dart
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── services/
│   ├── utils/
│   └── widgets/
│
├── data/
│   ├── models/
│   └── repositories/
│
└── features/
    ├── splash/
    ├── auth/
    ├── qr/
    ├── restaurant/
    ├── menu/
    ├── product/
    ├── cart/
    ├── checkout/
    ├── payment/
    ├── order_tracking/
    ├── order_history/
    └── profile/
```

## Merchant App

```text
lib/
│
├── main.dart
│
├── app/
├── core/
├── data/
└── features/
    ├── auth/
    ├── restaurant/
    ├── branch/
    ├── dashboard/
    ├── orders/
    ├── kds/
    ├── categories/
    ├── products/
    ├── modifiers/
    ├── tables/
    ├── staff/
    ├── analytics/
    ├── payments/
    └── settings/
```

---

# 7. GetX + MVC Responsibilities

## Model

Represents application data.

Examples:

```text
Restaurant
Branch
DiningTable
Category
Product
Modifier
Order
OrderItem
Payment
Customer
```

Model responsibilities:

- Parse JSON
- Convert to/from database format
- Hold typed data

Models should **not** fetch Supabase data.

---

## View

Responsible only for presentation.

Examples:

```text
MenuPage
CartPage
CheckoutPage
OrderTrackingPage
AdminDashboardPage
KitchenPage
```

A View should:

- Render state
- Show loading/error/empty states
- Call controller methods
- Avoid database code

---

## Controller

Responsible for feature state and UI orchestration.

Examples:

```text
MenuController
CartController
CheckoutController
OrderTrackingController
LiveOrdersController
KitchenController
```

Controller should:

- Load data using repositories
- Manage observable UI state
- Handle user interaction
- Navigate
- Coordinate feature logic

Controller should **not** contain raw Supabase table queries everywhere.

---

## Repository

Responsible for data access.

Examples:

```text
MenuRepository
OrderRepository
AuthRepository
PaymentRepository
StaffRepository
ReportsRepository
```

Repositories talk to:

```text
Supabase tables
RPC functions
Edge Functions
Storage
Realtime
```

Recommended rule:

```text
UI → Controller → Repository → Supabase
```

---

# 8. Core Flutter Dependencies

Typical dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  get:
  supabase_flutter:

  cached_network_image:
  mobile_scanner:
  intl:
  get_storage:
```

Possible production additions:

```text
connectivity_plus
flutter_secure_storage
app_links
firebase_messaging
image_picker
image_compression package
payment provider SDK
crash reporting
analytics
```

Use current compatible package versions when implementing.

---

# 9. Supabase Initialization

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey:
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  runApp(const MyApp());
}
```

Use:

```dart
final supabase = Supabase.instance.client;
```

Never place the following inside the Flutter app:

```text
SERVICE_ROLE_KEY
PAYMENT_GATEWAY_SECRET
WEBHOOK_SECRET
PRIVATE ADMIN API KEYS
```

Those belong only on trusted backend infrastructure such as Supabase Edge Functions.

---

# 10. Root GetX App

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Restaurant Order',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
```

---

# 11. Initial Binding

```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      SupabaseService(),
      permanent: true,
    );

    Get.put(
      AuthService(),
      permanent: true,
    );

    Get.put(
      CartController(),
      permanent: true,
    );

    Get.lazyPut(
      () => MenuRepository(),
      fenix: true,
    );

    Get.lazyPut(
      () => OrderRepository(),
      fenix: true,
    );
  }
}
```

Use long-lived services for:

```text
AuthService
SessionService
BranchContextService
MerchantContextService
ConnectivityService
DeepLinkService
```

Use controllers for feature-specific state.

---

# 12. Routes

```dart
abstract class AppRoutes {
  static const splash = '/splash';
  static const menu = '/menu';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const order = '/order';
}
```

Example:

```dart
class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),

    GetPage(
      name: AppRoutes.menu,
      page: () => const MenuPage(),
      binding: MenuBinding(),
    ),

    GetPage(
      name: AppRoutes.cart,
      page: () => const CartPage(),
    ),

    GetPage(
      name: AppRoutes.checkout,
      page: () => const CheckoutPage(),
      binding: CheckoutBinding(),
    ),
  ];
}
```

---

# 13. Database Entity Relationships

Core hierarchy:

```text
Restaurant
    │
    ├── Branch
    │     │
    │     ├── Dining Tables
    │     ├── Categories
    │     │    └── Products
    │     │          └── Modifier Groups
    │     │                └── Modifiers
    │     │
    │     └── Orders
    │
    └── Staff / Members
```

Order hierarchy:

```text
Order
 │
 ├── Customer
 ├── Restaurant
 ├── Branch
 ├── Table
 ├── Order Items
 │      └── Order Item Modifiers
 ├── Payment
 └── Order Status History
```

---

# 14. Profiles Table

```sql
create table profiles (
    id uuid primary key
        references auth.users(id)
        on delete cascade,

    full_name text,
    phone text,
    avatar_url text,

    created_at timestamptz
        not null default now()
);
```

---

# 15. Restaurants Table

```sql
create table restaurants (
    id uuid primary key
        default gen_random_uuid(),

    name text not null,

    slug text unique not null,

    logo_url text,

    currency text
        not null default 'INR',

    is_active boolean
        not null default true,

    created_at timestamptz
        not null default now()
);
```

---

# 16. Branches Table

```sql
create table branches (
    id uuid primary key
        default gen_random_uuid(),

    restaurant_id uuid not null
        references restaurants(id)
        on delete cascade,

    name text not null,
    address text,
    phone text,

    is_active boolean
        not null default true,

    created_at timestamptz
        not null default now()
);
```

---

# 17. Restaurant Staff Roles

```sql
create type staff_role as enum (
    'owner',
    'manager',
    'cashier',
    'waiter',
    'kitchen'
);
```

Membership table:

```sql
create table restaurant_members (
    restaurant_id uuid
        references restaurants(id)
        on delete cascade,

    user_id uuid
        references auth.users(id)
        on delete cascade,

    role staff_role not null,

    is_active boolean
        not null default true,

    primary key (
        restaurant_id,
        user_id
    )
);
```

This supports one person being associated with more than one restaurant.

Example:

```text
USER
 │
 ├── Restaurant A → owner
 └── Restaurant B → manager
```

---

# 18. Dining Tables and QR Tokens

```sql
create table dining_tables (
    id uuid primary key
        default gen_random_uuid(),

    branch_id uuid not null
        references branches(id)
        on delete cascade,

    name text not null,

    qr_token uuid not null
        default gen_random_uuid()
        unique,

    is_active boolean
        not null default true
);
```

Recommended QR URL:

```text
https://order.example.com/q/<qr_token>
```

Example:

```text
https://order.example.com/q/c61f13be-5925-....
```

Do not blindly trust query parameters such as:

```text
?restaurant=12&table=4
```

The QR token should be resolved securely by the backend.

---

# 19. Categories Table

```sql
create table categories (
    id uuid primary key
        default gen_random_uuid(),

    branch_id uuid not null
        references branches(id)
        on delete cascade,

    name text not null,
    image_url text,

    sort_order integer
        not null default 0,

    is_active boolean
        not null default true,

    created_at timestamptz
        not null default now()
);
```

---

# 20. Products Table

Store money in the smallest currency unit.

Example:

```text
₹99.50 → 9950 paise
```

Recommended schema:

```sql
create table products (
    id uuid primary key
        default gen_random_uuid(),

    branch_id uuid not null
        references branches(id),

    category_id uuid not null
        references categories(id),

    name text not null,
    description text,

    base_price_minor bigint not null,

    image_url text,

    is_veg boolean,

    is_available boolean
        not null default true,

    sort_order integer
        not null default 0,

    created_at timestamptz
        not null default now()
);
```

Avoid floating point money calculations where possible.

---

# 21. Product Modifiers

Example:

```text
Pizza

Size:
○ Small
○ Medium
○ Large

Crust:
○ Thin
○ Cheese Burst

Extras:
□ Cheese
□ Mushroom
□ Olives
```

Modifier groups:

```sql
create table modifier_groups (
    id uuid primary key
        default gen_random_uuid(),

    restaurant_id uuid not null
        references restaurants(id),

    name text not null,

    min_select integer
        default 0,

    max_select integer
        default 1,

    required boolean
        not null default false
);
```

Modifiers:

```sql
create table modifiers (
    id uuid primary key
        default gen_random_uuid(),

    group_id uuid not null
        references modifier_groups(id)
        on delete cascade,

    name text not null,

    price_delta_minor bigint
        not null default 0,

    is_available boolean
        not null default true
);
```

Product mapping:

```sql
create table product_modifier_groups (
    product_id uuid
        references products(id),

    modifier_group_id uuid
        references modifier_groups(id),

    primary key (
        product_id,
        modifier_group_id
    )
);
```

---

# 22. Order Types

```sql
create type order_type as enum (
    'dine_in',
    'takeaway',
    'delivery'
);
```

---

# 23. Order Statuses

```sql
create type order_status as enum (
    'awaiting_payment',
    'placed',
    'accepted',
    'preparing',
    'ready',
    'served',
    'completed',
    'cancelled'
);
```

Recommended status flow:

```text
AWAITING_PAYMENT
      ↓
PLACED
      ↓
ACCEPTED
      ↓
PREPARING
      ↓
READY
      ↓
SERVED
      ↓
COMPLETED
```

Allow cancellation only according to business rules.

---

# 24. Orders Table

```sql
create table orders (
    id uuid primary key
        default gen_random_uuid(),

    restaurant_id uuid not null
        references restaurants(id),

    branch_id uuid not null
        references branches(id),

    table_id uuid
        references dining_tables(id),

    customer_id uuid
        references auth.users(id),

    order_type order_type not null,

    status order_status
        not null default 'placed',

    subtotal_minor bigint not null,

    tax_minor bigint
        not null default 0,

    discount_minor bigint
        not null default 0,

    total_minor bigint not null,

    customer_note text,

    idempotency_key text,

    created_at timestamptz
        not null default now()
);
```

---

# 25. Order Item Snapshots

Never rely only on current product data for historical orders.

Store snapshots:

```sql
create table order_items (
    id uuid primary key
        default gen_random_uuid(),

    order_id uuid not null
        references orders(id)
        on delete cascade,

    product_id uuid
        references products(id),

    product_name text not null,

    unit_price_minor bigint not null,

    quantity integer not null,

    line_total_minor bigint not null
);
```

This protects order history if the product name or price later changes.

---

# 26. Order Item Modifier Snapshots

Recommended additional table:

```sql
create table order_item_modifiers (
    id uuid primary key
        default gen_random_uuid(),

    order_item_id uuid not null
        references order_items(id)
        on delete cascade,

    modifier_id uuid
        references modifiers(id),

    modifier_name text not null,

    price_delta_minor bigint
        not null default 0
);
```

---

# 27. Payment Statuses

```sql
create type payment_status as enum (
    'pending',
    'paid',
    'failed',
    'refunded'
);
```

---

# 28. Payments Table

```sql
create table payments (
    id uuid primary key
        default gen_random_uuid(),

    order_id uuid not null
        references orders(id),

    provider text,

    provider_order_id text,

    provider_payment_id text,

    amount_minor bigint not null,

    status payment_status
        not null default 'pending',

    created_at timestamptz
        not null default now()
);
```

Flutter must not directly mark payment rows as paid.

---

# 29. Order Status History

```sql
create table order_status_history (
    id uuid primary key
        default gen_random_uuid(),

    order_id uuid not null
        references orders(id),

    old_status order_status,

    new_status order_status not null,

    changed_by uuid
        references auth.users(id),

    created_at timestamptz
        not null default now()
);
```

Example history:

```text
12:31 order placed
12:32 accepted by staff
12:35 preparing
12:43 ready
12:45 served
```

Useful for:

- Analytics
- Disputes
- Staff tracking
- Kitchen performance
- Audit trails

---

# 30. Product Model Example

```dart
class Product {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final int priceMinor;
  final String? imageUrl;
  final bool isAvailable;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.priceMinor,
    required this.isAvailable,
    this.description,
    this.imageUrl,
  });

  factory Product.fromJson(
    Map<String, dynamic> json,
  ) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      priceMinor: json['base_price_minor'],
      imageUrl: json['image_url'],
      isAvailable: json['is_available'],
    );
  }
}
```

---

# 31. Menu Repository Example

```dart
class MenuRepository {
  SupabaseClient get _client =>
      Supabase.instance.client;

  Future<List<Product>> getProducts(
    String branchId,
  ) async {
    final response = await _client
        .from('products')
        .select()
        .eq('branch_id', branchId)
        .eq('is_available', true)
        .order('sort_order');

    return (response as List)
        .map(
          (e) => Product.fromJson(e),
        )
        .toList();
  }
}
```

---

# 32. Menu Controller Example

```dart
class MenuController extends GetxController {
  final MenuRepository repository;

  MenuController(this.repository);

  final products = <Product>[].obs;
  final selectedCategoryId = RxnString();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadMenu();
  }

  Future<void> loadMenu() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final branchId =
          Get.find<BranchContextService>()
              .branchId;

      products.value =
          await repository.getProducts(
        branchId!,
      );
    } catch (e) {
      errorMessage.value =
          'Unable to load menu';
    } finally {
      isLoading.value = false;
    }
  }
}
```

---

# 33. Menu Binding Example

```dart
class MenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => MenuController(
        Get.find<MenuRepository>(),
      ),
    );
  }
}
```

---

# 34. Menu View Example

```dart
class MenuPage
    extends GetView<MenuController> {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (controller
                .errorMessage.value !=
            null) {
          return Center(
            child: Text(
              controller
                  .errorMessage.value!,
            ),
          );
        }

        return ListView.builder(
          itemCount:
              controller.products.length,
          itemBuilder: (_, index) {
            final product =
                controller.products[index];

            return ListTile(
              title: Text(product.name),
              subtitle: Text(
                '₹${product.priceMinor / 100}',
              ),
            );
          },
        );
      }),
    );
  }
}
```

---

# 35. Customer Authentication Strategy

Do not force account creation before viewing a menu.

Recommended:

```text
Guest
  ↓
Browse
  ↓
Order
  ↓
Optional phone verification
  ↓
Order history
  ↓
Loyalty
```

For anonymous auth:

```dart
await Supabase.instance.client.auth
    .signInAnonymously();
```

For phone OTP:

```dart
await supabase.auth.signInWithOtp(
  phone: '+919999999999',
);
```

OTP verification:

```dart
await supabase.auth.verifyOTP(
  phone: phone,
  token: otp,
  type: OtpType.sms,
);
```

---

# 36. Admin Authentication Strategy

Recommended options:

```text
Email + password
Phone + OTP
MFA later
```

After authentication:

```text
auth.users
    ↓
restaurant_members
    ↓
available restaurants
    ↓
available role
    ↓
available branches
```

---

# 37. Merchant Context Service

```dart
class MerchantContextService
    extends GetxService {

  final restaurantId =
      RxnString();

  final branchId =
      RxnString();

  final role =
      RxnString();
}
```

Typical flow:

```text
Login
 ↓
Fetch memberships
 ↓
Choose restaurant
 ↓
Choose branch
 ↓
Set context
 ↓
Load dashboard
```

---

# 38. Branch Context Service

For customer ordering:

```dart
class BranchContextService
    extends GetxService {

  String? restaurantId;
  String? branchId;
  String? tableId;

  void configure({
    required String restaurant,
    required String branch,
    required String table,
  }) {
    restaurantId = restaurant;
    branchId = branch;
    tableId = table;
  }
}
```

---

# 39. QR Resolution Flow

```text
Customer scans QR
      ↓
Extract qr_token
      ↓
Call secure resolve_qr function
      ↓
Validate active table
      ↓
Get branch
      ↓
Get restaurant
      ↓
Return safe context
```

Example response:

```json
{
  "restaurant_id": "...",
  "restaurant_name": "Pizza House",
  "branch_id": "...",
  "branch_name": "Main Branch",
  "table_id": "...",
  "table_name": "Table 12"
}
```

---

# 40. Deep Linking Strategy

Recommended user experience:

```text
QR
 ↓
Universal/App Link
 ↓
App installed?
   │
   ├─ YES → Open Flutter app
   │
   └─ NO  → Open web ordering
```

For restaurant ordering, forcing a customer to install an app creates unnecessary friction.

Long-term recommended platform mix:

```text
Customer:
Flutter Android
Flutter iOS
Flutter Web / web ordering

Merchant:
Flutter Android
Flutter iOS
Optional Flutter Web/Desktop
```

---

# 41. Cart Architecture

Keep cart local until checkout.

```text
Product click
    ↓
CartController
    ↓
Local reactive state
```

Cart item example:

```dart
class CartItem {
  Product product;
  int quantity;
  List<SelectedModifier> modifiers;

  CartItem({
    required this.product,
    required this.quantity,
    required this.modifiers,
  });
}
```

---

# 42. Cart Controller Example

```dart
class CartController
    extends GetxController {

  final items = <CartItem>[].obs;

  void addItem(
    Product product,
    List<SelectedModifier> modifiers,
  ) {
    items.add(
      CartItem(
        product: product,
        quantity: 1,
        modifiers: modifiers,
      ),
    );
  }

  int get subtotalMinor {
    var total = 0;

    for (final item in items) {
      var unit =
          item.product.priceMinor;

      for (final modifier
          in item.modifiers) {
        unit +=
            modifier.priceMinor;
      }

      total +=
          unit * item.quantity;
    }

    return total;
  }
}
```

Important:

The cart total in Flutter is only for **display**.

The backend must recalculate the real total.

---

# 43. Never Trust Client Prices

Unsafe request:

```json
{
  "product_id": "burger123",
  "price": 1
}
```

Safe request:

```json
{
  "items": [
    {
      "product_id": "burger123",
      "quantity": 2,
      "modifier_ids": [
        "cheese123"
      ]
    }
  ]
}
```

The backend should:

```text
Fetch product
Validate availability
Fetch current price
Validate modifier
Fetch modifier price
Calculate subtotal
Calculate tax
Apply discount
Calculate final total
```

Flutter does not decide authoritative totals.

---

# 44. Atomic Order Creation

Do not do this directly from Flutter:

```text
insert order
insert item 1
insert item 2
insert payment
```

because connection failures can create partial data.

Instead create a PostgreSQL RPC:

```text
create_order(...)
```

Inside a transaction:

```text
BEGIN

validate customer/session
validate restaurant
validate branch
validate table
validate products
validate modifiers
fetch prices
calculate subtotal
calculate tax
apply coupon
calculate total

insert order
insert order items
insert order item modifiers
insert status history

COMMIT
```

Either everything succeeds or everything rolls back.

---

# 45. RPC vs Edge Functions

Use **PostgreSQL RPC** for mostly database-centric operations:

```text
resolve_qr
create_order
change_order_status
apply_coupon
get_menu
```

Use **Edge Functions** for external integrations:

```text
Razorpay
Stripe
Cashfree
PayPal
WhatsApp
SMS
Email
Push notifications
External delivery APIs
Webhook processing
```

---

# 46. Payment Architecture

Recommended flow:

```text
Customer
   ↓
Checkout
   ↓
create_order
   ↓
Backend calculates final total
   ↓
Edge Function creates payment session
   ↓
Payment gateway
   ↓
Customer pays
   ↓
Gateway webhook
   ↓
Edge Function verifies signature
   ↓
payments.status = paid
   ↓
order.status = placed
```

Never trust only:

```text
Flutter says payment successful
```

A server-side verified webhook should determine payment truth.

---

# 47. Payment Safety Rules

Flutter may request:

```text
Create payment for order X
```

Flutter must **not** directly:

```text
Set payment = paid
Set refund = complete
Modify order total
Modify gateway identifiers
```

Restrict these operations through RLS and server-only functions.

---

# 48. Realtime Order Architecture

Merchant app:

```text
Initial query
    +
Realtime subscription
```

Flow:

```text
Customer order
    ↓
PostgreSQL insert
    ↓
Supabase Realtime
    ↓
Admin/KDS
    ↓
New Order UI
```

Example repository stream:

```dart
Stream<List<Map<String, dynamic>>>
watchOrders(
  String branchId,
) {
  return supabase
      .from('orders')
      .stream(
        primaryKey: ['id'],
      )
      .eq(
        'branch_id',
        branchId,
      );
}
```

---

# 49. Live Orders Controller Example

```dart
class LiveOrdersController
    extends GetxController {

  final orders =
      <OrderModel>[].obs;

  StreamSubscription?
      subscription;

  void watchOrders(
    String branchId,
  ) {
    subscription =
        repository
            .watchOrders(branchId)
            .listen((rows) {

      orders.value =
          rows
              .map(
                OrderModel.fromJson,
              )
              .toList();
    });
  }

  @override
  void onClose() {
    subscription?.cancel();
    super.onClose();
  }
}
```

---

# 50. Customer Live Order Tracking

Customer subscribes to their own order.

```text
Order #854
    ↓
Realtime
```

Possible status UI:

```text
Order received
Accepted
Preparing
Ready
Served
Completed
```

No constant polling is needed while Realtime is connected.

---

# 51. Kitchen Display System

Example UI:

```text
NEW

#104
Table 4
2m ago

Burger ×2
Coke ×1


PREPARING

#102
Table 9
8m ago

Pizza ×1


READY

#99
Table 2
13m ago
```

Possible statuses:

```text
PLACED
 ↓
ACCEPTED
 ↓
PREPARING
 ↓
READY
 ↓
SERVED
 ↓
COMPLETED
```

---

# 52. Server-Controlled Status Transitions

Do not allow arbitrary state changes.

Valid transitions might be:

```text
placed → accepted
accepted → preparing
preparing → ready
ready → served
served → completed
```

Invalid example:

```text
completed → preparing
```

Use RPC/server logic to enforce valid transitions.

---

# 53. Storage Architecture

Menu images belong in Supabase Storage.

Suggested path:

```text
menu-images/
   restaurantId/
      products/
         productId/
            main.webp
```

Flow:

```text
Admin selects image
    ↓
Compress image
    ↓
Upload to Storage
    ↓
Save path/URL in product
    ↓
Customer loads cached image
```

Do not store large binary product images directly in PostgreSQL.

---

# 54. Row Level Security

RLS is mandatory.

Never assume Flutter restrictions are security.

A modified client can attempt:

```text
change branch_id
change restaurant_id
change order_id
change product_id
```

The database must verify every sensitive request.

---

# 55. Restaurant Membership Helper

Example:

```sql
create or replace function
public.is_restaurant_member(
    target_restaurant uuid
)
returns boolean

language sql
stable
security definer
set search_path = ''

as $$

select exists (
    select 1
    from public.restaurant_members rm
    where
        rm.restaurant_id =
            target_restaurant

        and rm.user_id =
            auth.uid()

        and rm.is_active = true
);

$$;
```

Review all `SECURITY DEFINER` functions carefully.

---

# 56. Example Restaurant RLS

```sql
alter table restaurants
enable row level security;
```

Example:

```sql
create policy
"staff can read own restaurants"

on restaurants

for select

to authenticated

using (
    public.is_restaurant_member(id)
);
```

---

# 57. Product Security Concept

Public customer permissions:

```text
products
SELECT ✅

products
INSERT ❌
UPDATE ❌
DELETE ❌
```

Authorized restaurant staff:

```text
products
SELECT ✅
INSERT ✅
UPDATE ✅
DELETE/ARCHIVE ✅
```

All write permissions must verify restaurant membership and branch ownership.

---

# 58. Public Menu vs Private Admin Data

Public/readable examples:

```text
active restaurant
active branch
active categories
available products
public modifier options
```

Private data:

```text
staff membership
payment internal references
audit logs
financial reports
refund records
internal notes
supplier data
inventory costs
```

Separate policies carefully.

---

# 59. Admin Permissions

Recommended role permissions:

| Role | Orders | Menu | Refund | Staff | Reports |
|---|---:|---:|---:|---:|---:|
| Owner | Yes | Yes | Yes | Yes | Yes |
| Manager | Yes | Yes | Yes | Yes | Yes |
| Cashier | Yes | No/Limited | Limited | No | Limited |
| Waiter | Limited | No | No | No | No |
| Kitchen | KDS only | No | No | No | No |

Later you can add capability-based permissions:

```text
order.view
order.accept
order.cancel
order.refund
menu.view
menu.edit
staff.manage
report.view
settings.edit
```

---

# 60. Optimized Menu Loading

Avoid N+1 queries.

Bad:

```text
Get categories

For every category:
    Get products

For every product:
    Get modifiers
```

Instead create one menu endpoint/RPC:

```text
get_menu(branch_id)
```

Return a nested structure:

```json
{
  "restaurant": {},
  "categories": [
    {
      "id": "...",
      "name": "Pizza",
      "products": [
        {
          "id": "...",
          "name": "Farmhouse",
          "price_minor": 39900,
          "modifier_groups": []
        }
      ]
    }
  ]
}
```

This greatly reduces mobile network round trips.

---

# 61. Database Indexes

Useful indexes:

```sql
create index
idx_products_branch_category
on products(
    branch_id,
    category_id
);
```

```sql
create index
idx_orders_branch_status_created
on orders(
    branch_id,
    status,
    created_at desc
);
```

```sql
create index
idx_orders_customer
on orders(
    customer_id,
    created_at desc
);
```

```sql
create index
idx_members_user
on restaurant_members(
    user_id,
    restaurant_id
);
```

---

# 62. Soft Delete Strategy

Avoid deleting important menu history.

Prefer:

```text
is_available = false
```

or:

```text
deleted_at = now()
```

instead of physically deleting products.

Historical orders must remain readable forever.

---

# 63. Push Notifications

Realtime works well while an app is active.

For background alerts:

```text
New order
   ↓
Database / Edge Function
   ↓
Push provider / FCM
   ↓
Restaurant device
```

Example push:

```text
New Order #492
Table 8
₹746
```

Use:

- Realtime for live open-app sync
- Push notifications for background attention

---

# 64. Local Cart Persistence

Persist:

```text
restaurant_id
branch_id
table_id
cart_items
```

Use local storage such as GetStorage or another appropriate local store.

Important:

```text
If branch changes:
    clear or validate cart
```

Never allow a cart from Restaurant A to be submitted to Restaurant B.

---

# 65. Idempotency

A customer may tap “Place Order” twice.

Without protection:

```text
Order #100
Order #101
```

Use an idempotency key.

Example:

```text
checkout_session_abc123
```

Recommended unique index:

```sql
create unique index
unique_order_idempotency
on orders(
    customer_id,
    idempotency_key
);
```

Repeated requests should return the same order rather than create duplicates.

---

# 66. UI State Management

Recommended state model:

```dart
enum ViewState {
  initial,
  loading,
  success,
  empty,
  error,
}
```

Use explicit states for complex pages.

Avoid using only:

```text
isLoading
```

for every screen.

---

# 67. GetX Controller Design Rules

Do not create one huge global controller.

Bad:

```text
AppController
    4000+ lines
```

containing:

```text
auth
menu
cart
orders
payments
admin
inventory
analytics
```

Instead create focused controllers:

```text
AuthController
MenuController
ProductController
CartController
CheckoutController
PaymentController
OrderTrackingController
OrderHistoryController
ProfileController
```

Admin:

```text
AdminAuthController
DashboardController
LiveOrdersController
OrderDetailController
KitchenController
CategoryController
ProductController
ModifierController
TableController
StaffController
ReportsController
SettingsController
```

---

# 68. Reactive State Rules

Use `.obs` only when UI needs to react.

Good:

```dart
final isLoading = false.obs;

final cartItems =
    <CartItem>[].obs;
```

Avoid unnecessarily making static configuration reactive.

---

# 69. Security Boundary

Treat every Flutter client as untrusted.

A client can be modified to attempt:

```text
change total
change restaurant
change branch
change role
change payment status
change product price
change table
change order status
```

The backend must validate all sensitive operations.

---

# 70. Logic Placement

| Logic | Flutter | Backend |
|---|---:|---:|
| Display product price | Yes | |
| Temporary cart total | Yes | |
| Final order total | | Yes |
| Validate coupon | | Yes |
| Validate item availability | | Yes |
| Login form | Yes | |
| Authorization | | Yes |
| UI navigation | Yes | |
| Payment verification | | Yes |
| Webhook secret | | Yes |
| Order tracking UI | Yes | |
| Legal status transition | | Yes |
| Refund decision rules | | Yes |
| Tax calculation | Optional preview | Yes |

---

# 71. Complete Dine-In Order Flow

```text
CUSTOMER
   │
   │ Scan QR
   ▼
Resolve QR
   │
   ▼
Restaurant + Branch + Table
   │
   ▼
Load Menu
   │
   ▼
Add Product
   │
   ▼
Select Modifiers
   │
   ▼
Cart
   │
   ▼
Checkout
   │
   ▼
create_order RPC
   │
   ├─ Verify table
   ├─ Verify products
   ├─ Verify availability
   ├─ Fetch current prices
   ├─ Validate modifiers
   ├─ Calculate tax
   ├─ Apply discount
   └─ Calculate final total
   │
   ▼
ORDER
   │
   ▼
Payment required?
   │
   ├───────────────┐
   │               │
 NO                YES
   │               │
   │               ▼
   │         Payment Provider
   │               │
   │               ▼
   │         Verified Webhook
   │               │
   └───────┬───────┘
           │
           ▼
         PLACED
           │
           │ Realtime
           ▼
      RESTAURANT APP
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
```

---

# 72. Takeaway Flow

```text
Open restaurant menu
    ↓
Choose takeaway
    ↓
Browse menu
    ↓
Cart
    ↓
Checkout
    ↓
Customer details
    ↓
Payment
    ↓
Order accepted
    ↓
Preparing
    ↓
Ready for pickup
    ↓
Completed
```

---

# 73. Delivery Flow

Recommended as a later phase.

```text
Open restaurant menu
    ↓
Choose delivery
    ↓
Enter/select address
    ↓
Validate delivery zone
    ↓
Calculate delivery charge
    ↓
Cart
    ↓
Checkout
    ↓
Payment
    ↓
Restaurant accepts
    ↓
Preparing
    ↓
Out for delivery
    ↓
Delivered
```

Additional tables later:

```text
customer_addresses
delivery_zones
delivery_fees
drivers
delivery_assignments
```

---

# 74. Table QR Generation

Admin flow:

```text
Admin
 ↓
Create Table
 ↓
Table 12
 ↓
Backend generates qr_token
 ↓
Create QR image
 ↓
Download/print
 ↓
Place on restaurant table
```

QR should encode a stable resolver URL, not raw editable IDs.

---

# 75. Basic Dashboard Metrics

Initial dashboard should show:

```text
Today's orders
Today's sales
Average order value
Completed orders
Cancelled orders
Active orders
Top products
Top categories
```

Later:

```text
Hourly sales
Weekly sales
Monthly sales
Preparation time
Table turnover
Customer retention
Coupon performance
Branch comparison
Refund rate
Payment method split
```

---

# 76. Inventory — Future Phase

Do not make inventory part of the first MVP unless required.

Future model:

```text
Ingredient
 ↓
Recipe
 ↓
Product
```

Example:

```text
Chicken Burger

Chicken   150 g
Bun       1
Cheese    1
Sauce     30 g
```

Selling two burgers:

```text
Chicken -300 g
Bun     -2
Cheese  -2
Sauce   -60 g
```

Future inventory tables:

```text
ingredients
recipes
recipe_items
stock_locations
stock_transactions
suppliers
purchase_orders
waste_logs
```

---

# 77. CRM — Future Phase

Possible features:

```text
Customer profile
Phone/email
Total orders
Lifetime value
Favorite products
Last order date
Loyalty points
Coupons
Segments
WhatsApp campaign consent
```

Possible customer segments:

```text
New
Returning
VIP
Inactive
High-value
Frequent takeaway
Frequent dine-in
```

---

# 78. Loyalty — Future Phase

Possible model:

```text
Customer
 ↓
Loyalty Account
 ↓
Points Transactions
```

Examples:

```text
₹100 spent → 10 points
500 points → ₹50 discount
```

Need server-side validation for points earn/redemption.

---

# 79. Reservations — Future Phase

Potential tables:

```text
reservations
reservation_guests
reservation_status_history
restaurant_opening_hours
special_closures
```

Possible statuses:

```text
pending
confirmed
seated
completed
cancelled
no_show
```

---

# 80. AI Features — Future Phase

Potential later features:

```text
AI menu assistant
Product recommendation
Upselling
Natural-language search
Menu translation
Review summarization
Demand forecasting
Inventory forecasting
Restaurant analytics explanations
```

Do not build these before the core ordering flow is stable.

---

# 81. Error Handling Strategy

Common errors:

```text
No internet
Supabase timeout
Expired auth session
Invalid QR
Inactive table
Restaurant closed
Product unavailable
Modifier unavailable
Payment failed
Order already created
Duplicate payment attempt
Unauthorized staff action
Realtime disconnected
```

Every feature should have:

```text
Loading
Success
Empty
Error
Retry
```

where appropriate.

---

# 82. Offline Considerations

Customer app:

- Keep cart locally
- Cache menu where reasonable
- Prevent checkout if current prices cannot be validated
- Show connectivity status

Merchant app:

- Cache latest orders locally if useful
- Reconnect Realtime automatically
- Re-fetch current orders after reconnect
- Avoid assuming a missed socket event means no changes occurred

For true offline POS, additional synchronization architecture is required.

---

# 83. Logging and Audit

Recommended server-side audit events:

```text
staff login
menu price change
product disabled
order cancelled
payment refunded
staff permission changed
restaurant settings changed
manual order edit
```

Future audit table:

```text
audit_logs
```

Fields:

```text
id
restaurant_id
branch_id
actor_user_id
action
entity_type
entity_id
old_value
new_value
created_at
```

---

# 84. Recommended MVP Scope

## Customer MVP

```text
QR scan / deep link
Restaurant menu
Categories
Products
Modifiers
Cart
Dine-in ordering
Takeaway ordering
Cash payment
Online payment
Live order tracking
Basic profile
Order history
```

## Merchant MVP

```text
Login
Restaurant
Branch
Category management
Product management
Modifier management
Table management
QR generation
Live orders
Accept order
KDS
Order status changes
Order history
Basic dashboard
Staff roles
```

---

# 85. Features to Delay

Do not build first:

```text
AI waiter
full inventory ERP
driver fleet
hotel PMS
accounting suite
advanced CRM
advanced loyalty
full reservation engine
multi-language AI
vendor purchase automation
complex franchise accounting
```

First prove this flow:

```text
QR
→ Menu
→ Cart
→ Order
→ Kitchen
→ Payment
→ Tracking
```

---

# 86. Development Order

Recommended implementation sequence:

## Phase 1 — Foundation

```text
Create Supabase project
Configure local environments
Create schema
Create migrations
Create RLS
Create indexes
Create seed data
Set up two Flutter apps
Set up shared packages
Set up GetX routing/bindings
```

## Phase 2 — Merchant Menu Management

```text
Admin auth
Restaurant membership
Branch selection
Categories
Products
Modifiers
Tables
QR tokens
Storage images
```

## Phase 3 — Customer Menu

```text
QR scanner
Deep linking
Resolve QR
Branch context
Menu loading
Categories
Product details
Modifier selection
```

## Phase 4 — Cart

```text
Cart controller
Quantity
Modifiers
Local persistence
Branch validation
Subtotal preview
```

## Phase 5 — Secure Ordering

```text
create_order RPC
Price validation
Tax calculation
Discount rules
Idempotency
Order item snapshots
Order history
```

## Phase 6 — Merchant Orders

```text
Live orders
Realtime
Order detail
Status changes
KDS
Status history
```

## Phase 7 — Customer Tracking

```text
Realtime order tracking
Status timeline
Current order
Order history
```

## Phase 8 — Payments

```text
Payment provider
Edge Function
Payment session creation
Webhook verification
Payment status
Refund flow
```

## Phase 9 — Production Hardening

```text
RLS tests
Rate limits
Indexes
Logging
Crash reporting
Push notifications
Reconnect behavior
Analytics
Backups
Monitoring
```

---

# 87. Testing Strategy

## Unit Tests

Test:

```text
Money calculations
Cart calculations
Model parsing
Controller state transitions
Repository error mapping
```

## Database Tests

Test:

```text
RLS policies
Restaurant isolation
Branch isolation
Role permissions
create_order validation
Duplicate order prevention
Invalid status transitions
```

## Integration Tests

Test:

```text
QR → Menu
Menu → Cart
Cart → Checkout
Checkout → Order
Order → KDS
KDS → Customer tracking
Payment → Webhook → Order
```

## Security Tests

Attempt:

```text
User A reads Restaurant B
User A edits Restaurant B product
Customer marks payment paid
Kitchen user edits restaurant settings
Cashier modifies owner role
Customer changes order total
Customer changes branch
```

Every unauthorized operation must fail server-side.

---

# 88. Environment Configuration

Recommended environments:

```text
development
staging
production
```

Use separate Supabase projects where practical.

Never test risky migrations directly on production.

Recommended config values:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
APP_ENV
PAYMENT_PUBLIC_KEY
```

Server-only:

```text
SUPABASE_SERVICE_ROLE_KEY
PAYMENT_SECRET_KEY
WEBHOOK_SECRET
SMS_SECRET
WHATSAPP_SECRET
```

---

# 89. Production Checklist

Before launch verify:

```text
[ ] All tables requiring RLS have RLS enabled
[ ] Public reads are intentionally limited
[ ] Service role key is not in Flutter
[ ] Payment secrets are server-side only
[ ] Payment webhooks are signature verified
[ ] Order totals are server calculated
[ ] Status transitions are server validated
[ ] Idempotency is implemented
[ ] Menu image policies are correct
[ ] Realtime enabled only where required
[ ] Important queries have indexes
[ ] Logs and crash reporting exist
[ ] Push notifications tested
[ ] Database backups configured
[ ] Error states tested
[ ] Empty states tested
[ ] Low network quality tested
[ ] Duplicate submit tested
[ ] Customer cannot access another customer’s private order
[ ] Staff cannot access other restaurants
[ ] Refund permissions tested
[ ] Deep links tested
[ ] QR fallback web flow tested
```

---

# 90. Final Architecture Summary

```text
                     SUPABASE
                        │
        ┌───────────────┼────────────────┐
        │               │                │
       AUTH         POSTGRESQL        STORAGE
                        │
                        │
                     RLS / RPC
                        │
                        │
                    REALTIME
                        │
                        │
                 EDGE FUNCTIONS
                        │
              Payments / Push / APIs
                        │
       ┌────────────────┴─────────────────┐
       │                                  │
CUSTOMER FLUTTER                    MERCHANT FLUTTER
       │                                  │
      GetX                               GetX
       │                                  │
      MVC                                MVC
       │                                  │
View → Controller → Repository   View → Controller → Repository
       │                                  │
       └──────────── Supabase ────────────┘
```

Core principle:

> **Flutter owns presentation and temporary UI state. Supabase/PostgreSQL owns trust, permissions, pricing, order truth, payment truth, and critical business rules.**

---

# 91. Recommended First Milestone

The first milestone should be:

```text
1. Owner logs in
2. Owner creates restaurant
3. Owner creates branch
4. Owner creates categories
5. Owner creates products
6. Owner creates table
7. System generates QR
8. Customer scans QR
9. Customer sees menu
10. Customer adds items
11. Customer places order
12. Order appears in KDS
13. Kitchen accepts order
14. Customer sees live status
15. Order is completed
```

Only after this full flow works reliably should you add advanced features.

---

# 92. Future Expansion Roadmap

After MVP:

```text
Phase 2
- Coupons
- Loyalty
- Push notifications
- Advanced reports
- Better customer profiles
- Takeaway scheduling

Phase 3
- Delivery zones
- Driver management
- Reservations
- CRM
- WhatsApp notifications

Phase 4
- Inventory
- Recipe costing
- Supplier management
- Purchase orders

Phase 5
- Multi-branch enterprise
- Franchise controls
- Advanced permissions
- Accounting integrations

Phase 6
- AI recommendations
- AI waiter
- AI translations
- Forecasting
- Automated marketing
```

---

# 93. Key Rules to Remember

1. **Never trust Flutter for final prices.**
2. **Never place service role secrets in the app.**
3. **Use RLS for restaurant and customer isolation.**
4. **Use server-side payment verification.**
5. **Use RPC/transactions for order creation.**
6. **Use idempotency for checkout and payment actions.**
7. **Store order snapshots for historical accuracy.**
8. **Use Realtime for active order/KDS updates.**
9. **Use push notifications for background alerts.**
10. **Keep controllers small and feature-specific.**
11. **Use repositories between controllers and Supabase.**
12. **Do not require an app install just to scan a restaurant QR.**
13. **Build the ordering core before advanced ERP features.**
14. **Design multi-tenant security from day one.**
15. **Test RLS and authorization like they are backend API endpoints.**

---

# 94. Suggested Next Technical Documents

After this architecture document, create:

```text
01_DATABASE_SCHEMA.md
02_RLS_POLICIES.md
03_CUSTOMER_APP_FLOW.md
04_MERCHANT_APP_FLOW.md
05_SUPABASE_RPC_FUNCTIONS.md
06_PAYMENT_ARCHITECTURE.md
07_REALTIME_KDS.md
08_API_CONTRACTS.md
09_FLUTTER_FOLDER_STRUCTURE.md
10_MVP_TASK_LIST.md
```

These can become the technical documentation set for the repository.

---

# 95. Project Success Definition

The platform is ready for its first real restaurant pilot when:

```text
Restaurant can onboard
Restaurant can build menu
Restaurant can create QR tables
Customer can scan without friction
Customer can order
Backend validates everything securely
Kitchen receives order immediately
Staff can process it
Customer sees live status
Payment is safely verified
Order history remains accurate
Restaurants cannot access each other's data
```

That is the foundation for a scalable QR restaurant ordering SaaS.
