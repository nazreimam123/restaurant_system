# ADMIN_APP_FLOW.md
## QR Restaurant Ordering Platform — Flutter + GetX + MVC + Supabase

> Complete admin/merchant application flow and implementation blueprint for the QR restaurant ordering platform.
>
> This document focuses on the **restaurant/admin/merchant application** used by owners, managers, cashiers, waiters, and kitchen staff.
>
> It covers authentication, restaurant/branch selection, dashboard, live orders, KDS, menu management, modifiers, tables, QR generation, staff permissions, payments, refunds, analytics, settings, realtime, local state, GetX architecture, Supabase interaction, RLS/security, testing, deployment, and future modules.

---

# 1. Admin App Goal

The admin app should allow restaurant teams to:

- Sign in securely
- Access only restaurants they belong to
- Access only permitted branches
- Switch restaurant/branch context
- View live orders
- Accept/reject/cancel orders according to permission
- Move orders through legal statuses
- Use Kitchen Display System
- Manage categories
- Manage products
- Manage modifiers
- Mark products sold out
- Manage tables
- Generate/rotate QR codes
- Manage staff
- View roles and permissions
- View payments
- Confirm cash payments
- Request refunds if permitted
- View sales analytics
- View order history
- Manage branch settings
- Manage restaurant settings
- Manage order types
- Manage tax/service-charge settings
- Receive push notifications
- Work with multiple outlets
- Support future inventory
- Support future CRM
- Support future reservations
- Support future loyalty
- Support future delivery operations

---

# 2. Admin App User Roles

Primary roles:

```text
Owner
Manager
Cashier
Waiter
Kitchen
```

Recommended responsibility split:

| Role | Main Responsibility |
|---|---|
| Owner | Full business control |
| Manager | Daily operations |
| Cashier | Orders, billing, payments |
| Waiter | Table/order service |
| Kitchen | KDS and kitchen status |

---

# 3. Role Permission Principle

The UI may hide actions.

But the backend must enforce every sensitive action.

Never rely on:

```text
if role == owner
```

inside Flutter as security.

Use:

```text
restaurant_members
branch_members
RLS
RPC authorization
```

on Supabase.

---

# 4. Admin Application Platforms

Recommended:

```text
Flutter Android
Flutter iOS
Flutter Web
```

Optional later:

```text
Flutter Windows
Flutter macOS
```

Best usage:

```text
Mobile:
owner, manager, waiter

Tablet:
KDS, cashier

Web:
owner, reports, menu management
```

---

# 5. High-Level Architecture

```text
ADMIN USER
    ↓
FLUTTER VIEW
    ↓
GETX CONTROLLER
    ↓
REPOSITORY
    ↓
SUPABASE
    │
    ├── Auth
    ├── PostgreSQL
    ├── RPC
    ├── Realtime
    ├── Storage
    └── Edge Functions
```

Recommended application pattern:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Supabase
```

For high-integrity operations:

```text
Controller
 ↓
Repository
 ↓
RPC / Edge Function
 ↓
PostgreSQL
```

---

# 6. Admin Folder Structure

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
│   ├── network/
│   ├── storage/
│   └── widgets/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── dto/
│
└── features/
    ├── splash/
    ├── auth/
    ├── restaurant_select/
    ├── branch_select/
    ├── dashboard/
    ├── live_orders/
    ├── order_detail/
    ├── kds/
    ├── categories/
    ├── products/
    ├── modifiers/
    ├── tables/
    ├── qr/
    ├── payments/
    ├── refunds/
    ├── staff/
    ├── reports/
    ├── settings/
    ├── notifications/
    ├── inventory/
    └── profile/
```

---

# 7. Core Admin Routes

Recommended:

```text
/splash
/login
/select-restaurant
/select-branch
/dashboard
/orders
/orders/:id
/kds
/categories
/products
/products/:id
/modifiers
/tables
/tables/:id
/staff
/payments
/reports
/settings
/profile
```

---

# 8. App Startup Flow

```text
App starts
 ↓
Supabase.initialize()
 ↓
InitialBinding
 ↓
SplashPage
 ↓
AdminStartupController
```

Startup checks:

```text
auth session
restaurant membership
saved restaurant context
saved branch context
role
permission availability
pending notification deep link
```

---

# 9. Startup Decision Tree

```text
Session exists?
   │
   ├── NO → Login
   │
   └── YES
         ↓
   Restaurant membership exists?
         │
         ├── NO → No Access / Invitation
         │
         └── YES
               ↓
        One restaurant?
          │
          ├── YES → select automatically
          └── NO  → Restaurant Select
               ↓
        One branch?
          │
          ├── YES → Dashboard
          └── NO  → Branch Select
```

---

# 10. Admin Authentication

Recommended MVP:

```text
Email + Password
```

Optional:

```text
Phone OTP
Magic link
MFA later
```

Do not allow public user signup to automatically become staff.

Authentication only proves:

```text
who user is
```

Membership tables determine:

```text
what user can access
```

---

# 11. Admin Login Flow

```text
Login screen
 ↓
Submit credentials
 ↓
Supabase Auth
 ↓
Session created
 ↓
Load restaurant memberships
 ↓
Validate active membership
 ↓
Select context
```

---

# 12. AdminAuthController

Responsibilities:

```text
email/password login
phone OTP later
loading state
auth errors
logout
session refresh
navigate after auth
```

Suggested state:

```dart
final isLoading = false.obs;
final errorMessage = RxnString();
```

---

# 13. SessionService

Global service responsibilities:

```text
current auth user
auth state changes
logout
session expiry
token refresh
```

Example:

```dart
class AdminSessionService
    extends GetxService {

  SupabaseClient get client =>
      Supabase.instance.client;

  User? get user =>
      client.auth.currentUser;

  String? get userId =>
      user?.id;

  bool get isAuthenticated =>
      client.auth.currentSession != null;
}
```

---

# 14. Restaurant Membership

After login:

```text
auth.uid()
 ↓
restaurant_members
 ↓
restaurants user belongs to
```

Example:

```text
User A

Pizza House → owner
Cafe 22 → manager
```

---

# 15. Restaurant Select Screen

If multiple memberships:

```text
Choose restaurant

Pizza House
Owner

Cafe 22
Manager
```

Select one and save context.

---

# 16. MerchantContextService

Recommended global context:

```dart
class MerchantContextService
    extends GetxService {

  final restaurantId = RxnString();
  final restaurantName = RxnString();

  final branchId = RxnString();
  final branchName = RxnString();

  final role = RxnString();

  bool get hasRestaurant =>
      restaurantId.value != null;

  bool get hasBranch =>
      branchId.value != null;
}
```

---

# 17. Context Security

MerchantContextService is UX state only.

Backend still validates:

```text
restaurant membership
branch membership
role
permission
```

every sensitive operation.

---

# 18. Branch Selection

After restaurant selection:

```text
restaurant
 ↓
branches accessible by user
```

Owner/manager may see:

```text
all branches
```

Cashier/waiter/kitchen may see:

```text
only assigned branches
```

according to backend rules.

---

# 19. Branch Select Screen

Example:

```text
Pizza House

Select branch

Patna Main
Boring Road
Kankarbagh
```

