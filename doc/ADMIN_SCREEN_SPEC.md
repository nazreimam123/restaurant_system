# ADMIN_SCREEN_SPEC.md
## QR Restaurant Ordering Platform
### Admin / Merchant App — Screen-by-Screen Implementation Contract
### Flutter + GetX + MVC + Supabase
### For Codex, Cursor, Claude Code, Copilot, and Other AI Coding Tools

> This document is the **authoritative screen specification for the Admin/Merchant application**.
>
> It is intended for AI coding tools and human developers implementing the merchant app.
>
> Use this document together with:
>
> - `ADMIN_APP_FLOW.md`
> - `APP_DESIGN_SYSTEM_AND_UI_SPEC.md`
> - `MVP_TASK_LIST.md`
> - `Supabase_Backend_Specification_QR_Restaurant_Project.md`
>
> AI tools must not invent routes, role behavior, screen states, visual hierarchy, or backend contracts that conflict with these files.
>
> This document defines:
>
> - screen purpose
> - route
> - role visibility
> - binding
> - controller
> - repositories/services
> - UI sections
> - realtime behavior
> - user actions
> - permissions
> - loading/empty/error states
> - backend dependencies
> - responsive behavior
> - analytics
> - accessibility
> - acceptance criteria
>
> The admin app should feel operationally simple:
>
> ```text
> See
> → Act
> → Confirm
> → Track
> ```

---

# 1. Global Admin Screen Rules

Every admin screen must:

- [ ] use shared design tokens
- [ ] use GetX routes and bindings
- [ ] avoid direct Supabase calls in Views
- [ ] respect current restaurant/branch context
- [ ] expose role-aware actions
- [ ] show loading/error/empty states where relevant
- [ ] support mobile
- [ ] support tablet
- [ ] support desktop/web where relevant
- [ ] use semantic status chips
- [ ] use centralized money formatting
- [ ] use centralized date formatting
- [ ] use backend permission checks as authority
- [ ] use responsive layouts
- [ ] provide clear destructive-action confirmations
- [ ] use accessible labels/tooltips
- [ ] dispose Realtime subscriptions correctly

---

# 2. Admin Route Inventory

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
/categories/new
/categories/:id/edit
/products
/products/new
/products/:id/edit
/modifiers
/modifiers/new
/modifiers/:id/edit
/tables
/tables/new
/tables/:id
/tables/:id/qr
/staff
/staff/invite
/payments
/payments/:id
/reports
/settings
/settings/restaurant
/settings/branch
/settings/opening-hours
/profile
```

Optional future:

```text
/refunds
/audit
/coupons
/inventory
/reservations
/customers
/loyalty
```

---

# 3. Role Visibility Summary

## Owner

Access:

```text
Dashboard
Orders
KDS
Menu
Tables
Staff
Payments
Reports
Settings
Profile
```

## Manager

Access:

```text
Dashboard
Orders
KDS
Menu
Tables
Staff limited
Payments
Reports
Operational Settings
Profile
```

## Cashier

Access:

```text
Orders
Payments
Limited Dashboard
Profile
```

## Waiter

Access:

```text
Orders
Tables
Limited Dashboard
Profile
```

## Kitchen

Access:

```text
KDS
Limited Order Detail
Profile
```

UI role visibility is UX only.

Backend RLS/RPC remains authority.

---

# 4. Shared Admin Components

Reuse:

```text
AdminPageScaffold
AdminPageHeader
BranchSelector
RestaurantSelector
MetricCard
StatusChip
OrderCard
KdsOrderCard
ProductListTile
AvailabilityToggle
CategoryListTile
StaffListTile
PaymentListTile
ReportSummaryCard
SettingsSection
DangerZoneCard
AppPrimaryButton
AppSecondaryButton
AppDangerButton
AppTextField
AppSearchField
AppDropdownField
AppEmptyState
AppErrorState
AppLoadingSkeleton
AppConfirmationDialog
```

---

# 5. Shared Admin Services

```text
AdminSessionService
MerchantContextService
ConnectivityService
RealtimeService
NotificationService
AppLifecycleService
PermissionService
AnalyticsService
```

---

# 6. Shared Admin Repositories

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

# 7. SplashPage

## Route

```text
/splash
```

## Purpose

Initialize session and determine correct admin destination.

## Controller

```text
AdminStartupController
```

## Dependencies

```text
AdminSessionService
MerchantRepository
BranchRepository
MerchantContextService
NotificationService
```

## Responsibilities

1. restore Supabase session
2. validate current user
3. load restaurant memberships
4. restore last restaurant context
5. validate branch access
6. process pending notification deep link
7. route user

## Navigation

No session:

```text
→ LoginPage
```

One restaurant + one branch:

```text
→ DashboardPage
```

Multiple restaurants:

```text
→ RestaurantSelectPage
```

Multiple branches:

```text
→ BranchSelectPage
```

Kitchen role with valid context:

```text
→ KdsPage
```

Cashier:

```text
→ LiveOrdersPage
```

## UI

Minimal:

```text
logo
app name
progress
```

## Error

Fallback:

```text
Couldn't start the app.

