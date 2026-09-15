# CUSTOMER_SCREEN_SPEC.md
## QR Restaurant Ordering Platform
### Customer App — Screen-by-Screen Implementation Contract
### Flutter + GetX + MVC + Supabase
### For Codex, Cursor, Claude Code, Copilot, and Other AI Coding Tools

> This document is the **authoritative screen specification for the customer application**.
>
> It is intended to be consumed directly by AI coding tools and human developers.
>
> Use this document together with:
>
> - `CUSTOMER_APP_FLOW.md`
> - `APP_DESIGN_SYSTEM_AND_UI_SPEC.md`
> - `MVP_TASK_LIST.md`
> - `Supabase_Backend_Specification_QR_Restaurant_Project.md`
>
> AI tools must not invent routes, states, screen behavior, visual hierarchy, or backend contracts that conflict with these files.
>
> This document describes:
>
> - screen purpose
> - route
> - binding
> - controller
> - repositories/services
> - required UI sections
> - component usage
> - user actions
> - loading/empty/error states
> - backend interactions
> - navigation behavior
> - responsive behavior
> - analytics events
> - accessibility
> - acceptance criteria
>
> The customer app should feel simple:
>
> ```text
> Scan
> → Browse
> → Choose
> → Order
> → Pay
> → Track
> ```

---

# 1. Global Screen Rules

Every screen must:

- [ ] use the shared design system
- [ ] use centralized colors/spacing/typography
- [ ] use GetX route + binding where appropriate
- [ ] avoid direct Supabase calls in Views
- [ ] expose loading/error/empty state when relevant
- [ ] support small mobile width
- [ ] support tablet/web gracefully where relevant
- [ ] use semantic labels on icon-only actions
- [ ] avoid hardcoded money formatting
- [ ] avoid hardcoded status colors
- [ ] avoid hardcoded backend error strings
- [ ] use repository/service abstractions
- [ ] preserve cart/order state safely
- [ ] handle reconnect/retry where relevant

---

# 2. Customer Route Inventory

```text
/splash
/scan
/menu
/product/:id
/cart
/checkout
/payment/pending
/payment/failure
/order/:id
/orders
/orders/:id
/profile
/auth/phone
/auth/otp
```

Optional future routes:

```text
/restaurant/info
/addresses
/coupons
/loyalty
/favorites
```

---

# 3. Screen Priority

## P0

```text
SplashPage
QrScannerPage
MenuPage
ProductDetailPage
CartPage
CheckoutPage
OrderTrackingPage
```

## P1

```text
PaymentPendingPage
PaymentFailurePage
OrderHistoryPage
OrderDetailPage
ProfilePage
PhoneEntryPage
OtpPage
```

---

# 4. Shared Customer Screen Components

AI tools should reuse:

```text
CustomerPageScaffold
RestaurantHeader
CategoryTabBar
ProductCard
ProductGridCard
QuantitySelector
ModifierOptionTile
CartSummaryBar
CartItemCard
CheckoutSection
PriceSummary
PaymentMethodTile
OrderStatusTimeline
ActiveOrderBanner
OrderHistoryCard
AppPrimaryButton
AppSecondaryButton
AppDangerButton
AppTextField
AppSearchField
AppEmptyState
AppErrorState
AppLoadingSkeleton
```

---

# 5. Shared Customer Services

```text
SessionService
RestaurantContextService
DeepLinkService
ConnectivityService
LocalCartService
AppLifecycleService
NotificationService
AnalyticsService
```

---

# 6. Shared Customer Repositories

```text
AuthRepository
RestaurantRepository
MenuRepository
OrderRepository
PaymentRepository
ProfileRepository
```

Future:

```text
AddressRepository
CouponRepository
LoyaltyRepository
```

---

# 7. SplashPage

## Route

```text
/splash
```

## Purpose

Initialize the customer app and decide the first destination.

## Controller

```text
StartupController
```

## Dependencies

```text
SessionService
DeepLinkService
RestaurantContextService
LocalCartService
ConnectivityService
OrderRepository
```

## UI

Minimal:

```text
centered brand logo
app/product name optional
small progress indicator only if startup takes visible time
```

Do not show:

```text
marketing carousel
signup CTA
long animation
```

## Startup Responsibilities

1. initialize current auth/session state
2. create anonymous session if necessary
3. restore local restaurant context
4. restore local cart
5. read initial deep link
6. detect pending active order/payment
7. determine route

## Navigation Rules

If deep link is valid QR:

```text
Splash
→ resolve QR
→ Menu
```

If no deep link but valid saved restaurant context:

```text
Splash
→ Menu
```

If no context:

```text
Splash
→ QrScannerPage
```

If pending paid/placed order should be recovered:

```text
Splash
→ OrderTrackingPage
```

If pending payment requires resume:

```text
Splash
→ PaymentPending/Checkout recovery flow
```

## States

```text
initializing
error
```

Startup failure must not trap user forever.

Fallback:

```text
Try Again
Scan QR
```

## Analytics

```text
app_open
startup_completed
startup_failed
```

## Acceptance Criteria

- [ ] session is restored
- [ ] anonymous auth created when needed
- [ ] initial deep link is handled
- [ ] saved context validated
- [ ] stale invalid context is cleared
- [ ] correct destination is opened
- [ ] app does not loop between splash and target route

---

# 8. QrScannerPage

## Route

```text
/scan
```

## Purpose

Scan restaurant/table QR and establish ordering context.

## Controller

```text
QrController
```

## Dependencies

```text
RestaurantRepository
RestaurantContextService
CartController
ConnectivityService
AnalyticsService
```

## UI Structure

```text
AppBar
  Scan Restaurant QR

Scanner Viewport

Helper Text
  Point your camera at the QR code on your table.

Optional:
  "Enter link manually" later
```

## Scanner Design

```text
large centered camera viewport
rounded corners
clear scanning frame
dark surrounding overlay
```

## Actions

```text
scan QR
retry
camera permission settings
cancel/back if context exists
```

## QR Processing

```text
raw QR
↓
parse expected /q/<token>
↓
debounce duplicate scan
↓
resolve_qr RPC
↓
receive QrContext
↓
compare current context/cart
```

## If Same Restaurant/Branch

Update table context if valid.

## If New Restaurant and Cart Empty

Switch directly.

## If New Restaurant and Cart Not Empty

Show confirmation dialog:

```text
You already have items from another restaurant.

Switching restaurants will clear your cart.

[Cancel]
[Switch Restaurant]
```

## Loading State

While resolving:

```text
freeze duplicate scan
small overlay spinner
```

## Error States

```text
INVALID_QR
TABLE_INACTIVE
BRANCH_INACTIVE
RESTAURANT_INACTIVE
NETWORK_ERROR
UNKNOWN_ERROR
```

User copy examples:

```text
This QR code is not valid.
This table is currently unavailable.
This restaurant is not accepting orders right now.
Couldn't connect. Try again.
```

## Navigation

Success:

```text
QrScannerPage
→ MenuPage
```

## Analytics

```text
qr_scan
qr_resolved
qr_failed
restaurant_switched
```

## Acceptance Criteria

- [ ] camera permission handled
- [ ] same QR does not trigger many backend calls
- [ ] invalid QR shows recoverable error
- [ ] cart protection works on restaurant switch
- [ ] context saved only after successful resolution
- [ ] app navigates to MenuPage

---

# 9. MenuPage

## Route

```text
/menu
```

## Purpose

Primary browsing and ordering screen.

## Controller

```text
MenuController
```

## Dependencies

```text
MenuRepository
RestaurantContextService
CartController
OrderRepository
ConnectivityService
AnalyticsService
```

## Required UI Sections

```text
Restaurant Header
Active Order Banner optional
Search Field
Category Tabs
Product Sections/List
Floating Cart Summary Bar
```

## Restaurant Header

Show:

```text
logo
restaurant name
branch name
table or order type context
restaurant open/closed state if known
```

Example:

```text
Pizza House
Patna Main
Table 12
```

## Search

Use shared:

```text
AppSearchField
```

Search:

```text
product name
description
tags if available
```

For MVP use client-side search over fetched menu.

## Category Navigation

Horizontal list:

```text
Popular
Starters
Pizza
Burgers
Drinks
Desserts
```

Selecting category should:

```text
filter
or
scroll to section
```

Choose one consistent approach.

## Product Presentation

Mobile:

```text
one-column product list
```

Tablet:

```text
two-column grid allowed
```

Web:

```text
2–3 columns
```

## Product Card

Show:

```text
name
description
price
image
availability
add button
```

Optional:

```text
veg/non-veg indicator
tags
```

## Sold Out State

Show product with:

```text
Sold Out
```

and disabled Add.

Do not allow checkout solely based on cached availability; server still validates.

## Active Order Banner

If active order exists:

```text
Order #1042 • Preparing
[Track]
```

Tap:

```text
→ OrderTrackingPage
```

## Floating Cart Bar

Show only if cart not empty.

Example:

```text
3 items                ₹947
View Cart
```

Tap:

```text
→ CartPage
```

## Loading State

Use menu skeleton:

```text
header skeleton
search placeholder
product card skeletons
```