---

# 20. Branch Switching

Switching branch should:

```text
close old realtime subscriptions
update MerchantContextService
clear branch-specific controller caches
load new branch dashboard
subscribe new branch orders
```

Never keep old branch realtime subscription alive.

---

# 21. Dashboard

Dashboard is role-aware.

Owner/manager:

```text
sales
orders
average order
live order count
top products
payment split
branch performance
```

Cashier:

```text
live orders
pending payments
cash summary
```

Kitchen:

```text
active KDS only
```

Waiter:

```text
active dine-in orders
tables
ready orders
```

---

# 22. Dashboard Layout

Example:

```text
Pizza House
Patna Main

Today
-------------------------
Sales          ₹24,820
Orders              86
Average         ₹288.60
Active               7
-------------------------

Order Status
Placed       2
Preparing    3
Ready        2

Top Items
1. Farmhouse Pizza
2. Veg Burger
3. Cold Coffee
```

---

# 23. DashboardController

Responsibilities:

```text
load summary
refresh date range
load active order counts
load top products
load payment summary
handle branch context
```

Prefer server RPC:

```text
get_dashboard_summary
```

instead of 10 independent queries.

---

# 24. Dashboard Time Range

Possible:

```text
Today
Yesterday
Last 7 days
This month
Custom
```

Server validates branch access.

---

# 25. Live Orders Module

This is one of the most important admin features.

Statuses:

```text
placed
accepted
preparing
ready
served
```

Depending on order type.

---

# 26. Live Orders Screen

Possible tabs:

```text
New
Accepted
Preparing
Ready
All Active
```

Cards:

```text
#1042
Table 12
2 min ago
₹892.50

2 × Farmhouse Pizza
1 × Coke

[Accept]
```

---

# 27. LiveOrdersController

Responsibilities:

```text
initial active order fetch
Realtime subscription
filter by status
sort orders
handle reconnect
play alert for new orders
dispose old subscription
```

---

# 28. Live Order Data Flow

```text
Customer creates order
 ↓
PostgreSQL
 ↓
Realtime event
 ↓
OrderRepository
 ↓
LiveOrdersController
 ↓
UI card appears
 ↓
sound/vibration
```

---

# 29. Initial Fetch + Realtime

Always:

```text
initial database query
+
Realtime subscription
```

Do not rely only on Realtime.

Reason:

```text
app may have been offline
events may have happened before subscription
```

---

# 30. Reconnect Strategy

When:

```text
network restored
app resumed
auth token refreshed
branch switched
```

do:

```text
refetch active orders
re-subscribe
```

Database remains source of truth.

---

# 31. New Order Alert

On new `placed` order:

```text
play sound
vibrate
show visual alert
```

If app background:

```text
push notification
```

---

# 32. Duplicate Alert Prevention

Maintain:

```text
known order IDs
last seen timestamp
```

Avoid playing new-order sound again on every refetch.

---

# 33. Order Detail Screen

Show:

```text
order number
status
order type
table
customer info if permitted
items
modifiers
notes
subtotal
tax
service charge
discount
total
payment
status timeline
actions
```

---

# 34. Order Detail Permission

Role-specific:

Kitchen may see:

```text
items
notes
table
status
```

but not necessarily:

```text
customer phone
payment details
refund actions
profit/report data
```

---

# 35. Order Actions

Possible:

```text
Accept
Start Preparing
Mark Ready
Mark Served
Complete
Cancel
Refund
Print
Call Customer
```

Only show authorized/legal actions.

---

# 36. Order Status State Machine

Recommended:

```text
awaiting_payment
      ↓
placed
      ↓
accepted
      ↓
preparing
      ↓
ready
      ↓
served
      ↓
completed
```

Takeaway:

```text
ready
 ↓
completed
```

---

# 37. Status Change Rule

Flutter calls:

```text
change_order_status RPC
```

Never:

```dart
supabase
  .from('orders')
  .update({'status': 'ready'});
```

for critical workflow.

Backend validates:

```text
role
branch
current status
new status
order type
```

---

# 38. Status Action Mapping

Example:

```text
placed
→ Accept

accepted
→ Start Preparing

preparing
→ Mark Ready

ready + dine_in
→ Mark Served

served
→ Complete
```

---

# 39. Cancellation

Cancellation may be permitted to:

```text
owner
manager
cashier
```

depending on policy.

Require reason:

```text
customer request
item unavailable
duplicate
payment issue
restaurant issue
other
```

---

# 40. Cancellation Flow

```text
Cancel
 ↓
Enter reason
 ↓
RPC
 ↓
validate role/status
 ↓
cancel order
 ↓
status history
 ↓
refund logic if needed
 ↓
customer realtime update
```

---

# 41. Kitchen Display System

Dedicated KDS view optimized for tablet.

Columns:

```text
NEW
PREPARING
READY
```

or:

```text
NEW
ACCEPTED
PREPARING
READY
```

---

# 42. KDS Card

Example:

```text
#1042
TABLE 12
02:31

2 × Farmhouse Pizza
  - Large
  - Extra cheese

1 × Coke

Note:
No onion

[START]
```

---

# 43. KDSController

Responsibilities:

```text
active kitchen orders
status columns
elapsed time
new order sounds
status updates
station filtering later
realtime
```

---

# 44. KDS Timer

Display:

```text
2 min
8 min
17 min
```

Calculate from:

```text
accepted_at
or
created_at
```

Do not write timer updates to database every minute.

UI calculates locally.

---

# 45. KDS Aging

Visual urgency:

```text
normal
warning
late
```

Example thresholds:

```text
0–10 min normal
10–20 warning
20+ late
```

Business configurable later.

---

# 46. Kitchen Stations Future

Future:

```text
Kitchen
Bar
Dessert
Beverage
Room Service
```

Order item routing:

```text
product
 ↓
kitchen station
```

Then each KDS receives only relevant items.

---

# 47. Kitchen Ticket Future

Possible table:

```text
kitchen_tickets
kitchen_ticket_items
```

Needed for split-station prep.

MVP may use whole order.

---

# 48. Menu Management

Admin hierarchy:

```text
Category
 ↓
Product
 ↓
Modifier Groups
 ↓
Modifiers
```

---

# 49. Category Screen

Functions:

```text
create
edit
reorder
activate/deactivate
image optional
```

Example:

```text
Starters
Pizza
Burger
Biryani
Drinks
Desserts
```

---

# 50. CategoryController

Responsibilities:

```text
load categories
add
edit
activate/deactivate
reorder
error handling
```

---

# 51. Category Reordering

Use:

```text
sort_order
```

Client can batch update order.

For robust implementation:

```text
reorder_categories RPC
```

or safe RLS updates.

---

# 52. Product List Screen

Show:

```text
image
name
category
price
availability
active/archive state
```

Quick action:

```text
Sold out toggle
```

---

# 53. Product States

Use:

```text
is_active
is_available
```

Meaning:

```text
is_active = false
→ archived/removed

is_available = false
→ temporarily sold out
```

---

# 54. Product Form

Fields:

```text
name
description
category
base price
image
veg/non-veg
availability
sort order
modifier groups
tags
```

---

# 55. ProductFormController

