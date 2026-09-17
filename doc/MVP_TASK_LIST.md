# MVP_TASK_LIST.md
## QR Restaurant Ordering Platform — Flutter + GetX + MVC + Supabase

> Build-ready MVP task checklist for the complete restaurant QR ordering platform.
>
> This file is intended to be used directly as the implementation tracker for:
>
> - Supabase backend
> - Customer Flutter app
> - Admin/Merchant Flutter app
> - QR ordering
> - Menu management
> - Cart and checkout
> - Secure order creation
> - Realtime order flow
> - Kitchen Display System
> - Payments
> - Staff roles
> - Testing
> - Staging
> - Pilot launch
>
> The MVP is successful when:
>
> ```text
> Restaurant creates menu
> → creates table QR
> → customer scans QR
> → sees menu
> → adds items
> → places order
> → order appears in admin/KDS
> → staff processes order
> → customer sees live status
> → payment is safe
> → order completes
> ```

---

# 1. MVP Scope

## Customer MVP

- [ ] Anonymous/guest authentication
- [ ] QR scan
- [ ] Deep-link QR handling
- [ ] Restaurant/table resolution
- [ ] Menu
- [ ] Categories
- [ ] Product details
- [ ] Modifiers
- [ ] Cart
- [ ] Cart persistence
- [ ] Dine-in checkout
- [ ] Takeaway checkout
- [ ] Cash payment
- [ ] Online payment
- [ ] Secure order creation
- [ ] Realtime order tracking
- [ ] Order history
- [ ] Basic profile
- [ ] Push notification for order ready

## Admin MVP

- [ ] Login
- [ ] Restaurant membership
- [ ] Branch selection
- [ ] Dashboard
- [ ] Category management
- [ ] Product management
- [ ] Modifier management
- [ ] Product image upload
- [ ] Table management
- [ ] QR generation
- [ ] Live orders
- [ ] Order detail
- [ ] KDS
- [ ] Order status changes
- [ ] Order history
- [ ] Payments
- [ ] Cash payment confirmation
- [ ] Staff roles
- [ ] Basic reports
- [ ] Restaurant/branch settings

## Backend MVP

- [ ] Supabase Auth
- [ ] PostgreSQL schema
- [ ] RLS
- [ ] SQL grants
- [ ] Storage
- [ ] RPCs
- [ ] Realtime
- [ ] Edge Functions
- [ ] Payment webhook
- [ ] Indexes
- [ ] Audit logging
- [ ] Migrations
- [ ] Seed data
- [ ] Staging environment

---

# 2. Out of Scope for MVP

Do **not** build these before the main ordering loop is working:

- [ ] Inventory ERP
- [ ] Recipe costing
- [ ] Purchase orders
- [ ] Supplier management
- [ ] Advanced CRM
- [ ] AI waiter
- [ ] AI recommendations
- [ ] AI translations
- [ ] Reservation engine
- [ ] Driver fleet
- [ ] Advanced delivery tracking
- [ ] Franchise hierarchy
- [ ] Advanced accounting
- [ ] Loyalty engine
- [ ] Multi-party group ordering
- [ ] Offline POS sync engine
- [ ] Complex table-session billing
- [ ] Advanced permission overrides
- [ ] Advanced marketing automation

---

# 3. Project Repository Setup

## 3.1 Monorepo

- [ ] Create root repository
- [ ] Create `/apps/customer_app`
- [ ] Create `/apps/merchant_app`
- [ ] Create `/packages/app_core`
- [ ] Create `/packages/app_models`
- [ ] Create `/packages/app_widgets`
- [ ] Create `/supabase`
- [ ] Add root README
- [ ] Add `.gitignore`
- [ ] Add environment documentation
- [ ] Add project architecture docs
- [ ] Add customer flow docs
- [ ] Add admin flow docs
- [ ] Add Supabase backend docs
- [ ] Add this MVP task file

### Definition of Done

- [ ] Both Flutter apps run independently
- [ ] Shared packages compile
- [ ] Supabase directory is tracked
- [ ] No secrets committed to Git

---

# 4. Environment Setup

## 4.1 Local

- [ ] Install Flutter stable
- [ ] Install Dart dependencies
- [ ] Install Supabase CLI
- [ ] Install Docker if using local Supabase
- [ ] Run local Supabase
- [ ] Verify local database
- [ ] Verify Auth locally
- [ ] Verify Storage locally

## 4.2 Supabase Projects

- [ ] Create development Supabase project
- [ ] Create staging Supabase project
- [ ] Create production Supabase project
- [ ] Record project URLs securely
- [ ] Record publishable keys
- [ ] Store server secrets securely
- [ ] Never put service/secret keys in Flutter

### Definition of Done

- [ ] Flutter dev app connects to development Supabase
- [ ] Staging uses separate project
- [ ] Production credentials are isolated

---

# 5. Flutter Base Setup — Customer App

- [ ] Create Flutter app
- [ ] Add `get`
- [ ] Add `supabase_flutter`
- [ ] Add `cached_network_image`
- [ ] Add `mobile_scanner`
- [ ] Add `intl`
- [ ] Add local storage package
- [ ] Add connectivity package
- [ ] Add app links/deep-link package
- [ ] Add push package later
- [ ] Configure Android
- [ ] Configure iOS
- [ ] Configure Flutter Web if used

---

# 6. Flutter Base Setup — Admin App

- [ ] Create Flutter app
- [ ] Add `get`
- [ ] Add `supabase_flutter`
- [ ] Add `cached_network_image`
- [ ] Add image picker
- [ ] Add local storage
- [ ] Add connectivity package
- [ ] Add push package
- [ ] Configure Android
- [ ] Configure iOS
- [ ] Configure web
- [ ] Configure tablet layouts

---

# 7. Shared Flutter Architecture

## 7.1 Shared Packages

- [ ] Create money formatter
- [ ] Create date formatter
- [ ] Create environment config
- [ ] Create common API error types
- [ ] Create common enums
- [ ] Create common models
- [ ] Create shared theme tokens
- [ ] Create reusable loading widget
- [ ] Create reusable empty-state widget
- [ ] Create reusable error widget
- [ ] Create reusable confirmation dialog

## 7.2 Architecture Rule