## Empty State

```text
Menu unavailable

This restaurant has no items available right now.

[Refresh]
```

## Error State

```text
Couldn't load the menu.

[Try Again]
```

## Pull To Refresh

Supported.

Refresh menu from backend.

## Closed Restaurant State

Menu may still show.

Disable ordering CTA where required.

Banner:

```text
This restaurant is currently closed for orders.
```

## Offline State

If cached menu exists:

```text
show cached menu
show offline banner
disable checkout
```

## Navigation

```text
Product tap
→ ProductDetailPage

Cart bar
→ CartPage

Track
→ OrderTrackingPage

Scan new QR
→ QrScannerPage
```

## Analytics

```text
menu_view
category_view
search
product_impression optional
```

## Acceptance Criteria

- [ ] restaurant/table context visible
- [ ] menu loads from repository
- [ ] search works
- [ ] category navigation works
- [ ] sold-out state works
- [ ] cart bar updates reactively
- [ ] active order banner works
- [ ] loading/empty/error states work
- [ ] page survives app resume
- [ ] no direct Supabase in View

---

# 10. ProductDetailPage

## Route

```text
/product/:id
```

## Purpose

Configure a menu item before adding it to cart.

## Controller

```text
ProductDetailController
```

## Dependencies

```text
MenuController or MenuRepository
CartController
RestaurantContextService
AnalyticsService
```

## Product Source

Prefer product lookup from already loaded menu model.

Do not re-fetch product unless needed.

## Required UI

```text
Product Image
Product Name
Description
Base Price
Modifier Groups
Quantity Selector
Item Note
Sticky Add-To-Cart CTA
```

## Image

Mobile:

```text
large top image
```

If absent:

```text
food placeholder
```

## Modifier Group UI

Each group shows:

```text
title
Required / Optional label
selection instruction
options
```

Example:

```text
Choose Size
Required • Select 1
```

## Option Types

If max = 1:

```text
radio
```

If max > 1:

```text
checkbox
```

## Modifier Row

Show:

```text
label
price delta
selected state
```

Example:

```text
Large                +₹100
```

## Modifier Validation

Before add:

```text
selected >= min_select
selected <= max_select
```

Error appears close to invalid group.

## Quantity

Use shared `QuantitySelector`.

Minimum:

```text
1
```

Maximum:

business-defined if implemented.

## Item Note

Optional multiline field.

Example placeholder:

```text
No onion, less spicy...
```

## Sticky CTA

Example:

```text
Add to Cart • ₹440
```

Price shown is client preview only.

## Existing Cart Edit Mode

If route opened to edit cart item:

- [ ] preselect modifiers
- [ ] restore quantity
- [ ] restore note
- [ ] CTA says `Update Cart`

## Loading/Error

If product no longer exists in local menu:

```text
This item is no longer available.
[Back to Menu]
```

## Navigation

After Add:

```text
return to Menu
```

or stay and show success.

Recommended:

```text
Get.back()
```

then cart bar updates.

## Analytics

```text
product_view
modifier_selected
add_to_cart
cart_item_updated
```

## Acceptance Criteria

- [ ] modifier rules render correctly
- [ ] required validation works
- [ ] quantity works
- [ ] note works
- [ ] preview total updates
- [ ] Add/Update uses CartController
- [ ] edit mode works
- [ ] sold-out product cannot be added

---

# 11. CartPage

## Route

```text
/cart
```

## Purpose

Review and edit local cart before checkout.

## Controller

```text
CartController
```

## Dependencies

```text
RestaurantContextService
LocalCartService
ConnectivityService
AnalyticsService
```

## Required UI

```text
Page Header
Restaurant/Table Context
Cart Item List
Order Note optional
Preview Price Summary
Proceed To Checkout CTA
```

## Header

```text
Your Cart
```

Context:

```text
Pizza House • Table 12
```

## Cart Item Card

Show:

```text
product name
selected modifiers
item note
quantity controls
unit/line preview price
remove
edit
```

## Edit

Tap:

```text
Edit
→ ProductDetailPage in edit mode
```

## Remove

For normal single cart line:

```text
remove directly with undo snackbar optional
```

No destructive dialog required.

## Quantity

Minimum 1.

If decrement from 1:

```text
remove
```

or disable minus and use explicit remove.

Choose consistent behavior.

## Preview Summary

```text
Subtotal
```

No final tax/discount authority here.

Label clearly if needed:

```text
Final total calculated at checkout.
```

## Empty State

```text
Your cart is empty.

Browse the menu and add something you like.

[Browse Menu]
```

## CTA

```text
Proceed to Checkout
```