Responsibilities:

```text
form state
validation
image upload
category selection
modifier group assignment
save
update
archive
```

---

# 56. Money Input

Merchant enters:

```text
₹199.50
```

Convert to:

```text
19950
```

minor units.

Never persist float.

---

# 57. Image Upload Flow

```text
select image
 ↓
resize/compress
 ↓
upload Supabase Storage
 ↓
receive path
 ↓
save product image_path
```

---

# 58. Image Replacement

Safe:

```text
upload new
 ↓
save new path
 ↓
delete old
```

Not:

```text
delete old first
```

---

# 59. Modifier Group Management

Example:

```text
Size
min 1
max 1
required

Extras
min 0
max 4
optional
```

---

# 60. Modifier Management

Fields:

```text
name
price delta
availability
sort order
```

Example:

```text
Large +₹100
Extra Cheese +₹40
Olives +₹30
```

---

# 61. Product Modifier Assignment

Product can attach:

```text
Size
Crust
Extras
```

One modifier group can be reused across products.

---

# 62. Menu Validation

Admin UI should prevent:

```text
required group with min_select = 0
max_select < min_select
negative invalid price rules if business disallows
```

Backend constraints remain authority.

---

# 63. Sold Out Shortcut

Very important operational feature.

From product list:

```text
Burger
Available [toggle]
```

Tap:

```text
is_available = false
```

Customer cannot order it after next refresh/server validation.

---

# 64. Tables Module

Admin can:

```text
create table
edit name
set capacity
assign area
activate/deactivate
view QR
rotate QR
```

---

# 65. Dining Areas

Optional:

```text
Ground Floor
Rooftop
Garden
VIP
```

Useful for table grouping.

---

# 66. Table Screen

Example:

```text
Table 1
Table 2
Table 3
Table 4
```

Show:

```text
active
QR status
area
capacity
```

---

# 67. Create Table Flow

```text
Add Table
 ↓
name
capacity
area
 ↓
insert table
 ↓
backend generates qr_token
 ↓
QR display
```

---

# 68. QR Generation

QR payload:

```text
https://order.example.com/q/<qr_token>
```

Admin app generates visual QR from URL.

---

# 69. QR Actions

```text
View
Download
Share
Print
Rotate
```

For mobile:

```text
share image/PDF
```

For web:

```text
print sheet
```

---

# 70. QR Rotation

Use secure RPC:

```text
rotate_table_qr
```

Backend:

```text
validate branch permission
generate new token
update table
audit event
return new token
```

Old QR becomes invalid.

---

# 71. Table Deactivation

If table inactive:

```text
resolve_qr rejects
```

Historical orders remain linked.

---

# 72. Staff Management

Owner/manager can:

```text
view staff
invite
assign role
assign branches
deactivate
remove
```

according to permission.

---

# 73. Staff List

Example:

```text
Rahul
Manager
Patna Main

Aman
Kitchen
Patna Main

Priya
Cashier
Boring Road
```

---

# 74. Staff Invitation Flow

```text
Owner selects Invite
 ↓
email/phone
 ↓
role
 ↓
branch access
 ↓
backend creates invitation
 ↓
send invitation
 ↓
staff authenticates
 ↓
accept invitation
 ↓
membership created
```

---

# 75. StaffController

Responsibilities:

```text
load members
load invitations
invite
change role
assign branches
deactivate
remove
```

Critical changes should use RPC.

---

# 76. Role Change

Never direct-update own role casually.

Backend must prevent:

```text
manager → owner
```

unless authorized.

Owner transfer should be separate secure flow.

---

# 77. Staff Deactivation

Prefer:

```text
is_active = false
```

rather than delete.

Effect:

```text
future access blocked
history preserved
```

---

# 78. Branch Assignment

For cashier/waiter/kitchen:

```text
branch_members
```

Owner/manager may have restaurant-wide access.

---

# 79. Staff Permission UI

MVP:

```text
fixed roles
```

Later:

```text
capability permissions
```

Examples:

```text
orders.read
orders.accept
orders.cancel
menu.edit
payments.refund
reports.view
staff.manage
settings.edit
```

---

# 80. Payments Screen

Show:

```text
order number
amount
method
status
provider
time
```

Filters:

```text
paid
pending
failed
refunded
cash
online
```

---

# 81. Payment Detail

Display:

```text
order
amount
method
status
provider IDs
paid time
refund history
```

Hide sensitive raw gateway data.

---

# 82. Cash Payment Flow

For pay-later:

```text
Order exists
 ↓
cash pending
 ↓
cashier collects
 ↓
Mark cash received
 ↓
RPC
 ↓
payment paid
```

Customer cannot mark it.

---

# 83. Confirm Cash Payment

Use:

```text
confirm_cash_payment RPC
```

Validate:

```text
role
branch
order state
amount
existing payment
```

---

# 84. Refunds

Refund action restricted to:

```text
owner
manager
maybe cashier with permission
```

---

# 85. Refund Flow

```text
Open payment
 ↓
Refund
 ↓
enter amount/reason
 ↓
refund Edge Function
 ↓
provider API
 ↓
payment_refunds
 ↓
payment status updated
 ↓
audit log
```

---

# 86. Partial Refund

Later/if gateway supports:

```text
total ₹1000
refund ₹300
```

Payment status:

```text
partially_refunded
```

---

# 87. Refund Safety

Never call payment provider secret API directly from Flutter.

Use:

```text
Edge Function
```

---

# 88. Order History

Admin historical orders screen.

Filters:

```text
date
status
order type
payment method
table
customer
order number
```

---

# 89. Order History Pagination

Use pagination.

Do not load:

```text
all orders
```

for large restaurants.

---

# 90. Search Order

Search:

```text
order number
customer phone
customer name
```

Only if role allowed to see customer data.

---

# 91. Reports

MVP reports:

```text
sales
order count
average order value
top products
category sales
payment method split
cancelled orders
```

---

# 92. ReportsController

Use backend RPC/view:

```text
get_sales_report
get_product_sales
get_payment_summary
```

Do not aggregate huge datasets in Flutter.

---

# 93. Date Filters

```text
Today
Yesterday
7 days
30 days
This month
Custom
```

Backend uses restaurant timezone/business day rules.

---

# 94. Sales Semantics

Define whether sales means:

```text
paid payments
completed orders
gross order value
net after refund
```

Do not mix.

Recommended separate metrics:

```text
gross order value
paid revenue
refunds
net revenue
```

---

# 95. Dashboard vs Reports

Dashboard:

```text
fast operational summary
```

Reports:

```text
historical analysis
filters
export
```

---

# 96. Export Future

Future:

```text
CSV
PDF
Excel
```

Generate server-side for large datasets.

---

# 97. Restaurant Settings

Owner/manager settings:

```text
restaurant name
logo
currency
timezone
order types
tax
service charge
guest ordering
payment rules
notification rules
```

---

# 98. Branch Settings

```text
branch name
address
phone
opening hours
order availability
temporary closure
```

---

# 99. Order Type Settings

Backend config:

```text
allow_dine_in
allow_takeaway
allow_delivery
```

Admin app toggles according to permission.

---

# 100. Payment Settings

Possible:

```text
cash enabled
online enabled
payment-before-kitchen
gateway configured
```

Do not expose secret keys after setup.

---

# 101. Gateway Configuration

Prefer secure setup:

```text
owner enters credentials
 ↓
send to trusted Edge Function/admin backend
 ↓
store securely
```

Not:

```text
store secret in public restaurant_settings
```

---

# 102. Opening Hours

Admin can manage:

```text
Mon 10:00–23:00
Tue 10:00–23:00
...
```

Future multiple shifts:

```text
Lunch
Dinner
```

---

# 103. Temporary Closure

Useful:

```text
Pause orders
```

with reason:

```text
Kitchen overloaded
Private event
Maintenance
```

Customer app sees restaurant unavailable.

---

# 104. Pause Ordering

Can be:

```text
restaurant-wide
branch-wide
order-type specific
```

MVP branch-wide pause may be enough.

---

# 105. Notification Settings

Per merchant:

```text
new order sound
new order push
ready order alerts
payment alerts
refund alerts
```

---

# 106. Push Notifications

Merchant push events:

```text
new order
payment received
order cancelled
refund failed
critical system alert
```

---

# 107. Merchant Device Tokens

Store:

```text
user_id
token
platform
app_type = merchant
```

On logout:

```text
disable/remove token
```

as needed.

---

# 108. Push Deep Link

Example:

```text
New Order #1042
```

Tap:

```text
/orders/<uuid>
```

Backend RLS still validates access.

---

# 109. Background Behavior

Realtime may not stay active in background.

Use:

```text
Realtime foreground
Push background
```

---

# 110. App Lifecycle

On resume:

```text
refresh session
refresh context validity
refetch live orders
reconnect realtime
check notification target
```

---

# 111. ConnectivityService

Show banner:

```text
Offline
```

When disconnected.

Merchant may still view cached data, but should not assume actions are submitted.

---

# 112. Offline Orders

Do not mark status locally as final while offline unless building a real offline-sync architecture.

MVP:

```text
disable critical server actions
```

when network unavailable.

---

# 113. True Offline POS

This is a separate project.

Requires:

```text
local database
local IDs
sync queue
conflict resolution
offline payment rules
reconciliation
```

Do not pretend Supabase Realtime alone is offline POS.

---

# 114. Error Architecture

Standard app errors:

```text
NetworkError
UnauthorizedError
PermissionDeniedError
ValidationError
NotFoundError
ConflictError
PaymentError
ServerError
UnknownError
```

Repositories convert raw backend exceptions.

---

# 115. Permission Denied UX

Example:

```text
You don't have permission to perform this action.
```

Do not expose internal RLS details.

---

# 116. Session Revoked

If membership removed while app open:

```text
next request fails
 ↓
refresh membership
 ↓
show access removed
 ↓
return restaurant select/login
```

---

# 117. Context Invalidated

If branch deactivated:

```text
show:
This branch is no longer available.
```

Then switch branch.

---

# 118. Restaurant Deactivated

Show:

```text
This restaurant is currently inactive.
```

Allow owner contact/support actions if product needs.

---

# 119. GetX Services

Recommended:

```text
AdminSessionService
MerchantContextService
ConnectivityService
RealtimeService
NotificationService
AppLifecycleService
AnalyticsService
PermissionService
```

---

# 120. GetX Controllers

MVP:

```text
AdminStartupController
AdminAuthController
RestaurantSelectController
BranchSelectController
DashboardController
LiveOrdersController
OrderDetailController
KdsController
CategoryController
ProductController
ProductFormController
ModifierController
TableController
QrController
StaffController
PaymentsController
PaymentDetailController
ReportsController
SettingsController
ProfileController
```

---

# 121. Repositories

Recommended:

```text
AuthRepository
MerchantRepository
BranchRepository
DashboardRepository
OrderRepository
MenuRepository
ModifierRepository
TableRepository
StaffRepository
PaymentRepository
ReportRepository
SettingsRepository
NotificationRepository
```

---

# 122. Models

Recommended:

```text
RestaurantMembership
Restaurant
Branch
BranchMembership
DashboardSummary
Order
OrderItem
OrderModifier
OrderStatusEvent
Category
Product
ModifierGroup
Modifier
DiningArea
DiningTable
StaffMember
Payment
Refund
ReportSummary
RestaurantSettings
BranchSettings
NotificationItem
```

---

# 123. View Responsibility

View should:

```text
render
listen to Rx
call controller
show dialogs
```

Do not call Supabase directly from widgets.

---

# 124. Controller Responsibility

Controller should:

```text
manage state
call repository
coordinate navigation
map UI action
```

Do not:

```text
store server secrets
validate payment signatures
decide final permissions
```

---

# 125. Repository Responsibility

Repository:

```text
Supabase table CRUD
RPC
Edge Functions
Realtime streams
response mapping
```

No UI dialogs.

---

# 126. PermissionService

Client-side UX helper.

Example:

```dart
class PermissionService
    extends GetxService {

  bool canEditMenu(String role) {
    return [
      'owner',
      'manager',
    ].contains(role);
  }
}
```

Important:

```text
This only controls UI.
Backend still enforces security.
```

---

# 127. Role-Based Navigation

Kitchen role may land directly on:

```text
/kds
```

Cashier:

```text
/orders
```

Owner:

```text
/dashboard
```

---

# 128. Route Guarding

Client route guard can improve UX:

```text
kitchen tries /staff
→ redirect
```

But RLS/RPC remain real protection.

---

# 129. Dashboard Binding

Example:

```dart
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DashboardController(
        repository:
            Get.find<DashboardRepository>(),
        context:
            Get.find<MerchantContextService>(),
      ),
    );
  }
}
```

---

# 130. Orders Binding

```dart
class LiveOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LiveOrdersController(
        repository:
            Get.find<OrderRepository>(),
        context:
            Get.find<MerchantContextService>(),
      ),
    );
  }
}
```

---

# 131. Realtime Subscription Disposal

On:

```text
controller close
branch switch
logout
```

cancel subscriptions.

Avoid:

```text
duplicate listeners
old branch updates
memory leaks
```

---

# 132. New Order Ordering

Sort active orders:

```text
oldest first
```

for kitchen.

For management:

```text
newest first
```

may be better.

Use screen-specific sorting.

---

# 133. Order Filtering

Filters:

```text
dine-in
takeaway
delivery
payment status
table
status
```

---

# 134. Bulk Actions

Avoid early.

Bulk status changes can create mistakes.

MVP:

```text
one order at a time
```

---

# 135. Optimistic UI

For noncritical operations:

```text
sold-out toggle
```

may optimistically update and rollback on error.

For critical:

```text
refund
payment
order completion
```

prefer wait for server confirmation.

---

# 136. Menu CRUD Security

Product direct CRUD may be safe under RLS.

Examples:

```text
insert product
update product
archive product
```

Backend policy validates branch access.

---

# 137. Critical RPC Operations

Use RPC/Edge Function for:

```text
create restaurant
change owner
staff invite acceptance
rotate QR
change order status
confirm cash payment
refund
```

---

# 138. Restaurant Creation

If SaaS allows owner onboarding:

```text
Create restaurant
 ↓
RPC
 ↓
restaurant
settings
owner membership
initial branch
```

transactionally.

---

# 139. Create Restaurant Screen

Fields:

```text
restaurant name
currency
timezone
first branch
address
phone
```

---

# 140. Owner Assignment

Backend uses:

```text
auth.uid()
```

Never accept:

```text
owner_user_id
```

from Flutter as trusted.

---

# 141. Owner Transfer

Separate secure screen.

Flow:

```text
Current owner
 ↓
select target existing member
 ↓
confirm
 ↓
secure RPC
 ↓
audit
```

Potential re-auth/MFA later.

---

# 142. Audit Log

Important admin actions:

```text
price changed
product archived
order cancelled
refund requested
staff invited
staff role changed
QR rotated
tax changed
restaurant paused
```

---

# 143. Audit UI Future

Owner can view:

```text
who
what
when
entity
```

Useful for larger teams.

---

# 144. Product Price Change

Admin enters:

```text
₹249
```

Server stores:

```text
24900
```

Existing orders remain unchanged because order snapshots exist.

---

# 145. Product Deletion

Prefer:

```text
archive
```

not physical delete.

Historical orders keep references.

---

# 146. Category Deletion

If products exist:

```text
prevent delete
or
archive
```

Better UX:

```text
Move products first
```

---

# 147. Modifier Deletion

If referenced historically:

```text
archive
```

Order snapshots preserve old modifier details.

---

# 148. Search Products

For small menus:

```text
client-side
```

For large catalogs:

```text
server search
```

---

# 149. Product Pagination

Not necessary for small menu.

For very large catalogs:

```text
pagination
```

---

# 150. Menu Clone Future

Useful for multi-branch:

```text
Copy menu from Branch A
to Branch B
```

Server-side RPC.

---

# 151. Shared Menu Future

Alternative model:

```text
restaurant-level menu
branch overrides
```

More complex.

MVP branch-owned products is simpler.

---

# 152. Multi-Branch Dashboard

Owner can switch:

```text
All branches
Patna Main
Boring Road
```

All-branch aggregate requires secure restaurant-level report RPC.

---

# 153. Branch Comparison

Future:

```text
sales
orders
AOV
top items
prep time
```

---

# 154. Kitchen Performance

Derived from status history:

```text
accepted → ready
```

Metrics:

```text
average prep time
P90 prep time
late orders
```

---

# 155. Staff Performance Later

Careful use:

```text
orders handled
status actions
refund actions
```

Avoid simplistic surveillance metrics.

---

# 156. Table Management Future

Table states:

```text
free
occupied
bill requested
cleaning
reserved
```

Requires table-session model.

Not MVP.

---

# 157. Reservations Future

Admin modules:

```text
reservation list
calendar
assign table
confirm
cancel
mark seated
no-show
```

---

# 158. Loyalty Future

Admin:

```text
loyalty rules
points multiplier
reward definitions
manual adjustment with audit
```

---

# 159. CRM Future

Admin can view:

```text
customer order count
lifetime value
last order
favorite items
consent
segments
```

Respect privacy.

---

# 160. Inventory Future

Modules:

```text
ingredients
recipes
stock
purchases
waste
suppliers
```

---

# 161. Inventory Architecture

```text
Ingredient
 ↓
Recipe
 ↓
Product
```

Stock uses ledger:

```text
purchase +100
sale -5
waste -2
adjustment +1
```

---

# 162. Inventory Controller Future

Controllers:

```text
IngredientController
StockController
RecipeController
PurchaseOrderController
SupplierController
```

---

# 163. Inventory Realtime

Not all stock data needs realtime.

Use server transactions.

Refresh on relevant actions.

---

# 164. Analytics Events

Admin analytics:

```text
login
branch_switch
order_accept
order_status_change
product_create
product_update
sold_out_toggle
refund_request
qr_rotate
```

Do not log secrets.

---

# 165. Crash Reporting

Log safe context:

```text
restaurant ID
branch ID
screen
order ID
role
error code
```

Never log:

```text
password
secret key
payment secret
raw auth token
```

---

# 166. App Navigation Shell

Recommended bottom nav for owner/manager:

```text
Dashboard
Orders
Menu
More
```

Kitchen:

```text
KDS
```

Cashier:

```text
Orders
Payments
More
```

Role-aware shell.

---

# 167. More Screen

Can contain:

```text
Tables
Staff
Reports
Settings
Profile
Switch branch
Logout
```

---

# 168. Tablet Layout

KDS:

```text
landscape
multi-column
large touch targets
```

Menu admin:

```text
master-detail
```

---

# 169. Responsive Web

For web:

```text
sidebar navigation
larger tables
filters
multi-column forms
```

Same controllers/repositories can support both.

---

# 170. Accessibility

Admin users may work in stressful environments.

Use:

```text
large tap targets
clear contrast
readable text
distinct status labels
sound + visual alert
```

Do not rely only on color.

---

# 171. KDS Accessibility

Status card should include text:

```text
NEW
PREPARING
READY
```

not only card color.

---

# 172. Localization

Admin app should support:

```text
English
Hindi
Arabic
```

or target market languages.

Do not hardcode strings.

---

# 173. Currency Formatting

Central formatter:

```text
minor units
currency code
```

Avoid scattered `/100`.

---

# 174. Timezone

Reports/orders use:

```text
restaurant timezone
```

Store backend timestamps as `timestamptz`.

UI converts correctly.

---

# 175. Business Day

If restaurant business day starts at:

```text
4 AM
```

reports should use backend rule.

Do not assume midnight.

---

# 176. Search Orders

For larger order history:

```text
order number
customer
phone
table
```

Use indexed server query.

---

# 177. Privacy by Role

Kitchen should not necessarily see:

```text
customer phone
address
full payment details
```

Cashier may need payment.

Manager may need reports.

Design DTOs/views progressively.

---

# 178. Customer Data Masking

Possible:

```text
98******42
```

for roles that only need partial phone visibility.

---

# 179. Data Export Permission

Only:

```text
owner
manager
```

should generally export customer/order data.

Backend must enforce.

---

# 180. Settings Permissions

Owner:

```text
all settings
```

Manager:

```text
operational settings
```

Cashier/waiter/kitchen:

```text
minimal/no settings
```

---

# 181. Tax Settings

High-impact setting.

Consider restricting to:

```text
owner
```

or owner + manager.

Log changes.

---

# 182. Payment Settings

Restrict strongly.

Changing gateway configuration can affect money.

Require:

```text
owner
```

possibly re-auth/MFA later.

---

# 183. Refund Permission

High-impact.

Consider:

```text
owner
manager
cashier limited amount
```

Future configurable limits.

---

# 184. Refund Limit Future

Example:

```text
cashier max ₹500
manager max ₹5000
owner unlimited
```

Backend enforced.

---

# 185. Critical Action Confirmation

Require confirm for:

```text
cancel order
refund
rotate QR
deactivate branch
remove staff
change tax
archive product
```

---

# 186. Destructive UI

Use:

```text
dialog
reason
explicit CTA
```

Avoid accidental one-tap destructive actions.

---

# 187. Order Printing

Future:

```text
Bluetooth
network printer
USB
cloud printer
```