[Try Again]
[Sign Out]
```

## Acceptance Criteria

- [ ] session restored
- [ ] stale context rejected
- [ ] role-specific destination works
- [ ] membership removal is handled
- [ ] no startup loop

---

# 8. LoginPage

## Route

```text
/login
```

## Purpose

Authenticate merchant/staff user.

## Controller

```text
AdminAuthController
```

## Dependencies

```text
AuthRepository
AdminSessionService
AnalyticsService
```

## UI

Mobile:

```text
Logo
Welcome back
Email
Password
Sign In
Forgot Password
```

Desktop/tablet:

```text
optional brand panel
login card max width 420
```

## Actions

```text
sign in
forgot password
```

## Validation

```text
email valid
password required
```

## Errors

```text
invalid credentials
account disabled
network error
too many attempts
```

## Success

```text
load memberships
→ RestaurantSelect / BranchSelect / Dashboard
```

## Acceptance Criteria

- [ ] validation works
- [ ] loading button works
- [ ] raw auth errors are mapped
- [ ] session created
- [ ] next route correct

---

# 9. RestaurantSelectPage

## Route

```text
/select-restaurant
```

## Purpose

Choose active restaurant membership.

## Controller

```text
RestaurantSelectController
```

## Dependencies

```text
MerchantRepository
MerchantContextService
```

## UI

List/grid of restaurants:

```text
Restaurant Name
Role
Branch Count
Status
[Open]
```

## Empty State

```text
You don't have access to any restaurants.

Contact your administrator.
```

## Actions

```text
select restaurant
refresh memberships
logout
```

## Success

Save context.

Then:

```text
one accessible branch
→ branch auto-select