Disabled if:

```text
offline
cart empty
invalid/stale restaurant context
```

## Context Mismatch

If cart context no longer matches:

```text
Your cart belongs to another restaurant.
[Clear Cart]
```

## Analytics

```text
cart_view
cart_quantity_changed
remove_from_cart
checkout_started
```

## Acceptance Criteria

- [ ] list updates reactively
- [ ] edit works
- [ ] quantity works
- [ ] local persistence updates
- [ ] empty state works
- [ ] checkout is blocked offline
- [ ] cart context shown clearly

---

# 12. CheckoutPage

## Route

```text
/checkout
```

## Purpose

Collect final order information and securely create the order.

## Controller

```text
CheckoutController
```

## Dependencies

```text
OrderRepository
CartController
RestaurantContextService
SessionService
ConnectivityService
PaymentRepository
AnalyticsService
```

## Required Sections

```text
Order Type
Restaurant/Table/Pickup Context
Customer Details
Order Note
Payment Method
Cart Summary
Server Price Summary
Place Order CTA
```

## Order Type

Show only enabled options:

```text
Dine-in
Takeaway
Delivery future
```

For QR table context:

```text
Dine-in selected by default
```

## Dine-In Context

Show:

```text
Table 12
```

Do not provide free-text table editing.

## Takeaway Context

Show:

```text
Pickup
ASAP
```

Scheduled pickup is future.

## Customer Details

MVP:

```text
name
phone if required by restaurant
```

Phone input:

```text
international format
```

## Order Note

Optional.

Example:

```text
Please bring extra plates.
```

## Payment Method

Show only methods enabled by backend/config.

Example:

```text
Cash
Online
```

## Before Submission

Validate:

```text
session exists
cart not empty
restaurant context exists
network available
form valid
payment method selected
```

## Submission

Generate/reuse idempotency key.

Send only:

```text
IDs
quantities
modifier IDs
notes
context
```

Do not trust/send final price as authoritative.

## create_order Handling

On success:

```text
store order ID
store server totals
clear cart only after order is safely created
```

If cash:

```text
→ OrderTrackingPage
```

If online:

```text
→ payment flow
```

## Price Changed Error

Show structured sheet/dialog:

```text
Some prices changed.

Burger
₹199 → ₹219

[Review Cart]
[Continue]
```

If backend requires explicit re-confirmation.

## Unavailable Product Error

Show:

```text
One item is no longer available.

Cheese Burger

[Back to Cart]
```

## Invalid Modifier Error

Return user to product/cart edit.

## Restaurant Closed Error

```text
This restaurant is not accepting orders right now.
```

## Duplicate Retry

Same idempotency key must be reused on network uncertainty.

## Loading

Button:

```text
Placing Order...
```

Disable repeated tap.

## Analytics

```text
checkout_view
order_submit
order_created
order_failed
```

## Acceptance Criteria

- [ ] only valid enabled order types shown
- [ ] server is authoritative for final totals
- [ ] idempotency key is stable for retry
- [ ] cart is not cleared before order success
- [ ] price/unavailability errors handled
- [ ] cash and online routes work correctly

---

# 13. PaymentPendingPage

## Route

```text
/payment/pending
```

## Purpose

Handle payment verification when client callback is not yet final.

## Controller

```text
PaymentController
```

## Dependencies

```text
PaymentRepository
OrderRepository
AppLifecycleService
ConnectivityService
AnalyticsService
```

## UI

Centered:

```text
spinner/status icon

Confirming payment

Order #1042

We're checking your payment status.
```

Actions:

```text
Check Again
Back to Order
```

Do not say:

```text
Payment failed
```

until server confirms failure.

## Behavior

On screen entry:

```text
query backend status
```

If pending:

```text
poll with controlled interval or allow manual refresh
```

Do not use aggressive short polling.

On app resume:

```text
re-check
```

## Outcomes

Paid:

```text
→ OrderTrackingPage
```

Failed:

```text
→ PaymentFailurePage
```

Still awaiting payment:

```text
stay
```

Order cancelled:

```text
show cancellation state
```

## Analytics

```text
payment_verification_pending
payment_verified
payment_verification_failed
```

## Acceptance Criteria

- [ ] backend status determines outcome
- [ ] page survives app background/resume
- [ ] no duplicate payment is created here
- [ ] user can recover safely

---

# 14. PaymentFailurePage

## Route

```text
/payment/failure
```

## Purpose

Allow recovery from verified failed/cancelled payment.

## Controller

```text
PaymentController
```

## UI

```text
failure icon

Payment failed

Your payment was not completed.

[Try Again]
[Choose Another Method]
[Back to Order]
```