Printing is device-specific.

Do not make it part of Supabase truth.

---

# 188. KOT Printing

Possible flow:

```text
new order
 ↓
merchant device
 ↓
printer
```

or:

```text
server/local gateway
```

Depends on hardware architecture.

---

# 189. Printer Failure

Order should remain valid even if printer fails.

Show:

```text
Print failed
[Retry]
```

Do not roll back order.

---

# 190. Receipt Printing

Cashier can print:

```text
receipt
tax invoice
```

using order snapshot.

---

# 191. Local Device Settings

Store locally:

```text
selected printer
sound enabled
KDS layout
default branch if appropriate
```

Not business-critical backend data.

---

# 192. KDS Screen Lock

For dedicated tablet:

```text
prevent sleep while KDS active
```

if platform permits and user enables.

---

# 193. Notification Sound

Allow merchant-configurable local sound.

But critical new-order visual state must still appear.

---

# 194. Multiple Devices

Same branch may have:

```text
cashier phone
manager phone
KDS tablet
```

Realtime keeps them synchronized.

---

# 195. Concurrent Status Change

Two devices may act simultaneously.

Backend validates current status atomically.

Example:

```text
Device A: preparing → ready
Device B: preparing → cancelled
```

Only valid allowed transaction should succeed according to business rules.

---

# 196. Conflict UX

If action rejected because order changed:

```text
Order was updated on another device.
```

Refresh order.

---

# 197. Optimistic Status Update

For KDS, you may optimistically move card.

But on server rejection:

```text
rollback
show error
refresh
```

Safer MVP:

```text
wait for RPC response
```

---

# 198. Cached Active Orders

Can cache for fast startup.

But immediately refresh from backend.

Never treat cache as truth.

---

# 199. Persistent Branch Context

Save last selected:

```text
restaurant_id
branch_id
```

On startup:

```text
validate membership still active
```

before using.

---

# 200. App Logout

Logout should:

```text
cancel realtime
clear merchant context
clear role cache
clear sensitive local data
remove/disable push token
sign out Supabase
navigate login
```

---

# 201. Profile Screen

Admin profile:

```text
name
email
phone
role
restaurants
branches
notification settings
logout
```

---

# 202. Role Display

Show:

```text
Owner
Manager
Cashier
Waiter
Kitchen
```

but never let unauthorized user edit own role.

---

# 203. Password Reset

Use Supabase Auth supported reset flow.

Admin app should include:

```text
Forgot password
```

---

# 204. MFA Future

Recommended for:

```text
owners
high-value managers
```

especially for payment/refund/settings.

---

# 205. Security Boundary

Flutter app is untrusted.

User can modify APK/request.

Backend must reject:

```text
cross-restaurant access
cross-branch access
unauthorized role changes
fake refund
fake payment
invalid order status
price manipulation
```

---

# 206. RLS Examples by Module

Menu:

```text
authorized staff → edit own branch
others → blocked
```

Orders:

```text
authorized branch staff → read
status changes through RPC
```

Staff:

```text
owner/manager → read
owner → sensitive role changes
```

Payments:

```text
authorized read
server-controlled writes
```

---

# 207. Restaurant Context Validation

Never trust:

```text
restaurantId from MerchantContextService
```

alone.

Backend RLS checks user membership.

---

# 208. Branch Context Validation

Every branch-sensitive query must be RLS filtered.

Client filter is only performance/UX.

---

# 209. Service Role Key

Never put:

```text
service_role
secret key
```

inside admin Flutter app.

Admin app is still a client.

---

# 210. Payment Secrets

Never put gateway secret inside Flutter.

Use Edge Functions.

---

# 211. Admin Error Codes

Useful:

```text
UNAUTHORIZED
MEMBERSHIP_INACTIVE
BRANCH_ACCESS_DENIED
ORDER_NOT_FOUND
INVALID_STATUS_TRANSITION
PRODUCT_CONFLICT
PAYMENT_NOT_REFUNDABLE
REFUND_LIMIT_EXCEEDED
INVITATION_EXPIRED
QR_ROTATION_FAILED
```

---

# 212. Error Mapping

Repository maps raw error:

```text
PostgrestException
FunctionException
AuthException
```

to domain error.

Controller decides UX.

---

# 213. Network Retry

Safe to retry:

```text
read queries
idempotent RPCs
```

Be careful with:

```text
refund
role change
QR rotation
```

Backend should support idempotency where appropriate.

---

# 214. Refund Idempotency

Gateway refunds can duplicate.

Use:

```text
refund idempotency key
provider refund ID
```

server-side.

---

# 215. Staff Invite Idempotency

Avoid duplicate active invitation for same:

```text
restaurant + email/phone + role
```

unless intentionally allowed.

---

# 216. Product Save Duplicate Tap

Disable button.

Backend still handles request consistency.

---

# 217. QR Rotation Duplicate Tap

Use server operation.

If repeated, UI should not accidentally rotate many times without clear confirmation.

---

# 218. Realtime Order Repository

Possible abstraction:

```dart
Stream<List<OrderModel>>
watchActiveOrders(
  String branchId,
);
```

Controller does not know low-level channel details.

---

# 219. Order Repository

Methods:

```text
getActiveOrders
getOrder
watchActiveOrders
changeStatus
cancelOrder
getHistory
confirmCashPayment
```

---

# 220. Menu Repository

Methods:

```text
getCategories
createCategory
updateCategory
archiveCategory
getProducts
createProduct
updateProduct
setAvailability
assignModifierGroups
```

---

# 221. Table Repository

Methods:

```text
getTables
createTable
updateTable
deactivateTable
rotateQr
```

---

# 222. Staff Repository

Methods:

```text
getMembers
getInvitations
invite
updateRole
updateBranches
deactivate
```

---

# 223. Payment Repository

Methods:

```text
getPayments
getPayment
confirmCash
requestRefund
getRefunds
```

---

# 224. Reports Repository

Methods:

```text
getDashboardSummary
getSalesSummary
getProductSales
getPaymentBreakdown
getOrderStatusSummary
```

---

# 225. Settings Repository

Methods:

```text
getRestaurantSettings
updateRestaurantSettings
getBranchSettings
updateBranchSettings
getOpeningHours
updateOpeningHours
```

---

# 226. Form Validation

Admin forms validate:

```text
required fields
money format
phone format
opening hours
modifier min/max
capacity
role selection
```

Backend revalidates.

---

# 227. Dirty Form Handling

If user edits product then navigates back:

```text
Discard changes?
```

Avoid accidental loss.

---

# 228. Autosave

Avoid autosaving critical forms initially.

Explicit:

```text
Save
```

is safer.

---

# 229. Image Upload Progress

Show:

```text
Uploading...
```

Do not block all app.

Retry upload independently.

---

# 230. Menu Bulk Import Future

CSV import:

```text
categories
products
prices
```

Should be server-validated.

---

# 231. Menu Export Future

Export:

```text
CSV
```

for backup/editing.

---

# 232. Duplicate Product Future

Useful:

```text
Duplicate
```

copies:

```text
name
description
price
modifiers
```

with new ID.

---

# 233. Multi-Branch Product Sync Future

Owner can:

```text
push price/menu update
to selected branches
```

Requires carefully designed server operations.

---

# 234. Price Override Future

Possible model:

```text
base restaurant product
branch-specific price
```

More complex than MVP.

---

# 235. Notification Center

Admin app can show:

```text
new order
payment issue
refund
system alert
staff invite
```

---

# 236. Notification Read State

Future table:

```text
notifications
notification_reads
```

Not required for push-only MVP.

---

# 237. KDS Fullscreen Mode

Offer:

```text
Enter KDS Mode
```

hides navigation.

For dedicated tablet.

---

# 238. KDS Exit

Protected optionally by:

```text
PIN
```

for staff terminals.

---

# 239. Staff PIN Future

Fast terminal access:

```text
employee PIN
```

requires separate security model.

Do not confuse with Supabase Auth password.

---

# 240. Device Registration Future

Dedicated POS/KDS devices could be registered.

Tables:

```text
merchant_devices
device_sessions
```

Useful for trusted hardware policies.

---

# 241. App Analytics

Track:

```text
admin_login
restaurant_selected
branch_selected
dashboard_view
order_accept
order_ready
product_created
sold_out_toggle
staff_invited
refund_requested
```

---

# 242. Privacy

Do not send customer PII to analytics unnecessarily.

Use IDs and aggregate events.

---

# 243. Testing Strategy

Admin app needs:

```text
unit
widget
integration
security
realtime
payment
role testing
```

---

# 244. Unit Tests

Test:

```text
permission helper
money formatting
status action mapping
menu form validation
modifier validation
date filters
controller state
```

---

# 245. Repository Tests

Test:

```text
orders fetch
realtime mapping
product CRUD
staff invite
refund function
settings updates
```

---

# 246. Controller Tests

Test:

```text
login
branch switch
new order event
status change
sold-out toggle
refund state
role-based action visibility
```

---

# 247. Widget Tests

Test:

```text
dashboard cards
live order card
KDS card
product form
staff list
permission denied UI
empty states
```

---

# 248. Integration Tests

Critical:

```text
Login → Select Restaurant → Branch → Dashboard
Order appears → Accept → Preparing → Ready
Create Product → Customer menu sees product
Mark sold out → Customer cannot order
Create Table → QR resolves
Invite Staff → Staff gains correct access
```

---

# 249. Role Security Tests

Owner:

```text
full allowed actions
```

Manager:

```text
allowed operational actions
restricted owner-only actions
```

Cashier:

```text
orders/payments
no staff ownership change
```

Kitchen:

```text
KDS only
no payment/menu/staff access
```

Waiter:

```text
dine-in order actions
restricted settings
```

---

# 250. Cross-Tenant Tests

Restaurant A user attempts:

```text
Restaurant B orders
Restaurant B products
Restaurant B payments
Restaurant B staff
Restaurant B tables
```

All must fail server-side.

---

# 251. Realtime Tests

```text
new order appears
other branch does not receive
status syncs on multiple devices
branch switch cleans old subscription
reconnect refetch works
logout stops subscription
```

---

# 252. Payment Tests

```text
cash confirm
online paid
failed
partial refund
full refund
unauthorized refund
duplicate refund request
```

---

# 253. Menu Tests

```text
create category
archive category
create product
edit price
sold out
modifier required
image upload
branch isolation
```

---

# 254. Table Tests

```text
create
edit
deactivate
QR resolve
rotate QR
old QR invalid
```

---

# 255. Staff Tests

```text
invite
expired invitation
role change
branch assignment
deactivate
owner transfer protection
```

---

# 256. Offline Tests

```text
live orders disconnect
status button offline
reconnect refresh
cached dashboard
branch switch offline
```

---

# 257. Device Tests

At minimum:

```text
Android phone
Android tablet
iPhone
iPad if supported
Web desktop
Web tablet
```

KDS should specifically be tested on real tablet.

---

# 258. Performance Tests

Test:

```text
100 active orders
500 products
large order history
multiple realtime devices
dashboard date queries
```

---

# 259. Admin MVP Screen List

Required:

```text
SplashPage
LoginPage
RestaurantSelectPage
BranchSelectPage
DashboardPage
LiveOrdersPage
OrderDetailPage
KdsPage
CategoryListPage
ProductListPage
ProductFormPage
ModifierListPage
TableListPage
TableDetailPage
StaffListPage
PaymentListPage
ReportsPage
SettingsPage
ProfilePage
```

---

# 260. Optional MVP Screens

Useful:

```text
QrPreviewPage
PaymentDetailPage
RefundDialog/Page
OpeningHoursPage
NotificationSettingsPage
```

---

# 261. Phase 2 Screens

```text
CouponManagementPage
CustomerListPage
LoyaltySettingsPage
AdvancedReportsPage
AuditLogPage
```

---

# 262. Phase 3 Screens

```text
InventoryDashboard
IngredientList
RecipeBuilder
StockMovement
SupplierList
PurchaseOrders
Reservations
DeliveryManagement
```

---

# 263. Implementation Order

Build admin app in this order:

```text
1. Flutter project setup
2. Supabase initialization
3. GetX routing
4. AdminSessionService
5. Login
6. Membership loading
7. Restaurant selection
8. Branch selection
9. MerchantContextService
10. Dashboard shell
11. Menu categories
12. Products
13. Modifiers
14. Product images
15. Tables
16. QR generation
17. Live orders
18. Realtime
19. Order detail
20. Status RPC
21. KDS
22. Order history
23. Payments
24. Cash confirmation
25. Staff
26. Settings
27. Reports
28. Push notifications
29. Refunds
30. QA/security hardening
```

---

# 264. First Admin Milestone

First working merchant flow:

```text
Login
 ↓
Select restaurant
 ↓
Select branch
 ↓
Create category
 ↓
Create product
 ↓
Create table
 ↓
Generate QR
 ↓
Customer orders
 ↓
Order appears live
 ↓
Accept
 ↓
Preparing
 ↓
Ready
 ↓
Complete
```

This is the core operational loop.

---

# 265. Second Milestone

Add:

```text
online payments
cash payment confirmation
staff roles
dashboard
order history
push
```

---

# 266. Third Milestone

Add:

```text
reports
refunds
multi-branch
opening hours
pause ordering
coupons
```

---

# 267. Fourth Milestone

Add:

```text
inventory
CRM
loyalty
reservations
delivery
```

---

# 268. Full Admin Flow Diagram

```text
                         APP OPEN
                            │
                            ▼
                          SPLASH
                            │
                     Session exists?
                       │          │
                      NO         YES
                       │          │
                       ▼          ▼
                     LOGIN    MEMBERSHIPS
                                  │
                        Restaurant count?
                         │              │
                        ONE           MANY
                         │              │
                         ▼              ▼
                    SELECT AUTO   RESTAURANT SELECT
                         │              │
                         └───────┬──────┘
                                 ▼
                           BRANCH ACCESS
                                 │
                         Branch count?
                           │          │
                          ONE        MANY
                           │          │
                           ▼          ▼
                        AUTO      BRANCH SELECT
                           │          │
                           └────┬─────┘
                                ▼
                             DASHBOARD
                                │
        ┌───────────────────────┼────────────────────────┐
        │                       │                        │
        ▼                       ▼                        ▼
   LIVE ORDERS                 MENU                    MORE
        │                       │                        │
        ▼                       ├─ Categories            ├─ Tables
   ORDER DETAIL                ├─ Products              ├─ Staff
        │                       ├─ Modifiers             ├─ Payments
        ▼                       └─ Availability          ├─ Reports
  STATUS ACTION                                          └─ Settings
        │
        ▼
       KDS
        │
        ▼
   COMPLETED ORDER
```