multiple
→ BranchSelectPage
```

## Acceptance Criteria

- [ ] only authorized restaurants shown
- [ ] role displayed
- [ ] inactive membership hidden
- [ ] context updated safely

---

# 10. BranchSelectPage

## Route

```text
/select-branch
```

## Purpose

Choose operational branch.

## Controller

```text
BranchSelectController
```

## Dependencies

```text
BranchRepository
MerchantContextService
```

## UI

Cards:

```text
Branch Name
Address
Active/Inactive
```

## Role Behavior

Owner/manager:

```text
all authorized branches
```

Assigned staff:

```text
only branch_members branches
```

## Actions

```text
select branch
switch restaurant
```

## Success

Save branch context.

Navigate based on role:

```text
owner/manager → Dashboard
cashier → Orders
waiter → Orders
kitchen → KDS
```

## Acceptance Criteria

- [ ] inaccessible branches never shown
- [ ] context persisted
- [ ] branch switching clears old realtime listeners

---

# 11. DashboardPage

## Route

```text
/dashboard
```

## Roles

```text
Owner
Manager
Cashier limited
Waiter limited
```

Kitchen usually does not need full dashboard.

## Controller

```text
DashboardController
```

## Dependencies

```text
DashboardRepository
MerchantContextService
PermissionService
AnalyticsService
```

## Required UI

```text
AdminPageHeader
Date Filter
Metric Cards
Order Status Summary
Top Products
Payment Summary
Recent Orders optional
```

## Header

Show:

```text
restaurant
branch selector
date context
```

## Metrics

MVP:

```text
Today's Sales
Orders
Average Order Value
Active Orders
```

## Role-Aware Metrics

Cashier:

```text
orders
pending payments
cash summary
```

Waiter:

```text
active dine-in
ready orders
```

## Loading

Metric skeleton cards.

## Empty

```text
No activity for this period.
```

## Error

Inline retry.

## Actions

```text
change date range
switch branch
open active orders
open reports
```

## Acceptance Criteria

- [ ] branch context visible
- [ ] date filter works
- [ ] data from backend summary RPC
- [ ] role-aware content
- [ ] no huge client aggregation

---

# 12. LiveOrdersPage

## Route

```text
/orders
```

## Roles

```text
Owner
Manager
Cashier
Waiter
Kitchen limited via KDS preferred
```

## Controller

```text
LiveOrdersController
```

## Dependencies

```text
OrderRepository
MerchantContextService
RealtimeService
ConnectivityService
AnalyticsService
```

## UI

Mobile:

```text
Tabs
New
Preparing
Ready
All
```

Tablet/Desktop:

```text
status columns
or
master-detail
```

## Order Card

Show:

```text
Order #1042
Table / Takeaway
Elapsed Time
Item Summary
Total
Status
Primary Action
```

## Initial Behavior

```text
fetch active orders
subscribe realtime
```

## Realtime

New order:

```text
insert into list
play sound
optional vibration
```

## Filters

```text
status
order type
table
payment
```

## Offline

Banner:

```text
Live updates disconnected.
```

Critical actions disabled.

## Acceptance Criteria

- [ ] initial fetch
- [ ] realtime insert/update
- [ ] branch isolation
- [ ] no duplicate order cards
- [ ] reconnect refetch
- [ ] role actions correct

---

# 13. OrderDetailPage

## Route

```text
/orders/:id
```

## Roles

All roles with access, but data/actions vary.

## Controller

```text
OrderDetailController
```

## Dependencies

```text
OrderRepository
PaymentRepository
PermissionService
AnalyticsService
```

## Required UI

```text
Order Header
Status
Order Type
Table
Customer Info if allowed
Items
Modifiers
Notes
Price Summary
Payment
Status History
Action Bar
```

## Customer Data Visibility

Kitchen:

```text
hide phone/payment detail
```

Cashier:

```text
payment visible
```

Owner/manager:

```text
full operational detail
```

## Action Bar

Possible:

```text
Accept
Start Preparing
Mark Ready
Mark Served
Complete
Cancel
Confirm Cash
Refund
```

Only show actions that are:

```text
role-permitted
+
state-legal
```

## Status Change

Call:

```text
change_order_status RPC
```

## Conflict

If another device updates first:

```text
Order was updated on another device.
Refreshing...
```

## Cancellation

Require reason and confirmation.

## Acceptance Criteria

- [ ] snapshots displayed
- [ ] status history displayed
- [ ] role-based customer/payment visibility
- [ ] legal actions only
- [ ] server conflict handled

---

# 14. KdsPage

## Route

```text
/kds
```

## Roles

```text
Kitchen
Manager
Owner
```

Optional cashier access only if configured.

## Controller

```text
KdsController
```

## Dependencies

```text
OrderRepository
RealtimeService
MerchantContextService
ConnectivityService
AnalyticsService
```

## Layout

Tablet/Desktop:

```text
NEW | PREPARING | READY
```

Mobile:

```text
tabbed columns
```

## KDS Card

Show:

```text
Order Number
Table/Order Type
Elapsed Time
Items
Modifiers
Item Notes
Order Notes
Next Action
```

Do not show:

```text
full payment metadata
customer profile
reports
```

## Actions

```text
Accept / Start
Mark Ready
```

Depending on workflow.

## Timer

Calculated locally from timestamps.

## Realtime

Required.

## Connection Indicator

```text
Live
Reconnecting
Offline
```

## Fullscreen

Support dedicated KDS mode.

## Acceptance Criteria

- [ ] readable from distance
- [ ] large touch actions
- [ ] realtime works
- [ ] reconnect refetch works
- [ ] status update RPC used
- [ ] no duplicate sound alert

---

# 15. CategoryListPage

## Route

```text
/categories
```

## Roles

```text
Owner
Manager
```

## Controller

```text
CategoryController
```

## Dependencies

```text
MenuRepository
MerchantContextService
PermissionService
```

## UI

```text
Page Header
Search optional
Category List
Add Category CTA
```

List row:

```text
Name
Active
Sort Order optional
More Menu
```

## Actions

```text
add
edit
activate/deactivate
reorder
```

## Empty

```text
No categories yet.
[Add Category]
```

## Acceptance Criteria

- [ ] branch-scoped categories
- [ ] reorder persists
- [ ] archive/deactivate works
- [ ] unauthorized roles blocked

---

# 16. CategoryFormPage

## Routes

```text
/categories/new
/categories/:id/edit
```

## Controller

```text
CategoryFormController
```

## UI

Fields:

```text
Name
Description optional
Image optional
Active toggle
```

## Actions

```text
Save
Cancel
```

## Validation

```text
name required
```

## Acceptance Criteria

- [ ] create works
- [ ] edit works
- [ ] loading state
- [ ] validation
- [ ] dirty-form warning

---

# 17. ProductListPage

## Route

```text
/products
```

## Roles

```text
Owner
Manager
```

## Controller

```text
ProductController
```

## Dependencies

```text
MenuRepository
MerchantContextService
PermissionService
```

## UI

```text
Page Header
Search
Category Filter
Availability Filter
Product List/Grid
Add Product CTA
```

Product row/card:

```text
thumbnail
name
category
price
availability
archive state
more menu
```

## Quick Action

```text
Available / Sold Out
```

## Empty

```text
No products yet.
[Add Product]
```

## Acceptance Criteria

- [ ] branch filter
- [ ] search
- [ ] sold-out toggle
- [ ] edit navigation
- [ ] responsive list/grid

---

# 18. ProductFormPage

## Routes

```text
/products/new
/products/:id/edit
```

## Controller

```text
ProductFormController
```

## Dependencies

```text
MenuRepository
ModifierRepository
Storage service/repository
MerchantContextService
```

## Form Sections

```text
Basic Info
Category
Pricing
Image
Availability
Modifier Groups
```

## Fields

```text
name
description
category
base price
image
veg/non-veg optional
available
active/archive
sort order optional
modifier groups
```

## Price

Merchant enters decimal display value.

Convert to integer minor units.

## Image

Upload/replace/remove.

## Validation

```text
name required
category required
price >= 0
valid modifier assignments
```

## Save

Direct RLS CRUD or repository operation.

## Acceptance Criteria

- [ ] create
- [ ] update
- [ ] image upload
- [ ] money conversion
- [ ] modifier assignment
- [ ] dirty form handling
- [ ] success feedback

---

# 19. ModifierGroupListPage

## Route

```text
/modifiers
```

## Roles

```text
Owner
Manager
```

## Controller

```text
ModifierController
```

## UI

Cards:

```text
Size
Required
Select 1