If order remains payable.

## Retry

Use existing order ID.

Do not recreate order.

## Choose Another Method

If cash allowed:

```text
switch payment method
```

Backend must validate.

## Analytics

```text
payment_failed_view
payment_retry
payment_method_changed
```

## Acceptance Criteria

- [ ] retry reuses existing order
- [ ] no duplicate order
- [ ] verified server state shown
- [ ] customer can navigate away and recover later

---

# 15. OrderTrackingPage

## Route

```text
/order/:id
```

## Purpose

Show current live order status.

## Controller

```text
OrderTrackingController
```

## Dependencies

```text
OrderRepository
NotificationService
ConnectivityService
AnalyticsService
```

## Required UI

```text
Order Header
Status Timeline
Restaurant/Table Context
Order Items Summary
Payment Summary
Price Summary
Manual Refresh
Support shortcut optional
```

## Header

Show:

```text
Order #1042
Pizza House
Table 12
```

## Status Timeline

Map:

```text
awaiting_payment
placed
accepted
preparing
ready
served
completed
cancelled
```

Display only states relevant to current order type.

## Current State

Example:

```text
Preparing your order
```

## Timeline Design

```text
✓ Order received
✓ Accepted
● Preparing
○ Ready
○ Served
```

## Realtime

On init:

```text
fetch order
subscribe to order
```

On reconnect:

```text
refetch current order
```

## Connection Status

Subtle status:

```text
Live
Reconnecting...
```

Do not block screen.

## Ready State

Dine-in:

```text
Your order is ready to be served.
```

Takeaway:

```text
Your order is ready for pickup.
```

## Completed State

Show:

```text
Order completed
```

Offer:

```text
View Orders
Order Again later
```

## Cancelled State

Show reason if safe/available.

If refund pending:

```text
Refund processing
```

## Payment Section

Show:

```text
Cash
Online • Paid
Online • Pending
Refunded
```

## Items

Use order snapshots.

Never fetch current menu to reconstruct old item price.

## Push

If opened from push:

```text
load order securely by UUID
```

RLS handles ownership.

## Analytics

```text
order_tracking_view
order_status_seen
order_completed_view
```

## Acceptance Criteria

- [ ] initial fetch works
- [ ] realtime status works
- [ ] reconnect refetch works
- [ ] order-type-specific copy works
- [ ] completed/cancelled states work
- [ ] wrong user's order is blocked by backend

---

# 16. OrderHistoryPage

## Route

```text
/orders
```

## Purpose

Show customer order history.

## Controller

```text
OrderHistoryController
```

## Dependencies

```text
OrderRepository
SessionService
AnalyticsService
```

## UI

```text
Page Title
Order List
Pagination/Load More
```

## Order Card

Show:

```text
Restaurant Name
Order #1042
Date
Total
Status
```

Optional:

```text
branch name
order type
```

## Pagination

Recommended:

```text
20 items per page
```

or cursor-based approach.

## Empty State

```text
No orders yet.

Your completed and active orders will appear here.

[Scan QR]
```

## Error

```text
Couldn't load your orders.
[Try Again]
```

## Guest Behavior

Anonymous session can show history from current device/session.

If product strategy requires cross-device history:

```text
prompt phone verification
```

## Navigation

Tap order:

```text
→ OrderDetailPage
```

If active:

```text
→ OrderTrackingPage
```

## Analytics

```text
order_history_view
order_history_item_opened
```

## Acceptance Criteria

- [ ] pagination works
- [ ] only own orders visible
- [ ] active/completed status shown
- [ ] empty state works
- [ ] tapping item routes correctly

---

# 17. OrderDetailPage

## Route

```text
/orders/:id
```

## Purpose

Show full historical order details.

## Controller

```text
OrderDetailController
```

## Dependencies

```text
OrderRepository
AnalyticsService
```

## UI Sections

```text
Order Header
Restaurant/Branch
Order Type/Table
Item Snapshots
Modifier Snapshots
Price Breakdown
Payment
Status History
Receipt Actions future
```

## Important Rule

Use historical order snapshot.

Do not reconstruct from current product data.

## Header

```text
Order #1042
Completed
12 Sep 2026 • 6:31 PM
```

## Item List

Example:

```text
2 × Farmhouse Pizza
  Large
  Extra Cheese

₹880
```

## Summary

```text
Subtotal
Tax
Service charge
Discount
Total
```

## Status History

```text
6:31 PM Order placed
6:32 PM Accepted
6:37 PM Preparing
6:48 PM Ready
```

## Reorder

Future only.

If implemented later:

```text
validate against current menu
```