---

# 269. Operational Order Flow

```text
CUSTOMER ORDER
      │
      ▼
   DATABASE
      │
      ▼
   REALTIME
      │
      ▼
 MERCHANT APP
      │
      ▼
    PLACED
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

Every transition:

```text
Flutter button
 ↓
RPC
 ↓
permission check
 ↓
transition validation
 ↓
database update
 ↓
status history
 ↓
Realtime
```

---

# 270. Menu Management Flow

```text
Merchant
 ↓
Menu
 ↓
Category
 ↓
Product
 ↓
Modifier Groups
 ↓
Modifiers
 ↓
Save
 ↓
Supabase + RLS
 ↓
Customer menu
```

---

# 271. Table QR Flow

```text
Merchant creates table
 ↓
Supabase generates qr_token
 ↓
Admin app builds QR
 ↓
Print/share
 ↓
Customer scans
 ↓
resolve_qr
 ↓
restaurant + branch + table
```

---

# 272. Staff Flow

```text
Owner
 ↓
Invite staff
 ↓
Role
 ↓
Branch assignment
 ↓
Invitation
 ↓
Staff login
 ↓
Accept
 ↓
restaurant_members
 ↓
branch_members
 ↓
role-aware app
```

---

# 273. Payment Admin Flow

```text
ORDER
 ↓
PAYMENT
 ↓
cash or online

Cash:
cashier confirms
 ↓
RPC
 ↓
paid

Online:
provider webhook
 ↓
Edge Function
 ↓
paid

Refund:
authorized admin
 ↓
Edge Function
 ↓
provider
 ↓
refund record
```

---

# 274. Data Ownership

Backend truth:

```text
membership
role
branch access
order state
payment state
refund state
menu ownership
tax/settings
staff access
```

Flutter state:

```text
selected branch
selected filter
screen state
form input
loading state
temporary search
KDS layout
```

---

# 275. Security Checklist

```text
[ ] no secret/service role key in app
[ ] no payment secret
[ ] restaurant membership checked server-side
[ ] branch access checked server-side
[ ] role changes protected
[ ] owner transfer protected
[ ] order status protected by RPC
[ ] payments not directly writable
[ ] refunds server-side
[ ] QR rotation protected
[ ] menu writes RLS protected
[ ] staff list protected
[ ] reports tenant filtered
[ ] storage paths tenant protected
[ ] realtime isolation tested
```

---

# 276. Dashboard Checklist

```text
[ ] current restaurant visible
[ ] current branch visible
[ ] switch branch available
[ ] today sales
[ ] today orders
[ ] active orders
[ ] status counts
[ ] refresh
[ ] role-aware cards
```

---

# 277. Live Orders Checklist

```text
[ ] initial fetch
[ ] realtime
[ ] reconnect
[ ] new order sound
[ ] order type
[ ] table
[ ] elapsed time
[ ] total
[ ] legal actions
[ ] filter
[ ] no cross-branch data
```

---

# 278. KDS Checklist

```text
[ ] large touch targets
[ ] full-screen mode
[ ] active statuses only
[ ] order age
[ ] modifiers visible
[ ] notes visible
[ ] sound
[ ] realtime
[ ] reconnect
[ ] status actions
```

---

# 279. Menu Checklist

```text
[ ] category CRUD
[ ] product CRUD
[ ] image upload
[ ] price minor units
[ ] sold-out toggle
[ ] modifiers
[ ] archive
[ ] branch isolation
[ ] customer refresh
```

---

# 280. Table Checklist

```text
[ ] create table
[ ] edit
[ ] area
[ ] capacity
[ ] active toggle
[ ] QR preview
[ ] share/print
[ ] rotate QR
[ ] old QR invalid
```

---

# 281. Staff Checklist

```text
[ ] invite
[ ] role
[ ] branch assignment
[ ] deactivate
[ ] owner-only controls
[ ] expired invite
[ ] audit
[ ] cross-tenant block
```

---

# 282. Payment Checklist

```text
[ ] list
[ ] filter
[ ] cash confirm
[ ] online status
[ ] refund permission
[ ] refund reason
[ ] provider error handling
[ ] no client-side secret
```

---

# 283. Reports Checklist

```text
[ ] date range
[ ] branch
[ ] sales semantics clear
[ ] paid revenue
[ ] refund total
[ ] top products
[ ] order count
[ ] export later
```

---

# 284. Production Checklist

```text
[ ] auth works
[ ] membership refresh works
[ ] last branch context validated
[ ] branch switching cleans subscriptions
[ ] realtime reconnect works
[ ] KDS handles 100+ active orders
[ ] status RPC handles concurrent updates
[ ] product CRUD RLS works
[ ] storage policies tested
[ ] QR rotate works
[ ] staff access tested
[ ] refund permission tested
[ ] payment secrets server-side
[ ] notification deep links work
[ ] logout cleans data
[ ] cross-tenant tests pass
[ ] tablet layout tested
[ ] web layout tested
```

---

# 285. Suggested Companion Files

Create next:

```text
ADMIN_APP_FOLDER_STRUCTURE.md
ADMIN_APP_MODELS.md
ADMIN_APP_GETX_CONTROLLERS.md
ADMIN_APP_REPOSITORIES.md
ADMIN_APP_KDS_FLOW.md
ADMIN_APP_ORDER_FLOW.md
ADMIN_APP_MENU_MANAGEMENT.md
ADMIN_APP_STAFF_PERMISSIONS.md
ADMIN_APP_PAYMENT_FLOW.md
ADMIN_APP_UI_SCREEN_SPEC.md
ADMIN_APP_TEST_PLAN.md
ADMIN_APP_TASK_LIST.md
```

---

# 286. Final Recommendation

Implement the admin app in this priority:

```text
AUTH
 ↓
MEMBERSHIP
 ↓
RESTAURANT CONTEXT
 ↓
BRANCH CONTEXT
 ↓
MENU MANAGEMENT
 ↓
TABLES + QR
 ↓
LIVE ORDERS
 ↓
ORDER STATUS RPC
 ↓
KDS
 ↓
PAYMENTS
 ↓
STAFF
 ↓
DASHBOARD
 ↓
REPORTS
 ↓
SETTINGS
 ↓
REFUNDS
 ↓
INVENTORY / CRM / RESERVATIONS
```

The admin experience should feel operationally simple:

```text
See
Act
Confirm
Track
```

while the backend strictly performs:

```text
authentication
membership validation
branch authorization
role authorization
order transition validation
payment verification
refund control
RLS tenant isolation
Realtime synchronization
audit logging
```

That separation is what makes the merchant application both **easy for restaurant staff** and **safe for a multi-tenant SaaS product**.