Extras
Optional
Up to 4
```

Show options count.

## Actions

```text
add
edit
deactivate
```

## Empty

```text
No modifier groups yet.
[Add Modifier Group]
```

---

# 20. ModifierGroupFormPage

## Routes

```text
/modifiers/new
/modifiers/:id/edit
```

## Controller

```text
ModifierFormController
```

## Fields

```text
group name
required
min_select
max_select
options
```

Each option:

```text
name
price delta
availability
sort order
```

## Validation

```text
max >= min
required should usually imply min >= 1
option name required
```

## Acceptance Criteria

- [ ] group save
- [ ] option CRUD
- [ ] price delta minor units
- [ ] validation
- [ ] reuse across products

---

# 21. TableListPage

## Route

```text
/tables
```

## Roles

```text
Owner
Manager
Waiter read-only/limited optional
```

## Controller

```text
TableController
```

## Dependencies

```text
TableRepository
MerchantContextService
PermissionService
```

## UI

Mobile:

```text
table list
```

Tablet/Desktop:

```text
grid
```

Table card:

```text
Table Name
Area
Capacity
Active
QR shortcut
```

## Actions

```text
add
edit
activate/deactivate
view QR
rotate QR
```

## Acceptance Criteria

- [ ] branch-scoped tables
- [ ] active/inactive state
- [ ] QR navigation
- [ ] role behavior correct

---

# 22. TableFormPage

## Routes

```text
/tables/new
/tables/:id
```

## Controller

```text
TableFormController
```

## Fields

```text
name
capacity
area optional
active
```

## Save

Backend generates QR token on create.

## Validation

```text
name required
capacity positive if provided
```

---

# 23. QrPreviewPage

## Route

```text
/tables/:id/qr
```

## Roles

```text
Owner
Manager
```

## Controller

```text
QrController
```

## Dependencies

```text
TableRepository
MerchantContextService
```

## UI

```text
Restaurant Name/Logo
Table Name
Large QR
Scan to Order
```

Actions:

```text
Share
Save
Print later
Rotate QR
```

## Rotate QR

Confirmation:

```text
Old printed QR codes will stop working.