## Acceptance Criteria

- [ ] historical snapshot data shown
- [ ] payment state shown
- [ ] status history shown
- [ ] ownership protected
- [ ] no dependence on current menu

---

# 18. ProfilePage

## Route

```text
/profile
```

## Purpose

Show customer identity/account options.

## Controller

```text
ProfileController
```

## Dependencies

```text
ProfileRepository
SessionService
NotificationService
AnalyticsService
```

## Guest UI

```text
Guest

Verify your phone to keep your order history across devices.

[Verify Phone]
```

Sections:

```text
Orders
Notifications
Help
About
Logout
```

## Verified User UI

Show:

```text
name
phone
avatar future
```

Actions:

```text
Edit profile
Orders
Logout
```

## Logout

If anonymous user logs out, warn about local history implications if applicable.

On logout:

```text
cancel realtime
clear private user cache
disable/remove push token
sign out
```

Restaurant context/cart retention is a product decision; MVP can clear private state and preserve only safe public context if desired.

## Analytics

```text
profile_view
logout
phone_verification_started
```

## Acceptance Criteria

- [ ] guest and verified states differ correctly
- [ ] profile data loads
- [ ] logout safely clears user-specific state
- [ ] verify phone CTA routes correctly

---

# 19. PhoneEntryPage

## Route

```text
/auth/phone
```

## Purpose

Begin customer phone verification.

## Controller

```text
AuthController
```

## Dependencies

```text
AuthRepository
AnalyticsService
```

## UI

```text
Title:
Verify your phone

Phone field
Country code
Continue button
```

Default market may show:

```text
+91
```

but architecture must support other country codes.

## Validation

- [ ] valid phone format
- [ ] required
- [ ] normalize to international format

## Submit

Call:

```text
send OTP
```

Then:

```text
→ OtpPage
```

## Errors

```text
invalid number
too many requests
network error
provider unavailable
```

## Analytics

```text
phone_verification_started
otp_requested
otp_request_failed
```

## Acceptance Criteria

- [ ] valid phone accepted
- [ ] invalid input blocked
- [ ] loading state shown
- [ ] OTP route receives normalized phone

---

# 20. OtpPage

## Route

```text
/auth/otp
```

## Purpose

Verify phone OTP.

## Controller

```text
AuthController
```

## UI

```text
Enter verification code

We sent a code to +91••••••••42

[ _ _ _ _ _ _ ]

Verify

Resend in 00:30
```

## Requirements

- [ ] numeric OTP input
- [ ] auto-focus
- [ ] paste support if possible
- [ ] resend cooldown
- [ ] loading state
- [ ] error state

## Successful Verification

Update/upgrade authenticated identity according to project auth strategy.

Then:

```text
→ ProfilePage
or previous intended route
```

## Errors

```text
wrong OTP
expired OTP
rate limited
network failure
```

## Analytics

```text
otp_verify
otp_verified
otp_verify_failed
otp_resent
```

## Acceptance Criteria

- [ ] OTP verification works
- [ ] resend cooldown works
- [ ] errors are clear
- [ ] prior customer order ownership is preserved according to auth implementation strategy

---

# 21. Optional RestaurantInfoPage

## Route

```text
/restaurant/info
```

## Priority

P2.

## Purpose

Show public restaurant information.

## UI

```text
logo
name
branch
address
phone
opening hours
order types
about
```

No private business data.

---

# 22. Global Bottom Navigation

If enabled in MVP:

```text
Menu
Orders
Profile
```

If no restaurant context:

```text
Scan
Orders
Profile
```

## Rules

- [ ] selected state uses primary
- [ ] one navigation style only
- [ ] do not show on checkout/payment/tracking full-focus flows if UX is cleaner without it

---

# 23. Customer App Shell Rules

Screens using main shell:

```text
MenuPage
OrderHistoryPage
ProfilePage
```

Focused transactional screens may use standalone scaffold:

```text
ProductDetailPage
CartPage
CheckoutPage
PaymentPendingPage
PaymentFailurePage
OrderTrackingPage
OtpPage
```

---

# 24. Global App Bar Rules

Use simple app bars.

Do not clutter with:

```text
too many actions
marketing buttons
unrelated icons
```

Common actions:

```text
back
scan QR
cart
profile
```

---

# 25. Customer Error Code Mapping

Centralize.

Example mapping:

```text
INVALID_QR
→ "This QR code is not valid."

TABLE_INACTIVE
→ "This table is currently unavailable."

BRANCH_INACTIVE
→ "This branch is not accepting orders."

RESTAURANT_CLOSED
→ "This restaurant is currently closed."

PRODUCT_UNAVAILABLE
→ "This item is no longer available."

INVALID_MODIFIER
→ "One of your selected options is no longer available."

PAYMENT_FAILED
→ "Your payment could not be completed."

UNAUTHORIZED
→ "Your session has expired. Please try again."
```