Use:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Supabase
```

- [ ] No raw Supabase queries in Views
- [ ] Controllers do not contain secrets
- [ ] Repositories map backend errors
- [ ] Critical business logic stays backend-side

---

# 8. Supabase Migration Foundation

- [ ] Initialize Supabase migrations
- [ ] Create private schema
- [ ] Add required extensions
- [ ] Create reusable `updated_at` trigger function
- [ ] Add migration naming convention
- [ ] Add seed file
- [ ] Add reset workflow

### Definition of Done

- [ ] `supabase db reset` rebuilds backend
- [ ] All schema changes are migration-driven

---

# 9. Database Enums

- [ ] Create `staff_role`
- [ ] Create `order_type`
- [ ] Create `order_status`
- [ ] Create `payment_status`
- [ ] Create `payment_method`
- [ ] Create `discount_type` if coupons included

---

# 10. Profiles Table

- [ ] Create `profiles`
- [ ] FK to `auth.users`
- [ ] Add `full_name`
- [ ] Add `phone`
- [ ] Add `avatar_path`
- [ ] Add timestamps
- [ ] Add RLS
- [ ] Add self-select policy
- [ ] Add self-update policy
- [ ] Add Auth user profile creation trigger

---

# 11. Restaurant Tables

- [ ] Create `restaurants`
- [ ] Create `restaurant_settings`
- [ ] Add restaurant slug
- [ ] Add currency
- [ ] Add timezone
- [ ] Add active state
- [ ] Add created-by
- [ ] Add timestamps
- [ ] Add `allow_dine_in`
- [ ] Add `allow_takeaway`
- [ ] Add `allow_delivery`
- [ ] Add guest checkout setting
- [ ] Add payment-before-kitchen setting
- [ ] Add default tax configuration
- [ ] Add service-charge configuration

---

# 12. Restaurant Membership

- [ ] Create `restaurant_members`
- [ ] Add role
- [ ] Add active state
- [ ] Add inviter
- [ ] Add timestamps
- [ ] Add unique restaurant/user pair
- [ ] Add user membership lookup index

### Roles

- [ ] Owner
- [ ] Manager
- [ ] Cashier
- [ ] Waiter
- [ ] Kitchen

---

# 13. Branch Tables

- [ ] Create `branches`
- [ ] Add restaurant FK
- [ ] Add branch name
- [ ] Add code
- [ ] Add phone
- [ ] Add address
- [ ] Add city/state/postal code
- [ ] Add country
- [ ] Add lat/lng optional
- [ ] Add active state
- [ ] Add timestamps
- [ ] Create `branch_members`
- [ ] Add membership indexes

---

# 14. Opening Hours

Recommended for MVP or immediate Phase 1.1:

- [ ] Create `branch_opening_hours`
- [ ] Add weekday
- [ ] Add opening time
- [ ] Add closing time
- [ ] Add closed flag
- [ ] Add admin UI later

---

# 15. Dining Tables

- [ ] Create `dining_tables`
- [ ] Add branch FK
- [ ] Add table name
- [ ] Add capacity
- [ ] Add random `qr_token`
- [ ] Add active state
- [ ] Add timestamps
- [ ] Add unique branch/table name
- [ ] Add unique QR token

Optional:

- [ ] Create `dining_areas`

---

# 16. Menu Categories

- [ ] Create `categories`
- [ ] Add branch FK
- [ ] Add name
- [ ] Add description
- [ ] Add image path
- [ ] Add sort order
- [ ] Add active flag
- [ ] Add timestamps
- [ ] Add branch/sort index

---

# 17. Products

- [ ] Create `products`
- [ ] Add branch FK
- [ ] Add category FK
- [ ] Add name
- [ ] Add description
- [ ] Add price in minor units
- [ ] Add image path
- [ ] Add veg/non-veg optional
- [ ] Add availability flag
- [ ] Add active/archive flag
- [ ] Add sort order
- [ ] Add timestamps
- [ ] Add indexes

### Validation

- [ ] Price >= 0
- [ ] Product belongs to category branch
- [ ] Archived products not shown publicly
- [ ] Sold-out products rejected at checkout

---

# 18. Modifiers

## 18.1 Modifier Groups

- [ ] Create `modifier_groups`
- [ ] Add restaurant FK
- [ ] Add name
- [ ] Add `min_select`
- [ ] Add `max_select`
- [ ] Add required flag
- [ ] Add sort order
- [ ] Add active flag
- [ ] Add constraints

## 18.2 Modifiers

- [ ] Create `modifiers`
- [ ] Add group FK
- [ ] Add name
- [ ] Add price delta minor units
- [ ] Add availability
- [ ] Add active flag
- [ ] Add sort order

## 18.3 Product Assignment

- [ ] Create `product_modifier_groups`
- [ ] Add product FK
- [ ] Add modifier group FK
- [ ] Add sort order

---

# 19. Orders Table

- [ ] Create `orders`
- [ ] Add restaurant FK
- [ ] Add branch FK
- [ ] Add table FK nullable
- [ ] Add customer FK
- [ ] Add human-readable order number
- [ ] Add order type
- [ ] Add status
- [ ] Add currency snapshot
- [ ] Add subtotal minor
- [ ] Add tax minor
- [ ] Add service charge minor
- [ ] Add discount minor
- [ ] Add delivery fee minor
- [ ] Add total minor
- [ ] Add customer name snapshot
- [ ] Add phone snapshot
- [ ] Add customer note
- [ ] Add idempotency key
- [ ] Add placed timestamp
- [ ] Add completed timestamp
- [ ] Add cancelled timestamp
- [ ] Add timestamps

---

# 20. Order Items

- [ ] Create `order_items`
- [ ] Add order FK
- [ ] Add product FK
- [ ] Add product name snapshot
- [ ] Add unit price snapshot
- [ ] Add quantity
- [ ] Add modifier total snapshot
- [ ] Add line total
- [ ] Add item note
- [ ] Add timestamp

---

# 21. Order Item Modifiers

- [ ] Create `order_item_modifiers`
- [ ] Add order item FK
- [ ] Add modifier FK
- [ ] Add modifier name snapshot
- [ ] Add price delta snapshot
- [ ] Add timestamp

---

# 22. Order Status History

- [ ] Create `order_status_history`
- [ ] Add order FK
- [ ] Add old status
- [ ] Add new status
- [ ] Add changed_by
- [ ] Add reason
- [ ] Add timestamp
- [ ] Make client updates impossible
- [ ] Insert through controlled server logic

---

# 23. Payments

- [ ] Create `payments`
- [ ] Add order FK
- [ ] Add payment method
- [ ] Add provider
- [ ] Add provider order ID
- [ ] Add provider payment ID
- [ ] Add amount minor
- [ ] Add currency
- [ ] Add payment status
- [ ] Add failure fields
- [ ] Add paid timestamp
- [ ] Add refund timestamp
- [ ] Add timestamps
- [ ] Add provider indexes

---

# 24. Webhook Events

- [ ] Create `webhook_events`
- [ ] Add provider
- [ ] Add provider event ID
- [ ] Add event type
- [ ] Add payload JSON
- [ ] Add processed timestamp
- [ ] Add error field
- [ ] Add unique provider/event ID
- [ ] Block client access

---

# 25. Refund Table

Recommended for MVP if online payment included:

- [ ] Create `payment_refunds`
- [ ] Add payment FK
- [ ] Add amount
- [ ] Add provider refund ID
- [ ] Add reason
- [ ] Add requested_by
- [ ] Add status
- [ ] Add timestamps

---

# 26. Device Tokens

- [ ] Create `device_tokens`
- [ ] Add user FK
- [ ] Add token
- [ ] Add platform
- [ ] Add app type
- [ ] Add active flag
- [ ] Add last seen
- [ ] Add uniqueness
- [ ] Add RLS

---

# 27. Audit Logs

- [ ] Create `audit_logs`
- [ ] Add restaurant ID
- [ ] Add branch ID
- [ ] Add actor user ID
- [ ] Add action
- [ ] Add entity type
- [ ] Add entity ID
- [ ] Add metadata JSON
- [ ] Add timestamp
- [ ] Block client edits

Audit important actions:

- [ ] Product price changed
- [ ] Product archived
- [ ] Product sold out
- [ ] Order cancelled
- [ ] Refund requested
- [ ] Staff invited
- [ ] Staff role changed
- [ ] QR rotated
- [ ] Tax setting changed
- [ ] Branch paused

---

# 28. Database Indexes

- [ ] Restaurant member user index
- [ ] Branch member user index
- [ ] Category branch/sort index
- [ ] Product branch/category/sort index
- [ ] Active orders branch/status/time index
- [ ] Customer order history index
- [ ] Payment provider order index
- [ ] Payment provider payment index
- [ ] Order idempotency index
- [ ] Add indexes used by RLS helpers

---

# 29. Private Authorization Helpers

- [ ] Create private schema helper for restaurant membership
- [ ] Create restaurant role helper
- [ ] Create branch access helper
- [ ] Pin `search_path`
- [ ] Schema-qualify every object
- [ ] Review `security definer`
- [ ] Restrict grants
- [ ] Add tests

---

# 30. RLS — Foundation

Enable RLS on:

- [ ] profiles
- [ ] restaurants
- [ ] restaurant_settings
- [ ] restaurant_members
- [ ] branches
- [ ] branch_members
- [ ] dining_tables
- [ ] categories
- [ ] products
- [ ] modifier_groups
- [ ] modifiers
- [ ] product_modifier_groups
- [ ] orders
- [ ] order_items
- [ ] order_item_modifiers
- [ ] order_status_history
- [ ] payments
- [ ] payment_refunds
- [ ] device_tokens
- [ ] audit_logs

---

# 31. RLS — Customer

- [ ] Customer can read own profile
- [ ] Customer can update own profile
- [ ] Customer can read public menu data only
- [ ] Customer can read own orders
- [ ] Customer can read own order items
- [ ] Customer can read own order status history
- [ ] Customer can read safe own payment status
- [ ] Customer cannot update payment
- [ ] Customer cannot update order financial fields
- [ ] Customer cannot access another user's order
- [ ] Anonymous authenticated user behaves correctly

---

# 32. RLS — Merchant

- [ ] Owner can read own restaurant
- [ ] Manager can read allowed restaurant
- [ ] Branch staff only access assigned branch
- [ ] Staff cannot access another restaurant
- [ ] Menu writes restricted to authorized staff
- [ ] Staff membership reads restricted
- [ ] Payments readable only if permitted
- [ ] Kitchen access limited as designed
- [ ] Audit logs protected

---

# 33. SQL Grants

For every table define:

```text
anon
authenticated
server
```

- [ ] Review SELECT
- [ ] Review INSERT
- [ ] Review UPDATE
- [ ] Review DELETE
- [ ] Remove broad unnecessary privileges
- [ ] Review function execute grants
- [ ] Review private schema usage grants

---

# 34. Storage Buckets

Create:

- [ ] `restaurant-assets`
- [ ] `menu-images`
- [ ] `avatars`

Decide:

- [ ] Public/private bucket behavior
- [ ] File-size limits
- [ ] MIME types
- [ ] Path convention
- [ ] Storage RLS

---

# 35. Storage Policies

- [ ] Public can read public menu images
- [ ] Customer cannot upload menu images
- [ ] Authorized staff can upload own restaurant images
- [ ] Cross-tenant upload blocked
- [ ] Unauthorized delete blocked
- [ ] Avatar upload restricted to own user

---

# 36. RPC — `resolve_qr`

Implement:

- [ ] Accept QR token
- [ ] Validate table active
- [ ] Validate branch active
- [ ] Validate restaurant active
- [ ] Return safe restaurant context
- [ ] Return safe branch context
- [ ] Return safe table context
- [ ] No private fields
- [ ] Grant to required roles
- [ ] Test invalid token
- [ ] Test disabled table

### Definition of Done

```text
QR token
→ restaurant
→ branch
→ table
```

works safely.

---

# 37. RPC — `get_public_menu`

- [ ] Accept branch ID
- [ ] Validate branch active
- [ ] Validate restaurant active
- [ ] Return active categories
- [ ] Return active products
- [ ] Return modifier groups
- [ ] Return available modifiers
- [ ] Return currency
- [ ] Return safe public fields only
- [ ] Avoid N+1 requests
- [ ] Test empty menu
- [ ] Test sold-out items

---

# 38. RPC — `create_restaurant`

If self-service SaaS onboarding is MVP:

- [ ] Use current `auth.uid()`
- [ ] Create restaurant
- [ ] Create restaurant settings
- [ ] Create owner membership
- [ ] Create initial branch
- [ ] Transactional
- [ ] Audit
- [ ] Do not trust owner ID from client

---

# 39. RPC — `create_order`

This is critical.

- [ ] Accept branch ID
- [ ] Accept table ID
- [ ] Accept order type
- [ ] Accept idempotency key
- [ ] Accept items
- [ ] Accept product IDs
- [ ] Accept quantities
- [ ] Accept modifier IDs
- [ ] Accept notes
- [ ] Validate authenticated customer
- [ ] Validate branch
- [ ] Validate table belongs to branch
- [ ] Validate order type enabled
- [ ] Validate restaurant active
- [ ] Validate branch active
- [ ] Validate products belong to branch
- [ ] Validate product active
- [ ] Validate product available
- [ ] Fetch server-side prices
- [ ] Validate modifier groups
- [ ] Validate modifier belongs to attached group
- [ ] Validate required modifier groups
- [ ] Validate min/max selections
- [ ] Fetch modifier prices
- [ ] Calculate subtotal
- [ ] Calculate tax
- [ ] Calculate service charge
- [ ] Calculate discount
- [ ] Calculate total
- [ ] Create order
- [ ] Create order snapshots
- [ ] Create modifier snapshots
- [ ] Create initial status history
- [ ] Handle idempotency
- [ ] Return final server totals
- [ ] Transaction rollback on any failure

---

# 40. RPC — `change_order_status`

- [ ] Accept order ID
- [ ] Accept target status
- [ ] Accept optional reason
- [ ] Validate staff user
- [ ] Validate branch access
- [ ] Validate role
- [ ] Load current status
- [ ] Validate legal transition
- [ ] Update order
- [ ] Insert status history
- [ ] Set completion/cancel timestamps
- [ ] Add audit if needed
- [ ] Return updated order

---

# 41. RPC — `confirm_cash_payment`

- [ ] Validate order
- [ ] Validate branch
- [ ] Validate cashier/manager permission
- [ ] Validate amount
- [ ] Create/update payment
- [ ] Prevent duplicate confirmation
- [ ] Audit
- [ ] Return payment state

---

# 42. RPC — `rotate_table_qr`

- [ ] Validate table
- [ ] Validate branch access
- [ ] Validate permission
- [ ] Generate new random token
- [ ] Save new token
- [ ] Audit
- [ ] Return new token
- [ ] Old QR no longer resolves

---

# 43. RPC — Dashboard Summary

- [ ] `get_dashboard_summary`
- [ ] Validate branch access
- [ ] Today's order count
- [ ] Today's sales
- [ ] Active order count
- [ ] Average order value
- [ ] Status breakdown
- [ ] Top products
- [ ] Fast enough for mobile

---

# 44. Realtime Setup

Enable Realtime for:

- [ ] `orders`
- [ ] `order_status_history`

Optional:

- [ ] `order_items`

Do not enable everything.

---

# 45. Realtime Security Tests

- [ ] Customer receives own order
- [ ] Customer cannot receive other customer order
- [ ] Staff receives own branch orders
- [ ] Staff cannot receive another branch if unauthorized
- [ ] Restaurant A cannot receive Restaurant B
- [ ] Logout stops subscriptions
- [ ] Branch switch stops old subscriptions

---

# 46. Edge Function — `create-payment`

- [ ] Authenticate caller
- [ ] Accept order ID
- [ ] Load order server-side
- [ ] Verify customer ownership
- [ ] Verify order payable
- [ ] Verify amount server-side
- [ ] Create provider order/session
- [ ] Store provider order ID
- [ ] Return safe checkout data
- [ ] Prevent duplicate active payment session

---

# 47. Edge Function — `payment-webhook`

- [ ] Accept provider webhook
- [ ] Read raw payload
- [ ] Verify signature
- [ ] Reject invalid signature
- [ ] Check event ID
- [ ] Enforce webhook idempotency
- [ ] Find payment
- [ ] Validate provider IDs
- [ ] Validate amount
- [ ] Validate currency
- [ ] Mark payment paid/failed
- [ ] Update order state
- [ ] Insert order status history
- [ ] Record webhook event
- [ ] Log errors safely

---

# 48. Edge Function — Refund

Recommended if refund is MVP:

- [ ] Authenticate admin
- [ ] Validate role
- [ ] Validate branch/payment
- [ ] Validate refundable amount
- [ ] Call provider
- [ ] Record refund
- [ ] Update payment state
- [ ] Audit
- [ ] Handle duplicate requests

---

# 49. Push Notification Backend

- [ ] Store device tokens
- [ ] Send new-order push to merchant
- [ ] Send order-ready push to customer
- [ ] Handle invalid push token
- [ ] Deep-link notification to order
- [ ] Do not make notification failure invalidate order

---

# 50. Customer App — Project Skeleton

- [ ] Create route constants
- [ ] Create AppPages
- [ ] Create InitialBinding
- [ ] Create app theme
- [ ] Create error types
- [ ] Create formatters
- [ ] Create shared widgets
- [ ] Add Supabase initialization

---

# 51. Customer App — Global Services

- [ ] `SessionService`
- [ ] `RestaurantContextService`
- [ ] `DeepLinkService`
- [ ] `ConnectivityService`
- [ ] `LocalCartService`
- [ ] `AppLifecycleService`
- [ ] `NotificationService`
- [ ] `AnalyticsService`

---

# 52. Customer App — Anonymous Auth

- [ ] Check session at startup
- [ ] Sign in anonymously if no session
- [ ] Persist auth automatically through Supabase SDK
- [ ] Handle session expiry
- [ ] Test app restart
- [ ] Test logout/re-auth if supported

---

# 53. Customer App — Splash

- [ ] Splash page
- [ ] Startup controller
- [ ] Check auth
- [ ] Check initial deep link
- [ ] Check saved context
- [ ] Check active order
- [ ] Route correctly

---

# 54. Customer App — Deep Links

- [ ] Configure Android app links
- [ ] Configure iOS universal links
- [ ] Configure web fallback
- [ ] Parse `/q/<token>`
- [ ] Handle cold start
- [ ] Handle warm app
- [ ] Handle invalid path
- [ ] Handle order notification deep link

---

# 55. Customer App — QR Scanner

- [ ] Camera permission
- [ ] Scanner page
- [ ] QR parse
- [ ] Debounce duplicate scans
- [ ] Extract token
- [ ] Call `resolve_qr`
- [ ] Invalid QR UX
- [ ] Disabled table UX
- [ ] Network error UX

---

# 56. Customer App — Restaurant Context

- [ ] Save restaurant ID
- [ ] Save branch ID
- [ ] Save table ID
- [ ] Save restaurant name
- [ ] Save branch name
- [ ] Save table name
- [ ] Save currency
- [ ] Persist locally
- [ ] Clear stale context
- [ ] Handle switching restaurant

---

# 57. Customer App — Context Switch

- [ ] Detect cart from another branch
- [ ] Show confirmation
- [ ] Clear cart on confirmed switch
- [ ] Replace context
- [ ] Load new menu

---

# 58. Customer App — Menu Models

- [ ] `RestaurantMenu`
- [ ] `Category`
- [ ] `Product`
- [ ] `ModifierGroup`
- [ ] `Modifier`
- [ ] JSON parsing
- [ ] Null safety
- [ ] Money in integer minor units

---

# 59. Customer App — Menu Repository

- [ ] `getMenu(branchId)`
- [ ] Call public menu RPC
- [ ] Map response
- [ ] Map backend errors
- [ ] Add refresh support
- [ ] Add local cache optional

---

# 60. Customer App — Menu Screen

- [ ] Restaurant header
- [ ] Table indicator
- [ ] Category tabs
- [ ] Product list
- [ ] Search
- [ ] Loading state
- [ ] Empty state
- [ ] Error state
- [ ] Pull to refresh
- [ ] Cart badge
- [ ] Floating cart bar
- [ ] Sold-out UI

---

# 61. Customer App — Search

- [ ] Search query state
- [ ] Product name match
- [ ] Product description match
- [ ] Empty search result state
- [ ] Clear search

---

# 62. Customer App — Product Detail

- [ ] Product image
- [ ] Product name
- [ ] Description
- [ ] Base price
- [ ] Modifier groups
- [ ] Quantity selector
- [ ] Item note
- [ ] Add-to-cart button
- [ ] Price preview

---

# 63. Customer App — Modifier Selection

- [ ] Required group UI
- [ ] Single-select group
- [ ] Multi-select group
- [ ] Min validation
- [ ] Max validation
- [ ] Price delta UI
- [ ] Sold-out modifier UI
- [ ] Error message
- [ ] Edit existing cart item

---

# 64. Customer App — Cart

- [ ] `CartItem` model
- [ ] `CartController`
- [ ] Add item
- [ ] Remove item
- [ ] Increase quantity
- [ ] Decrease quantity
- [ ] Merge identical items
- [ ] Keep different modifier selections separate
- [ ] Item notes
- [ ] Preview subtotal
- [ ] Empty cart
- [ ] Persistent cart
- [ ] Context validation

---

# 65. Customer App — Local Cart Persistence

- [ ] Save after change
- [ ] Restore on startup
- [ ] Add storage version
- [ ] Handle corrupted data
- [ ] Handle stale schema
- [ ] Clear on branch change
- [ ] Clear after safe order creation

---

# 66. Customer App — Checkout

- [ ] Checkout page
- [ ] Order type selection
- [ ] Dine-in context
- [ ] Takeaway context
- [ ] Customer name
- [ ] Customer phone if required
- [ ] Order note
- [ ] Payment method selector
- [ ] Price preview
- [ ] Place order button
- [ ] Duplicate tap prevention
- [ ] Connectivity validation

---

# 67. Customer App — Secure Order Submission

- [ ] Generate idempotency key
- [ ] Save idempotency key locally
- [ ] Build ID-only item payload
- [ ] Do not send trusted final price
- [ ] Call `create_order`
- [ ] Render server total
- [ ] Handle unavailable product
- [ ] Handle price change
- [ ] Handle invalid modifier
- [ ] Handle restaurant closed
- [ ] Handle duplicate retry

---

# 68. Customer App — Cash Order

- [ ] Support cash/pay-later if enabled
- [ ] Create order
- [ ] Route directly to tracking
- [ ] Show payment method
- [ ] Clear cart only after success

---

# 69. Customer App — Online Payment

- [ ] `PaymentRepository`
- [ ] `PaymentController`
- [ ] Call `create-payment`
- [ ] Launch gateway
- [ ] Handle success callback
- [ ] Handle failure callback
- [ ] Handle cancel callback
- [ ] Do not mark paid locally
- [ ] Show confirming state
- [ ] Query backend status
- [ ] Route after verified state

---

# 70. Customer App — Payment Recovery

- [ ] Save pending order ID
- [ ] Save pending payment context
- [ ] On startup query order
- [ ] If paid → tracking
- [ ] If awaiting payment → resume
- [ ] If failed → retry
- [ ] Prevent duplicate charge

---

# 71. Customer App — Order Tracking

- [ ] Order tracking page
- [ ] Fetch current order
- [ ] Subscribe to Realtime
- [ ] Show order number
- [ ] Show table/order type
- [ ] Show item summary
- [ ] Show payment
- [ ] Show total
- [ ] Show status timeline
- [ ] Manual refresh
- [ ] Reconnect/refetch

---

# 72. Customer App — Status Labels

Map:

- [ ] Awaiting payment
- [ ] Order received
- [ ] Accepted
- [ ] Preparing
- [ ] Ready
- [ ] Served
- [ ] Completed
- [ ] Cancelled

---

# 73. Customer App — Active Order

- [ ] Save active order ID
- [ ] Restore on restart
- [ ] Show active-order banner on menu
- [ ] Push notification opens correct order
- [ ] Remove from active when completed

---

# 74. Customer App — Order History

- [ ] Orders page
- [ ] Pagination
- [ ] Order cards
- [ ] Order detail
- [ ] Snapshot items
- [ ] Payment state
- [ ] Status history
- [ ] Empty state
- [ ] RLS ownership tested

---

# 75. Customer App — Profile

- [ ] Guest profile state
- [ ] Name
- [ ] Phone
- [ ] Order history shortcut
- [ ] Verify phone later
- [ ] Logout
- [ ] Notification settings optional

---

# 76. Customer App — Push Notifications

- [ ] Ask at meaningful time
- [ ] Save device token
- [ ] Handle token refresh
- [ ] Handle foreground message
- [ ] Handle background tap
- [ ] Deep-link to order
- [ ] Test order-ready notification

---

# 77. Customer App — Offline UX

- [ ] Offline banner
- [ ] Cached menu optional
- [ ] Cart remains editable
- [ ] Checkout disabled offline
- [ ] Tracking refetches on reconnect
- [ ] No duplicate request after reconnect

---

# 78. Customer App — Analytics

Track:

- [ ] App open
- [ ] QR scan
- [ ] QR resolved
- [ ] Menu viewed
- [ ] Product viewed
- [ ] Search used
- [ ] Add to cart
- [ ] Remove from cart
- [ ] Checkout started
- [ ] Order created
- [ ] Payment started
- [ ] Payment success
- [ ] Payment failed
- [ ] Order completed

Do not send sensitive PII.

---

# 79. Admin App — Project Skeleton

- [ ] Routes
- [ ] AppPages
- [ ] InitialBinding
- [ ] Theme
- [ ] Error types
- [ ] Formatters
- [ ] Reusable widgets
- [ ] Supabase init
- [ ] Responsive shell

---

# 80. Admin App — Global Services

- [ ] `AdminSessionService`
- [ ] `MerchantContextService`
- [ ] `ConnectivityService`
- [ ] `RealtimeService`
- [ ] `NotificationService`
- [ ] `AppLifecycleService`
- [ ] `PermissionService`
- [ ] `AnalyticsService`

---

# 81. Admin App — Login

- [ ] Login page
- [ ] Email/password
- [ ] Form validation
- [ ] Loading state
- [ ] Auth error state
- [ ] Forgot password
- [ ] Navigate after login

---

# 82. Admin App — Membership Load

- [ ] Fetch restaurant memberships
- [ ] Filter inactive memberships
- [ ] Handle no membership
- [ ] Handle multiple restaurants
- [ ] Read role
- [ ] Save selected restaurant

---

# 83. Admin App — Restaurant Selection

- [ ] List accessible restaurants
- [ ] Show role
- [ ] Select restaurant
- [ ] Persist last selection
- [ ] Revalidate on startup

---

# 84. Admin App — Branch Selection

- [ ] Fetch allowed branches
- [ ] Owner/manager all-branch logic
- [ ] Staff assignment logic
- [ ] Select branch
- [ ] Persist last branch
- [ ] Revalidate access
- [ ] Clean subscriptions when switching

---

# 85. Admin App — Navigation by Role

- [ ] Owner default dashboard
- [ ] Manager default dashboard
- [ ] Cashier default orders
- [ ] Waiter default orders/tables
- [ ] Kitchen default KDS
- [ ] Client route guards
- [ ] Backend remains authority

---

# 86. Admin App — Dashboard

- [ ] Dashboard page
- [ ] Sales today
- [ ] Orders today
- [ ] Average order value
- [ ] Active orders
- [ ] Status counts
- [ ] Top products
- [ ] Pull to refresh
- [ ] Date range
- [ ] Role-aware cards

---

# 87. Admin App — Categories

- [x] Category list
- [x] Add
- [x] Edit
- [x] Reorder
- [x] Activate/deactivate
- [x] Image optional
- [x] Empty state
- [x] Permission checks

---

# 88. Admin App — Products

- [x] Product list
- [x] Add product
- [x] Edit product
- [x] Archive product
- [x] Sold-out toggle
- [x] Category selection
- [x] Price minor conversion
- [x] Product image
- [x] Modifiers
- [x] Search
- [x] Filter by category

---

# 89. Admin App — Image Upload

- [ ] Image picker
- [ ] Resize/compress
- [ ] Upload progress
- [ ] Storage path convention
- [ ] Save new path
- [ ] Delete old image after success
- [ ] Handle upload failure

---

# 90. Admin App — Modifiers

- [x] Modifier-group list
- [x] Add group
- [x] Edit group
- [x] Required flag
- [x] Min/max validation
- [x] Add modifier
- [x] Edit modifier
- [x] Price delta
- [x] Availability
- [x] Assign group to product

---

# 91. Admin App — Tables

- [x] Table list
- [x] Add table
- [x] Edit table
- [x] Capacity
- [x] Area optional
- [x] Active state
- [x] QR preview
- [x] Share QR
- [x] Rotate QR
- [x] Confirmation dialog

---

# 92. Admin App — QR Visual Generation

- [x] Build QR from resolver URL
- [x] Include table name
- [x] Include restaurant name/logo optional
- [x] Save/share image
- [x] Print support later
- [x] Verify generated QR scans

---

# 93. Admin App — Live Orders

- [ ] Initial active-order query
- [ ] Realtime subscription
- [ ] Tabs/status filters
- [ ] Order cards
- [ ] New order alert
- [ ] Sound
- [ ] Vibration optional
- [ ] Open order detail
- [ ] Reconnect/refetch
- [ ] Branch switching cleanup

---

# 94. Admin App — Order Detail

- [ ] Order number
- [ ] Status
- [ ] Order type
- [ ] Table
- [ ] Customer info by role
- [ ] Item list
- [ ] Modifier snapshots
- [ ] Notes
- [ ] Financial summary
- [ ] Payment state
- [ ] Status history
- [ ] Allowed actions

---

# 95. Admin App — Order Status Actions

- [ ] Accept
- [ ] Start preparing
- [ ] Mark ready
- [ ] Mark served
- [ ] Complete
- [ ] Cancel with reason
- [ ] Use RPC
- [ ] Handle conflict from another device
- [ ] Refresh after conflict

---

# 96. Admin App — KDS

- [ ] Tablet layout
- [ ] New column
- [ ] Preparing column
- [ ] Ready column
- [ ] Large cards
- [ ] Table number
- [ ] Items
- [ ] Modifiers
- [ ] Notes
- [ ] Elapsed time
- [ ] Sound
- [ ] Fullscreen mode
- [ ] Realtime
- [ ] Status action buttons
- [ ] Reconnect behavior

---

# 97. Admin App — Payments

- [ ] Payment list
- [ ] Payment detail
- [ ] Filters
- [ ] Cash/online distinction
- [ ] Pending/paid/failed/refunded
- [ ] Confirm cash payment
- [ ] Permission check
- [ ] Do not directly edit provider payment status

---

# 98. Admin App — Refunds

If MVP:

- [ ] Refund action
- [ ] Permission check
- [ ] Refund amount
- [ ] Refund reason
- [ ] Confirmation
- [ ] Call Edge Function
- [ ] Show result
- [ ] Show refund history

---

# 99. Admin App — Staff

- [ ] Staff list
- [ ] Role display
- [ ] Branch display
- [ ] Invite
- [ ] Change role
- [ ] Assign branches
- [ ] Deactivate
- [ ] Permission restrictions
- [ ] Protect owner role
- [ ] Audit actions

---

# 100. Admin App — Settings

- [ ] Restaurant info
- [ ] Logo
- [ ] Currency
- [ ] Timezone
- [ ] Dine-in toggle
- [ ] Takeaway toggle
- [ ] Delivery disabled/hidden if not MVP
- [ ] Guest ordering toggle
- [ ] Tax
- [ ] Service charge
- [ ] Payment-before-kitchen
- [ ] Branch address
- [ ] Branch phone
- [ ] Opening hours
- [ ] Pause ordering

---

# 101. Admin App — Reports

- [ ] Today
- [ ] Yesterday
- [ ] 7 days
- [ ] 30 days
- [ ] Custom
- [ ] Orders count
- [ ] Gross order value
- [ ] Paid revenue
- [ ] Refund total
- [ ] Average order value
- [ ] Top products
- [ ] Payment split
- [ ] Cancelled orders

---

# 102. Admin App — Push Notifications

- [ ] Save merchant device token
- [ ] Handle new-order push
- [ ] Deep-link to order
- [ ] Handle payment alerts
- [ ] Token refresh
- [ ] Logout cleanup

---

# 103. Admin App — Offline UX

- [ ] Offline banner
- [ ] Disable critical writes offline
- [ ] Keep cached active orders for view only
- [ ] Reconnect
- [ ] Refetch active orders
- [ ] Restore subscriptions

---

# 104. Admin App — Analytics

Track:

- [ ] Login
- [ ] Restaurant select
- [ ] Branch switch
- [ ] Order accepted
- [ ] Order preparing
- [ ] Order ready
- [ ] Product created
- [ ] Price updated
- [ ] Sold-out toggle
- [ ] Staff invited
- [ ] Refund requested
- [ ] QR rotated

---

# 105. Customer App Unit Tests

- [ ] Money formatter
- [ ] Cart preview total
- [ ] Cart merge
- [ ] Modifier validation
- [ ] QR parsing
- [ ] Deep link parsing
- [ ] Error mapping
- [ ] Checkout state
- [ ] Payment state
- [ ] Tracking state

---

# 106. Admin App Unit Tests

- [ ] Role helper
- [ ] Status action mapping
- [ ] Menu validation
- [ ] Product price conversion
- [ ] Modifier min/max validation
- [ ] Date filters
- [ ] Dashboard state
- [ ] Realtime merge logic

---

# 107. Widget Tests — Customer

- [ ] Menu loading
- [ ] Empty menu
- [ ] Sold-out product
- [ ] Required modifier
- [ ] Cart empty
- [ ] Checkout form
- [ ] Payment pending
- [ ] Order tracking

---

# 108. Widget Tests — Admin

- [ ] Login form
- [ ] Dashboard
- [ ] Live order card
- [ ] KDS card
- [ ] Product form
- [ ] Table form
- [ ] Staff list
- [ ] Permission denied UI

---

# 109. Backend Security Tests

Test each identity:

```text
anon
anonymous authenticated customer
verified customer
owner
manager
cashier
waiter
kitchen
user from another restaurant
```

- [ ] Cross-tenant restaurant blocked
- [ ] Cross-branch blocked
- [ ] Other customer order blocked
- [ ] Customer product write blocked
- [ ] Customer payment write blocked
- [ ] Kitchen refund blocked
- [ ] Cashier staff role escalation blocked
- [ ] Manager owner transfer blocked if unauthorized
- [ ] Storage cross-tenant write blocked

---

# 110. `create_order` Tests

- [ ] Valid dine-in
- [ ] Valid takeaway
- [ ] Invalid branch
- [ ] Invalid table
- [ ] Table from another branch
- [ ] Inactive restaurant
- [ ] Inactive branch
- [ ] Inactive product
- [ ] Sold-out product
- [ ] Cross-branch product
- [ ] Quantity zero
- [ ] Negative quantity
- [ ] Excessive quantity
- [ ] Invalid modifier
- [ ] Missing required modifier
- [ ] Too many modifiers
- [ ] Duplicate idempotency request
- [ ] Concurrent duplicate request

---

# 111. Order State Tests

- [ ] placed → accepted
- [ ] accepted → preparing
- [ ] preparing → ready
- [ ] ready → served
- [ ] served → completed
- [ ] invalid reverse transition rejected
- [ ] unauthorized status update rejected
- [ ] concurrent update conflict handled

---

# 112. Payment Tests

- [ ] Create payment
- [ ] Success callback
- [ ] Webhook success
- [ ] Duplicate webhook
- [ ] Invalid signature
- [ ] Wrong amount
- [ ] Wrong currency
- [ ] Payment failed
- [ ] Payment cancelled
- [ ] App closed after payment
- [ ] Retry payment
- [ ] Duplicate charge prevention
- [ ] Refund success
- [ ] Refund failure
- [ ] Duplicate refund

---

# 113. Realtime Tests

- [ ] Customer receives status
- [ ] Merchant receives new order
- [ ] KDS receives update
- [ ] Other restaurant receives nothing
- [ ] Branch switch stops old feed
- [ ] Logout stops feed
- [ ] Reconnect refetch works
- [ ] Multiple merchant devices stay synchronized

---

# 114. Deep Link Tests

- [ ] Cold-start valid QR
- [ ] Warm-app valid QR
- [ ] Invalid QR
- [ ] Disabled table
- [ ] Switch restaurant with empty cart
- [ ] Switch restaurant with nonempty cart
- [ ] Push notification order link
- [ ] Unknown link path

---

# 115. Performance Tests

- [ ] 100 products
- [ ] 500 products
- [ ] 50 categories
- [ ] 100 active orders
- [ ] Multiple KDS devices
- [ ] Menu RPC latency
- [ ] Dashboard RPC latency
- [ ] Order-history pagination
- [ ] Image loading on slow network

---

# 116. Low Network Tests

- [ ] Slow 3G menu
- [ ] Checkout timeout
- [ ] Create-order retry
- [ ] Payment callback delayed
- [ ] Realtime reconnect
- [ ] Image failure
- [ ] Cart remains safe

---

# 117. Device QA

Customer:

- [ ] Small Android
- [ ] Large Android
- [ ] Small iPhone
- [ ] Large iPhone
- [ ] Mobile web

Admin:

- [ ] Android phone
- [ ] Android tablet
- [ ] iPhone
- [ ] iPad
- [ ] Desktop web

---

# 118. Accessibility QA

Customer:

- [ ] Large text
- [ ] Screen reader
- [ ] Tap targets
- [ ] Contrast
- [ ] Status not color-only

Admin:

- [ ] KDS readability
- [ ] Large buttons
- [ ] Sound + visual alerts
- [ ] Status text labels

---

# 119. Logging and Monitoring

- [ ] Flutter crash reporting
- [ ] Edge Function logging
- [ ] Payment webhook logs
- [ ] Safe order IDs in logs
- [ ] Safe restaurant/branch IDs in logs
- [ ] No secrets in logs
- [ ] No OTP/password logs
- [ ] Monitor function failures
- [ ] Monitor database errors

---

# 120. Backup / Recovery

- [ ] Configure production backups
- [ ] Review Supabase backup options
- [ ] Create pre-migration backup procedure
- [ ] Test database restore
- [ ] Document restore process

---

# 121. CI/CD

- [ ] Flutter analyze customer
- [ ] Flutter test customer
- [ ] Flutter analyze merchant
- [ ] Flutter test merchant
- [ ] Validate migrations
- [ ] Run backend tests
- [ ] Deploy staging
- [ ] Run integration tests
- [ ] Manual production approval
- [ ] Deploy production migrations
- [ ] Deploy Edge Functions
- [ ] Build Flutter releases

---

# 122. Staging Checklist

- [ ] Staging Supabase ready
- [ ] Staging payment gateway/test mode
- [ ] Test restaurant seeded
- [ ] Test branch
- [ ] Test products
- [ ] Test QR
- [ ] Test customer app staging build
- [ ] Test merchant app staging build
- [ ] Test realtime
- [ ] Test push
- [ ] Test payment
- [ ] Test refund if included
- [ ] Test roles

---

# 123. Pilot Restaurant Setup

For first restaurant:

- [ ] Create owner account
- [ ] Create restaurant
- [ ] Create branch
- [ ] Configure currency/timezone
- [ ] Configure tax
- [ ] Configure service charge
- [ ] Add categories
- [ ] Add products
- [ ] Add modifiers
- [ ] Upload images
- [ ] Create tables
- [ ] Print QR codes
- [ ] Add staff
- [ ] Assign roles
- [ ] Set branch opening hours
- [ ] Configure payments
- [ ] Register merchant devices
- [ ] Configure KDS tablet

---

# 124. Pilot Dry Run

Run full tests:

- [ ] Customer scans QR
- [ ] Menu opens
- [ ] Adds item
- [ ] Modifiers work
- [ ] Cart works
- [ ] Checkout works
- [ ] Cash order reaches KDS
- [ ] Accept works
- [ ] Preparing works
- [ ] Ready works
- [ ] Customer tracking works
- [ ] Complete works
- [ ] Online payment works
- [ ] Payment webhook works
- [ ] Push works
- [ ] Sold-out toggle works
- [ ] Price update works
- [ ] QR rotation works
- [ ] Role restrictions work

---

# 125. Pilot Edge Cases

- [ ] Customer double-taps order
- [ ] Customer closes app during checkout
- [ ] Customer closes app during payment
- [ ] Kitchen internet drops
- [ ] Merchant app restarts
- [ ] Same order opened on two devices
- [ ] Product sold out after cart
- [ ] Price changed after cart
- [ ] Payment provider callback delayed
- [ ] Duplicate webhook
- [ ] Staff access removed during session
- [ ] Branch paused while customer is ordering

---

# 126. Production Launch Checklist

Backend:

- [ ] Production migrations applied
- [ ] RLS verified
- [ ] Grants verified
- [ ] Secrets set
- [ ] Payment webhook URL configured
- [ ] Storage policies verified
- [ ] Realtime enabled
- [ ] Backups enabled
- [ ] Logs monitored

Customer:

- [ ] Production URL/key
- [ ] Deep links verified
- [ ] Push production config
- [ ] Payment production key/public config
- [ ] Crash reporting
- [ ] Release signing
- [ ] Store build/web deployment

Admin:

- [ ] Production URL/key
- [ ] Push config
- [ ] Crash reporting
- [ ] Release signing
- [ ] Tablet tested
- [ ] Web deployment if applicable

---

# 127. Go-Live Definition of Done

The MVP is production-ready when:

```text
[ ] Restaurant owner can log in
[ ] Restaurant membership works
[ ] Branch access works
[ ] Owner can create menu
[ ] Owner can create tables
[ ] QR resolves correctly
[ ] Customer scans without signup friction
[ ] Customer can browse menu
[ ] Customer can choose modifiers
[ ] Customer cart persists
[ ] Customer can place order
[ ] Backend calculates final total
[ ] Duplicate checkout cannot create duplicate order
[ ] Merchant receives live order
[ ] KDS works
[ ] Staff can change valid status
[ ] Invalid status change is blocked
[ ] Customer sees realtime status
[ ] Cash payment can be confirmed
[ ] Online payment is webhook verified
[ ] Cross-tenant access is blocked
[ ] Other customer orders are private
[ ] Merchant secrets are not in Flutter
[ ] Push notifications work
[ ] Order history works
[ ] Production backups exist
[ ] Pilot restaurant completes real test orders
```

---

# 128. Priority Legend

Use:

```text
P0 = required before any pilot
P1 = required before production launch
P2 = useful immediately after launch
P3 = future
```

---

# 129. P0 — Must Build First

Backend:

- [ ] Core schema
- [ ] RLS
- [ ] Grants
- [ ] resolve_qr
- [ ] get_public_menu
- [ ] create_order
- [ ] change_order_status
- [ ] Realtime
- [ ] Storage menu images

Customer:

- [ ] Anonymous auth
- [ ] QR/deep link
- [ ] Menu
- [ ] Product/modifiers
- [ ] Cart
- [ ] Checkout
- [ ] Cash order
- [ ] Tracking

Admin:

- [ ] Login
- [ ] Membership
- [ ] Branch
- [ ] Categories
- [ ] Products
- [ ] Modifiers
- [ ] Tables
- [ ] QR
- [ ] Live orders
- [ ] KDS
- [ ] Status changes

---

# 130. P1 — Before Public Production

- [ ] Online payments
- [ ] Payment webhook
- [ ] Payment recovery
- [ ] Push notifications
- [ ] Staff management
- [ ] Dashboard
- [ ] Order history
- [ ] Cash confirmation
- [ ] Opening hours
- [ ] Branch pause
- [ ] Audit logs
- [ ] Crash reporting
- [ ] Staging environment
- [ ] CI/CD
- [ ] Backups
- [ ] Production monitoring
- [ ] Security tests

---

# 131. P2 — Immediately After MVP

- [ ] Coupons
- [ ] Customer phone verification
- [ ] Basic loyalty
- [ ] Refund UI
- [ ] Advanced reports
- [ ] Dining areas
- [ ] Product tags
- [ ] Restaurant info screen
- [ ] Customer feedback
- [ ] CSV exports
- [ ] Better push preferences

---

# 132. P3 — Future

- [ ] Delivery
- [ ] Reservations
- [ ] Inventory
- [ ] Recipe costing
- [ ] CRM
- [ ] Supplier management
- [ ] Purchase orders
- [ ] AI waiter
- [ ] Recommendations
- [ ] Multi-language AI
- [ ] Franchise controls
- [ ] Offline POS
- [ ] Driver tracking
- [ ] Group ordering

---

# 133. Suggested Sprint Breakdown

## Sprint 1 — Backend Foundation

- [ ] Supabase projects
- [ ] Migrations
- [ ] Restaurants
- [ ] Branches
- [ ] Membership
- [ ] RLS
- [ ] Categories
- [ ] Products
- [ ] Modifiers

## Sprint 2 — Admin Menu

- [ ] Admin auth
- [ ] Restaurant/branch selection
- [ ] Categories
- [ ] Products
- [ ] Modifiers
- [ ] Images

## Sprint 3 — QR + Customer Menu

- [ ] Tables
- [ ] QR generation
- [ ] resolve_qr
- [ ] Anonymous auth
- [ ] Customer QR scanner
- [ ] Customer menu

## Sprint 4 — Cart + Checkout

- [ ] Product detail
- [ ] Modifier validation
- [ ] Cart
- [ ] Local persistence
- [ ] Checkout
- [ ] create_order

## Sprint 5 — Orders + KDS

- [ ] Live orders
- [ ] Realtime
- [ ] Order detail
- [ ] Status RPC
- [ ] KDS
- [ ] Customer tracking

## Sprint 6 — Payments

- [ ] Payment schema
- [ ] create-payment
- [ ] Gateway SDK
- [ ] Webhook
- [ ] Recovery
- [ ] Cash confirmation

## Sprint 7 — Staff + Dashboard

- [ ] Staff roles
- [ ] Branch assignment
- [ ] Dashboard
- [ ] Order history
- [ ] Reports

## Sprint 8 — Production Hardening

- [ ] Push
- [ ] Audit
- [ ] Security tests
- [ ] Low-network tests
- [ ] CI/CD
- [ ] Staging
- [ ] Pilot

---

# 134. Dependency Map

```text
AUTH
 ↓