[Cancel]
[Rotate QR]
```

Call:

```text
rotate_table_qr RPC
```

## Acceptance Criteria

- [ ] QR encodes correct resolver URL
- [ ] share works
- [ ] rotation invalidates old QR
- [ ] action audited

---

# 24. StaffListPage

## Route

```text
/staff
```

## Roles

```text
Owner
Manager limited
```

## Controller

```text
StaffController
```

## Dependencies

```text
StaffRepository
MerchantContextService
PermissionService
```

## UI

```text
Search
Role Filter
Staff List
Invite Staff CTA
```

Staff row:

```text
name/email/phone
role
branches
active/inactive
more menu
```

## Actions

```text
invite
change role
assign branches
deactivate
remove if policy permits
```

## Restrictions

Manager must not promote self/others to owner unless backend allows.

## Acceptance Criteria

- [ ] authorized members only
- [ ] branch assignment visible
- [ ] role restrictions
- [ ] deactivation works
- [ ] audit actions

---

# 25. StaffInvitePage

## Route

```text
/staff/invite
```

## Controller

```text
StaffInviteController
```

## Fields

```text
email or phone
role
branch assignments
```

## Actions

```text
Send Invite
```

## Validation

```text
contact required
role required
branches required for restricted roles
```

## Success

```text
Invitation sent.
```

## Errors

```text
already invited
already member
invalid contact
permission denied
```

---

# 26. PaymentListPage

## Route

```text
/payments
```

## Roles

```text
Owner
Manager
Cashier
```

## Controller

```text
PaymentsController
```

## Dependencies

```text
PaymentRepository
MerchantContextService
PermissionService
```

## UI

Filters:

```text
All
Paid
Pending
Failed
Refunded
Cash
Online
```

Rows/cards:

```text
Order #1042
Amount
Method
Status
Time
```

## Actions

```text
open detail
confirm cash where relevant
```

## Acceptance Criteria

- [ ] payment status correct
- [ ] pagination/filtering
- [ ] branch isolation
- [ ] no secret provider data exposed

---

# 27. PaymentDetailPage

## Route

```text
/payments/:id
```

## Controller

```text
PaymentDetailController
```

## UI

Sections:

```text
Payment Summary
Order
Provider Reference
Cash Confirmation
Refunds
```

## Cash Payment

If pending cash:

```text
[Mark Cash Received]
```

Call controlled RPC.

## Refund

If role permits:

```text
[Refund]
```

opens refund dialog/flow.

## Acceptance Criteria

- [ ] status reflected from backend
- [ ] cash confirmation safe
- [ ] refund permission checked
- [ ] provider IDs copyable where safe

---

# 28. Refund Dialog / Screen

## Priority

P1 if refunds are MVP.

## Controller

Could use:

```text
PaymentDetailController
```

or dedicated:

```text
RefundController
```

## Fields

```text
amount
reason
```

## Confirmation

```text
This action may send money back to the customer.