Views should never display raw backend codes.

---

# 26. Global Loading State Contract

Every async page should define:

```text
initial
loading
success
empty
error
```

when meaningful.

Critical CTA async actions additionally define:

```text
submitting
```

---

# 27. Global Connectivity Contract

If offline:

Menu with cache:

```text
view allowed
checkout blocked
```

Cart:

```text
edit allowed
checkout blocked
```

Tracking:

```text
show last state
show reconnecting/offline indicator
refetch on reconnect
```

Payment:

```text
do not declare failure solely because network disconnected
```

---

# 28. Global Money Contract

All models:

```text
int minor units
```

Formatting through shared formatter.

Example:

```text
89250
→ ₹892.50
```

Do not use `double` for totals.

---

# 29. Global Date Contract

Backend timestamps:

```text
timestamptz
```

Flutter:

```text
parse typed timestamp
convert to local
format centrally
```

---

# 30. Global Image Contract

Every image widget must include:

```text
placeholder
error fallback
cache
fixed aspect ratio
```

Product card image ratios must be consistent.

---

# 31. Global Accessibility Contract

Every screen must support:

- [ ] text scaling
- [ ] semantic page titles
- [ ] semantic icon buttons
- [ ] touch target >= 44×44
- [ ] status text in addition to color
- [ ] readable contrast
- [ ] keyboard navigation on web where relevant

---

# 32. Global Responsive Contract

## Mobile

```text
< 600
single-column
16px page padding
```

## Tablet

```text
600–1023
24px page padding
2-column where useful
```

## Desktop/Web

```text
>= 1024
centered content
max width around 1100 for customer app
2–3 column menu grid
```

---

# 33. Customer Screen State Matrix

| Screen | Loading | Empty | Error | Offline | Realtime |
|---|---:|---:|---:|---:|---:|
| Splash | Yes | No | Yes | Yes | No |
| QR Scanner | Resolve only | No | Yes | Yes | No |
| Menu | Yes | Yes | Yes | Yes | No |
| Product Detail | Minimal | No | Yes | Cached | No |
| Cart | No | Yes | Context error | Yes | No |
| Checkout | Submit | No | Yes | Block | No |
| Payment Pending | Yes | No | Yes | Special | No |
| Payment Failure | No | No | Yes | Yes | No |
| Tracking | Yes | No | Yes | Yes | Yes |
| Order History | Yes | Yes | Yes | Cached optional | No |
| Order Detail | Yes | No | Yes | Cached optional | No |
| Profile | Yes | No | Yes | Partial | No |
| Phone Entry | Submit | No | Yes | Block | No |
| OTP | Submit | No | Yes | Block | No |

---

# 34. Navigation Matrix

```text
Splash
→ Scan
→ Menu

Menu
→ Product
→ Cart
→ Scan
→ Orders
→ Profile
→ Tracking

Product
→ Menu

Cart
→ Menu
→ Checkout

Checkout
→ Cart
→ Payment Pending
→ Tracking

Payment Pending
→ Tracking
→ Payment Failure

Payment Failure
→ Payment Retry
→ Checkout
→ Order

Tracking
→ Menu
→ Orders

Orders
→ Order Detail
→ Tracking

Profile
→ Phone Entry
→ Orders

Phone Entry
→ OTP

OTP
→ Profile
```

---

# 35. Customer App Analytics Matrix

| Screen | Required Event |
|---|---|
| Splash | `app_open` |
| QR | `qr_scan`, `qr_resolved`, `qr_failed` |
| Menu | `menu_view`, `search`, `category_view` |
| Product | `product_view`, `add_to_cart` |
| Cart | `cart_view`, `remove_from_cart` |
| Checkout | `checkout_view`, `order_submit`, `order_created` |
| Payment | `payment_started`, `payment_succeeded`, `payment_failed` |
| Tracking | `order_tracking_view` |
| History | `order_history_view` |
| Profile | `profile_view` |
| Phone | `phone_verification_started` |

Do not include raw phone/address/payment secrets in analytics.

---

# 36. Customer Screen File Structure

Recommended:

```text
features/
├── splash/
│   ├── bindings/
│   ├── controllers/
│   ├── views/
│   └── widgets/
│
├── qr/
├── menu/
├── product/
├── cart/
├── checkout/
├── payment/
├── order_tracking/
├── order_history/
├── profile/
└── auth/
```

---