RESTAURANT MEMBERSHIP
 ↓
BRANCH
 ↓
MENU
 ↓
TABLE + QR
 ↓
CUSTOMER MENU
 ↓
CART
 ↓
CREATE ORDER
 ↓
REALTIME
 ↓
KDS
 ↓
PAYMENTS
 ↓
REPORTS / STAFF / HARDENING
```

---

# 135. Critical Path

Do not block the project by starting with noncritical features.

Build:

```text
Restaurant
 ↓
Branch
 ↓
Menu
 ↓
Table
 ↓
QR
 ↓
Customer Menu
 ↓
Cart
 ↓
Order
 ↓
KDS
 ↓
Tracking
```

before:

```text
CRM
AI
Inventory
Loyalty
Reservations
```

---

# 136. Release 0.1 — Internal Demo

Must support:

```text
Admin creates menu
Admin creates table
Customer scans
Customer places cash order
Admin sees order
Admin updates status
Customer sees status
```

---

# 137. Release 0.2 — Restaurant Pilot

Add:

```text
online payment
staff roles
push
order history
dashboard
opening hours
basic reports
```

---

# 138. Release 1.0 — Public MVP

Must have:

```text
security audit
RLS tests
payment recovery
crash monitoring
backups
production CI/CD
pilot evidence
operational docs
```

---

# 139. Operational Documentation

Before launch create:

- [ ] Restaurant onboarding guide
- [ ] Staff login guide
- [ ] KDS guide
- [ ] QR printing guide
- [ ] Payment troubleshooting guide
- [ ] Refund guide
- [ ] Branch pause guide
- [ ] Incident response guide
- [ ] Backup restore guide
- [ ] Support checklist

---

# 140. Incident Scenarios

Document response for:

- [ ] Supabase outage
- [ ] Payment gateway outage
- [ ] Realtime disconnect
- [ ] Push outage
- [ ] Wrong price configured
- [ ] Duplicate payment
- [ ] QR leaked
- [ ] Staff account compromised
- [ ] Restaurant accidentally paused
- [ ] Product accidentally archived

---

# 141. Security Incident Actions

Must support:

- [ ] Deactivate staff
- [ ] Rotate table QR
- [ ] Revoke sessions if required
- [ ] Rotate server secrets
- [ ] Disable payment gateway temporarily
- [ ] Pause restaurant
- [ ] Review audit log

---

# 142. Final Development Rule

Do not mark a feature complete because:

```text
UI works
```

A feature is complete only when:

```text
UI works
+
backend validates
+
RLS protects
+
error states work
+
tests pass
+
reconnect/retry is safe
```

---

# 143. Final MVP Success Flow

```text
OWNER
 ↓