[Cancel]
[Confirm Refund]
```

## Backend

Edge Function.

## Acceptance Criteria

- [ ] amount validated
- [ ] role validated server-side
- [ ] duplicate submission blocked
- [ ] result shown clearly

---

# 29. ReportsPage

## Route

```text
/reports
```

## Roles

```text
Owner
Manager
```

## Controller

```text
ReportsController
```

## Dependencies

```text
ReportRepository
MerchantContextService
```

## UI

```text
Date Filter
Summary Metrics
Top Products
Payment Breakdown
Cancelled Orders
Simple Charts optional
```

## Metrics

```text
Gross Order Value
Paid Revenue
Refunds
Net Revenue
Orders
Average Order Value
```

## Date Filters

```text
Today
Yesterday
7 Days
30 Days
Custom
```

## Acceptance Criteria

- [ ] backend aggregates
- [ ] branch/date filters
- [ ] report semantics clear
- [ ] no giant client-side aggregation

---

# 30. SettingsPage

## Route

```text
/settings
```

## Roles

```text
Owner
Manager limited
```

## Purpose

Entry point for settings.

## UI Groups

```text
Restaurant
Branch
Ordering
Payments
Tax & Charges
Opening Hours
Notifications
Staff
```

Owner-only items clearly restricted.

---

# 31. RestaurantSettingsPage

## Route

```text
/settings/restaurant
```

## Roles

```text
Owner
Manager limited
```

## Controller

```text
SettingsController
```

## Fields

```text
restaurant name
logo
currency
timezone
guest ordering
```

## Sensitive Settings

Currency/timezone changes may have business implications.

Require confirmation if changing after live use.

---

# 32. BranchSettingsPage

## Route

```text
/settings/branch
```

## Fields

```text
branch name
phone
address
order types
pause orders
```

## Pause Ordering

Persistent warning when active.

Actions:

```text
Pause Orders
Resume Orders
```

---

# 33. OpeningHoursPage

## Route

```text
/settings/opening-hours
```

## Controller

```text
OpeningHoursController
```

## UI

For each weekday:

```text
Open/Closed
Opening Time
Closing Time
```

## Validation

```text
close > open
```

unless overnight support implemented.

## Acceptance Criteria

- [ ] all weekdays editable
- [ ] closed state works
- [ ] backend saves branch-specific schedule

---

# 34. ProfilePage

## Route

```text
/profile
```

## Controller

```text
ProfileController
```

## UI

```text
name
email
phone
role
current restaurant
current branch
notification settings
logout
```

## Actions

```text
switch restaurant
switch branch
logout
```

## Logout

Must:

```text
cancel realtime
clear MerchantContextService
clear sensitive local data
disable/remove push token
sign out
```

---

# 35. Admin Navigation Shell

## Mobile — Owner/Manager

```text
Dashboard
Orders
Menu
More
```

## Mobile — Cashier

```text
Orders
Payments
More
```

## Mobile — Waiter

```text
Orders
Tables
More
```

## Kitchen

```text
KDS
```

## Tablet

Use:

```text
NavigationRail
```

## Desktop

Use:

```text
Sidebar
```

---

# 36. MorePage / More Menu

Can expose:

```text
Tables
Staff
Payments
Reports
Settings
Profile
Switch Branch
Logout
```

Role-aware.

---

# 37. Branch Selector Contract

Header selector appears on operational screens:

```text
Dashboard
Orders
KDS
Menu
Payments
Reports
```

Switching branch:

1. confirm only if necessary
2. cancel branch-specific streams
3. update context
4. clear branch caches
5. reload screen

---

# 38. Restaurant Selector Contract

Less prominent than branch selector.

Place in:

```text
sidebar profile section
profile page
more menu
```

Avoid accidental restaurant switch during active service.

---

# 39. Admin Error Code Mapping

Centralize.

Examples:

```text
UNAUTHORIZED
→ "You don't have permission to perform this action."

MEMBERSHIP_INACTIVE
→ "Your restaurant access has been disabled."

BRANCH_ACCESS_DENIED
→ "You don't have access to this branch."

INVALID_STATUS_TRANSITION
→ "This order has already moved to another status."

PAYMENT_NOT_REFUNDABLE
→ "This payment can't be refunded."

REFUND_LIMIT_EXCEEDED
→ "You don't have permission to refund this amount."

INVITATION_EXPIRED
→ "This invitation has expired."
```

No raw SQL/RLS messages in UI.

---

# 40. Global Loading Contract

List screens:

```text
skeleton rows/cards
```

Forms:

```text
button loading
```

Dashboard:

```text
metric skeleton
```

KDS/live orders:

```text
show cached/previous state + reconnect if possible
```

---

# 41. Global Empty-State Contract

Examples:

Orders:

```text
No active orders.
```

Products:

```text
No products yet.
[Add Product]
```

Staff:

```text
No staff members yet.
[Invite Staff]
```

Payments:

```text
No payments found for this filter.
```

---

# 42. Global Offline Contract

If offline:

```text
show persistent banner
disable critical writes
keep cached reads if available
```

Do not allow fake local status/payment completion.

---

# 43. Global Realtime Contract

Used primarily for:

```text
orders
order status
KDS
```

On disconnect:

```text
show reconnecting state
```

On reconnect:

```text
refetch
then resubscribe
```

Database is source of truth.

---

# 44. Global Money Contract

Use:

```text
int minor units
```

No `double` for business values.

---

# 45. Global Date Contract

Display in restaurant timezone/business-day context where relevant.

Use centralized formatter.

---

# 46. Global Accessibility Contract

- [ ] touch targets >= 44×44
- [ ] semantic labels
- [ ] keyboard-friendly desktop/web
- [ ] KDS readable at distance
- [ ] statuses include text
- [ ] contrast adequate
- [ ] large text does not break layout

---

# 47. Global Responsive Contract

## Mobile

```text
single column
bottom nav
cards
bottom sheets
```

## Tablet

```text
navigation rail
two-column forms/lists
KDS columns
```

## Desktop

```text
sidebar
master-detail
data tables where useful
max form width 720
```

---

# 48. Screen State Matrix

| Screen | Loading | Empty | Error | Offline | Realtime |
|---|---:|---:|---:|---:|---:|
| Splash | Yes | No | Yes | Yes | No |
| Login | Submit | No | Yes | Block | No |
| Restaurant Select | Yes | Yes | Yes | Partial | No |
| Branch Select | Yes | Yes | Yes | Partial | No |
| Dashboard | Yes | Yes | Yes | Cached | Optional |
| Live Orders | Yes | Yes | Yes | Yes | Yes |
| Order Detail | Yes | No | Yes | Yes | Yes |
| KDS | Yes | Yes | Yes | Yes | Yes |
| Categories | Yes | Yes | Yes | Partial | No |
| Products | Yes | Yes | Yes | Partial | No |
| Product Form | Submit | No | Yes | Block writes | No |
| Modifiers | Yes | Yes | Yes | Partial | No |
| Tables | Yes | Yes | Yes | Partial | No |
| QR Preview | Yes | No | Yes | Partial | No |
| Staff | Yes | Yes | Yes | Partial | No |
| Payments | Yes | Yes | Yes | Partial | Optional |
| Reports | Yes | Yes | Yes | Cached optional | No |
| Settings | Yes | No | Yes | Block writes | No |
| Profile | Yes | No | Yes | Partial | No |

---

# 49. Admin Navigation Matrix

```text
Splash
→ Login
→ Restaurant Select
→ Branch Select
→ Dashboard / Orders / KDS