# 37. Screen Implementation Template for AI Tools

When implementing any screen, AI tool must produce:

```text
1. route entry
2. binding
3. controller
4. view
5. feature widgets
6. repository/service calls
7. loading state
8. error state
9. empty state if applicable
10. responsive handling
11. accessibility semantics
12. analytics hook
13. widget/controller tests
```

---

# 38. Controller Naming Contract

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
OrderDetailController
ProfileController
AuthController
```

Do not create:

```text
CustomerController
MainController
AppController
```

as giant global business controllers.

---

# 39. Binding Naming Contract

```text
SplashBinding
QrBinding
MenuBinding
ProductDetailBinding
CartBinding
CheckoutBinding
PaymentBinding
OrderTrackingBinding
OrderHistoryBinding
OrderDetailBinding
ProfileBinding
AuthBinding
```

---

# 40. Customer Repository Method Contract

Suggested methods:

```text
RestaurantRepository
  resolveQr(token)

MenuRepository
  getMenu(branchId)

OrderRepository
  createOrder(request)
  getOrder(orderId)
  watchOrder(orderId)
  getOrders(...)
  getOrderDetails(orderId)

PaymentRepository
  createPayment(orderId)
  getPaymentStatus(orderId)
  retryPayment(orderId)

ProfileRepository
  getProfile()
  updateProfile()

AuthRepository
  ensureAnonymousSession()
  sendPhoneOtp(phone)
  verifyPhoneOtp(phone, otp)
```

Exact request/response schema must later be frozen in `API_CONTRACTS.md`.

---

# 41. Customer Screen Security Rules

Views must never:

```text
set payment paid
set order status
choose trusted price
trust local role
trust table ID
trust branch ID
```

Backend must validate.

---

# 42. Customer Screen Performance Rules

Menu:

```text
single menu payload
lazy list/grid
cached images
```

Tracking:

```text
one realtime order subscription
```

History:

```text
pagination
```

Avoid:

```text
N+1 product modifier calls
aggressive polling
```

---

# 43. Customer Screen Copy Style

Use:

```text
short
clear
action-oriented
friendly
```

Good:

```text
Add to Cart
Place Order
Try Again
Mark as Paid — not customer
Track Order
```

Avoid verbose instructional paragraphs.

---

# 44. Customer Critical Flow Acceptance

The customer application is screen-complete when a user can perform:

```text
Splash
→ Scan QR
→ Menu
→ Product Detail
→ Add to Cart
→ Cart
→ Checkout
→ Cash/Online Payment
→ Order Tracking
→ Order History
```

with:

```text
loading states
error recovery
offline behavior
server validation
realtime updates
responsive UI
```

---

# 45. Customer P0 Build Order

AI implementation should follow:

```text
1. SplashPage
2. QrScannerPage
3. MenuPage
4. ProductDetailPage
5. CartPage
6. CheckoutPage
7. OrderTrackingPage
```

Then:

```text
8. PaymentPendingPage
9. PaymentFailurePage
10. OrderHistoryPage
11. OrderDetailPage
12. ProfilePage
13. PhoneEntryPage
14. OtpPage
```

Do not start loyalty, addresses, coupons, or delivery UI before P0/P1 is stable.

---

# 46. Final AI Coding Instruction

When implementing the customer app:

```text
Read CUSTOMER_SCREEN_SPEC.md first.

Then read:
CUSTOMER_APP_FLOW.md
APP_DESIGN_SYSTEM_AND_UI_SPEC.md
Supabase_Backend_Specification_QR_Restaurant_Project.md
MVP_TASK_LIST.md

Treat CUSTOMER_SCREEN_SPEC.md as the screen behavior authority.

Do not invent:
- routes
- screen states
- status behavior
- backend ownership rules
- design tokens
- component styles
- navigation behavior

Use:
View → Controller → Repository → Supabase

Keep Views presentation-only.

Implement screens in P0 order.

After each screen:
- run flutter analyze
- run relevant tests
- fix warnings/errors
- verify small mobile layout
- verify tablet layout where relevant
- update MVP checklist
```

---

# 47. Definition of CUSTOMER_SCREEN_SPEC Complete

This specification is complete when an AI coding tool can answer for every customer screen:

```text
What is this screen for?
What route opens it?
Which controller owns it?
Which repositories/services does it use?
What does it display?
What can the user do?
What happens on success?
What happens on error?
What happens offline?
Where does it navigate?
How should it look?
What needs to be tested?
```

The implementation goal remains:

```text
Customer perception:
Scan → Choose → Order → Track

System behavior:
Authenticate → Validate → Price → Create → Pay → Synchronize
```