creates restaurant
 ↓
creates branch
 ↓
creates categories/products/modifiers
 ↓
creates table
 ↓
prints QR

CUSTOMER
 ↓
scans QR
 ↓
sees menu
 ↓
selects product/modifiers
 ↓
adds to cart
 ↓
checks out
 ↓
backend validates order
 ↓
pays / chooses cash
 ↓
order placed

MERCHANT
 ↓
receives realtime order
 ↓
accepts
 ↓
prepares
 ↓
marks ready
 ↓
serves/completes

CUSTOMER
 ↓
sees realtime updates
 ↓
order complete
```

---

# 144. Final MVP Checklist

## Backend

- [ ] Schema complete
- [ ] RLS complete
- [ ] Grants complete
- [ ] Auth complete
- [ ] Storage complete
- [ ] Core RPCs complete
- [ ] Realtime complete
- [ ] Payments complete
- [ ] Webhook complete
- [ ] Indexes complete
- [ ] Audit complete
- [ ] Tests complete

## Customer App

- [ ] Auth
- [ ] QR
- [ ] Deep links
- [ ] Menu
- [ ] Products
- [ ] Modifiers
- [ ] Cart
- [ ] Checkout
- [ ] Payment
- [ ] Tracking
- [ ] History
- [ ] Push
- [ ] Offline/reconnect
- [ ] Tests

## Admin App

- [ ] Login
- [ ] Restaurant select
- [ ] Branch select
- [ ] Dashboard
- [ ] Menu CRUD
- [ ] Modifiers
- [ ] Tables
- [ ] QR
- [ ] Live orders
- [ ] KDS
- [ ] Status changes
- [ ] Payments
- [ ] Staff
- [ ] Reports
- [ ] Settings
- [ ] Push
- [ ] Tests

## Production

- [ ] Staging passed
- [ ] Pilot passed
- [ ] Security passed
- [ ] Payment recovery passed
- [ ] Backups configured
- [ ] Monitoring configured
- [ ] CI/CD configured
- [ ] Support docs ready
- [ ] Production credentials correct

---

# 145. Definition of MVP Complete

The MVP is complete only when a real restaurant can use it for a real service period and the full workflow works repeatedly:

```text
Customer:
Scan → Order → Pay → Track

Restaurant:
Receive → Prepare → Ready → Complete

System:
Validate → Secure → Synchronize → Record
```

with:

```text
no cross-tenant data leak
no client-controlled price
no client-controlled payment truth
no duplicate order on retry
no duplicate payment on retry
no broken order after network failure
```

That is the minimum production standard for this project.