Dashboard
→ Orders
→ Reports
→ Payments

Orders
→ Order Detail
→ KDS

Menu
→ Categories
→ Products
→ Modifiers
→ Product Form

Tables
→ Table Form
→ QR Preview

Staff
→ Invite

Payments
→ Payment Detail
→ Refund

Settings
→ Restaurant
→ Branch
→ Opening Hours

Profile
→ Switch Restaurant
→ Switch Branch
→ Logout
```

---

# 50. Admin Analytics Matrix

| Screen | Events |
|---|---|
| Login | `admin_login` |
| Restaurant Select | `restaurant_selected` |
| Branch Select | `branch_selected` |
| Dashboard | `dashboard_view` |
| Orders | `live_orders_view` |
| Order Detail | `order_opened`, `order_status_change` |
| KDS | `kds_view`, `kds_status_change` |
| Products | `product_created`, `product_updated`, `sold_out_toggle` |
| Tables | `table_created`, `qr_rotated` |
| Staff | `staff_invited`, `staff_role_changed` |
| Payments | `cash_confirmed`, `refund_requested` |
| Reports | `report_view` |
| Settings | `settings_updated` |

Do not send customer PII unnecessarily.

---

# 51. Admin Screen File Structure

```text
features/
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
├── staff/
├── payments/
├── reports/
├── settings/
└── profile/
```

Each:

```text
bindings/
controllers/
views/
widgets/
```

---

# 52. Screen Implementation Template for AI Tools

For each admin screen create:

```text
1. route
2. binding
3. controller
4. view
5. feature widgets
6. repositories/services
7. role visibility
8. loading state
9. empty state
10. error state
11. responsive behavior
12. accessibility
13. analytics
14. tests
```

---

# 53. Controller Naming Contract

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
CategoryFormController
ProductController
ProductFormController
ModifierController
ModifierFormController
TableController
TableFormController
QrController
StaffController
StaffInviteController
PaymentsController
PaymentDetailController
RefundController
ReportsController
SettingsController
OpeningHoursController
ProfileController
```

Avoid giant:

```text
AdminController
AppController
RestaurantController
```

containing everything.

---

# 54. Binding Naming Contract

```text
AdminSplashBinding
AdminAuthBinding
RestaurantSelectBinding
BranchSelectBinding
DashboardBinding
LiveOrdersBinding
OrderDetailBinding
KdsBinding
CategoryBinding
CategoryFormBinding
ProductBinding
ProductFormBinding
ModifierBinding
ModifierFormBinding
TableBinding
TableFormBinding
QrBinding
StaffBinding
StaffInviteBinding
PaymentsBinding
PaymentDetailBinding
ReportsBinding
SettingsBinding
ProfileBinding
```

---

# 55. Repository Method Contract

Suggested:

```text
MerchantRepository
  getMemberships()
  getRestaurants()

BranchRepository
  getAccessibleBranches()

DashboardRepository
  getDashboardSummary(branchId, range)

OrderRepository
  getActiveOrders(branchId)
  watchActiveOrders(branchId)
  getOrder(orderId)
  changeStatus(...)
  cancelOrder(...)

MenuRepository
  getCategories(branchId)
  createCategory(...)
  updateCategory(...)
  getProducts(branchId)
  createProduct(...)
  updateProduct(...)
  setAvailability(...)

ModifierRepository
  getGroups(restaurantId)
  createGroup(...)
  updateGroup(...)
  assignToProduct(...)

TableRepository
  getTables(branchId)
  createTable(...)
  updateTable(...)
  rotateQr(...)

StaffRepository
  getMembers(restaurantId)
  invite(...)
  updateRole(...)
  assignBranches(...)
  deactivate(...)

PaymentRepository
  getPayments(branchId)
  getPayment(paymentId)
  confirmCash(...)
  requestRefund(...)

ReportRepository
  getSalesSummary(...)
  getProductSales(...)
  getPaymentBreakdown(...)

SettingsRepository
  getRestaurantSettings(...)
  updateRestaurantSettings(...)
  getBranchSettings(...)
  updateBranchSettings(...)
  getOpeningHours(...)
  updateOpeningHours(...)
```

Freeze exact payloads later in `API_CONTRACTS.md`.

---

# 56. Admin Security Rules

Views must never:

```text
trust local role as backend authority
set payment paid directly
refund directly with provider secret
change owner through direct update
change order status through raw update
edit another restaurant by changing ID
```

---

# 57. Admin Performance Rules

Live Orders:

```text
active statuses only
indexed query
realtime
```

KDS:

```text
branch active orders only
```

Reports:

```text
server aggregation
```

History:

```text
pagination
```

Avoid giant unfiltered reads.

---

# 58. Admin Copy Style

Use concise operational labels:

```text
Accept
Start Preparing
Mark Ready
Complete
Save Product
Invite Staff
Confirm Cash
Refund
```

Avoid long action labels.

---

# 59. Admin Critical Flow Acceptance

The admin app is screen-complete when:

```text
Login
→ Select Restaurant
→ Select Branch
→ Dashboard
→ Create Menu
→ Create Table
→ View QR
→ Receive Customer Order
→ Accept
→ Prepare
→ Ready
→ Complete
```

with:

```text
Realtime
Role-aware actions
Error recovery
Responsive layout
Security enforced server-side
```

---

# 60. Admin P0 Build Order

Implement in this order:

```text
1. SplashPage
2. LoginPage
3. RestaurantSelectPage
4. BranchSelectPage
5. DashboardPage
6. CategoryListPage
7. ProductListPage
8. ProductFormPage
9. ModifierGroupListPage
10. ModifierGroupFormPage
11. TableListPage
12. TableFormPage
13. QrPreviewPage
14. LiveOrdersPage
15. OrderDetailPage
16. KdsPage
```

Then:

```text
17. PaymentListPage
18. PaymentDetailPage
19. StaffListPage
20. StaffInvitePage
21. ReportsPage
22. SettingsPage
23. RestaurantSettingsPage
24. BranchSettingsPage
25. OpeningHoursPage
26. ProfilePage
```

---

# 61. Final AI Coding Instruction

When implementing the admin app:

```text
Read ADMIN_SCREEN_SPEC.md first.

Then read:
ADMIN_APP_FLOW.md
APP_DESIGN_SYSTEM_AND_UI_SPEC.md
Supabase_Backend_Specification_QR_Restaurant_Project.md
MVP_TASK_LIST.md

Treat ADMIN_SCREEN_SPEC.md as the screen behavior authority.

Do not invent:
- routes
- role access
- screen states
- status actions
- design tokens
- navigation behavior
- backend ownership rules

Use:
View → Controller → Repository → Supabase

Use RPC/Edge Functions for critical actions.

Do not call Supabase directly from Views.

Implement screens in P0 order.

After each screen:
- run flutter analyze
- run tests
- fix warnings/errors
- verify mobile
- verify tablet
- verify desktop where relevant
- update MVP checklist
```

---

# 62. Definition of ADMIN_SCREEN_SPEC Complete

This specification is complete when an AI coding tool can answer for every admin screen:

```text
What is the screen for?
Which roles may see it?
Which route opens it?
Which controller owns it?
Which repositories/services are used?
What data is shown?
What actions are available?
Which actions are destructive?
What happens on success?
What happens on error?
What happens offline?
How does Realtime behave?
How should it look on mobile/tablet/desktop?
What needs to be tested?
```

The implementation goal remains:

```text
Restaurant staff perception:
See → Act → Confirm → Track

System behavior:
Authenticate → Authorize → Validate → Update → Synchronize → Audit
```
