# API_CONTRACTS.md
## QR Restaurant Ordering Platform
### Customer App + Admin/Merchant App + Supabase
### Authoritative API / RPC / Edge Function / Realtime Contract
### Flutter + GetX + MVC + Supabase
### For Codex, Cursor, Claude Code, Copilot, and Human Developers

> This document is the **authoritative contract between the Flutter applications and the Supabase backend**.
>
> It should be treated as the source of truth for:
>
> - Supabase RPC names
> - RPC parameters
> - request JSON
> - response JSON
> - common DTO shapes
> - domain error codes
> - Edge Function endpoints
> - payment contracts
> - Realtime event shapes
> - pagination/filtering
> - idempotency
> - enum values
> - money and timestamp rules
> - client/server trust boundaries
>
> Use together with:
>
> - `DATABASE_SCHEMA.sql`
> - `Supabase_Backend_Specification_QR_Restaurant_Project.md`
> - `CUSTOMER_APP_FLOW.md`
> - `ADMIN_APP_FLOW.md`
> - `CUSTOMER_SCREEN_SPEC.md`
> - `ADMIN_SCREEN_SPEC.md`
> - `APP_DESIGN_SYSTEM_AND_UI_SPEC.md`
> - `MVP_TASK_LIST.md`
>
> If code and this document disagree, stop implementation and resolve the contract before continuing.

---

# 1. Contract Version

Initial API contract:

```text
API Contract Version: 1.0.0
```

The app should not invent different payloads for the same operation.

Breaking API changes require:

```text
major version change
or
backward-compatible server deployment first
```

---

# 2. Backend Architecture

```text
Flutter
   │
   ├── Supabase Auth
   │
   ├── Supabase Data API
   │
   ├── PostgreSQL RPC
   │
   ├── Supabase Realtime
   │
   ├── Supabase Storage
   │
   └── Edge Functions
           │
           └── external providers
```

Trusted business operations should follow:

```text
Flutter
 ↓
Repository
 ↓
RPC / Edge Function
 ↓
PostgreSQL
```

---

# 3. API Trust Boundary

The Flutter apps are untrusted clients.

Never trust client-provided:

```text
product price
modifier price
subtotal
tax
service charge
discount
delivery fee
total
payment success
staff role
tenant ownership
table ownership
branch ownership
legal order transition
refund eligibility
coupon validity
```

The backend must calculate or validate these values.

---

# 4. Authentication Contract

## Customer

Recommended:

```text
Supabase anonymous authenticated session
```

The client should have an `auth.uid()` before private order operations.

## Merchant/Admin

Recommended MVP:

```text
Supabase email/password
```

Authorization is derived from:

```text
restaurant_members
branch_members
```

Never from user-editable Auth metadata.

---

# 5. Authorization Header

Supabase SDK handles authenticated requests.

Conceptually:

```http
Authorization: Bearer <user_access_token>
```

Never include:

```text
service_role key
secret key
payment secret
webhook secret
```

in Flutter.

---

# 6. Data Types

## UUID

JSON:

```json
"0190d237-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Dart:

```text
String
```

unless a UUID value object is introduced.

## Money

All business money values:

```text
integer minor units
```

Example:

```json
{
  "amount_minor": 19950,
  "currency_code": "INR"
}
```

means:

```text
₹199.50
```

Never transmit business totals as floating-point values.

## Percentage

Use basis points where applicable.

```text
10000 = 100%
1800  = 18%
500   = 5%
```

## Timestamp

ISO-8601 UTC/timestamptz string:

```json
"2026-09-12T13:15:42.123456+00:00"
```

Flutter converts to local display timezone.

## Date

If date-only is needed:

```json
"2026-09-12"
```

## Time

If time-only is needed:

```json
"10:30:00"
```

---

# 7. Enum Contract

## staff_role

```text
owner
manager
cashier
waiter
kitchen
```

## order_type

```text
dine_in
takeaway
delivery
```

## order_status

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

## payment_status

```text
pending
authorized
paid
failed
cancelled
partially_refunded
refunded
```

## payment_method

```text
cash
card
upi
wallet
online
```

## refund_status

```text
pending
processing
succeeded
failed
cancelled
```

## discount_type

```text
fixed
percentage
```

## app_client_type

```text
customer
merchant
```

---

# 8. Standard Domain Result Envelope

Trusted RPCs should preferably return a JSON object using this structure.

## Success

```json
{
  "ok": true,
  "data": {},
  "error": null
}
```

## Domain Failure

```json
{
  "ok": false,
  "data": null,
  "error": {
    "code": "PRODUCT_UNAVAILABLE",
    "message": "One or more products are unavailable.",
    "details": {}
  }
}
```

`details` may be omitted or `{}`.

---

# 9. Unexpected Backend Failure

Unexpected SQL/database/runtime failures may still surface as a Supabase/PostgREST or Edge Function transport error.

The repository must convert those to:

```text
ServerError
NetworkError
UnauthorizedError
UnknownError
```

Do not show raw SQL messages to users.

---

# 10. Standard Domain Error Object

```json
{
  "code": "ERROR_CODE",
  "message": "Safe user/developer-facing summary.",
  "details": {
    "field": "optional structured information"
  }
}
```

`message` must not expose:

```text
SQL
RLS implementation
stack traces
secret values
gateway secrets
```

---

# 11. Global Error Codes

## Authentication / Session

```text
UNAUTHENTICATED
SESSION_EXPIRED
AUTH_REQUIRED
```

## Authorization

```text
FORBIDDEN
RESTAURANT_ACCESS_DENIED
BRANCH_ACCESS_DENIED
ROLE_PERMISSION_DENIED
MEMBERSHIP_INACTIVE
```

## Resource

```text
NOT_FOUND
RESTAURANT_NOT_FOUND
BRANCH_NOT_FOUND
TABLE_NOT_FOUND
PRODUCT_NOT_FOUND
ORDER_NOT_FOUND
PAYMENT_NOT_FOUND
```

## Restaurant / Ordering

```text
RESTAURANT_INACTIVE
BRANCH_INACTIVE
ORDERING_PAUSED
RESTAURANT_CLOSED
ORDER_TYPE_DISABLED
TABLE_INACTIVE
TABLE_BRANCH_MISMATCH
```

## Menu

```text
PRODUCT_INACTIVE
PRODUCT_UNAVAILABLE
PRODUCT_BRANCH_MISMATCH
INVALID_QUANTITY
INVALID_MODIFIER
MODIFIER_UNAVAILABLE
MODIFIER_NOT_ALLOWED
MODIFIER_SELECTION_REQUIRED
MODIFIER_SELECTION_TOO_FEW
MODIFIER_SELECTION_TOO_MANY
```

## Checkout / Order

```text
EMPTY_ORDER
INVALID_ORDER
INVALID_ORDER_TYPE
INVALID_IDEMPOTENCY_KEY
ORDER_ALREADY_EXISTS
INVALID_STATUS_TRANSITION
ORDER_ALREADY_COMPLETED
ORDER_ALREADY_CANCELLED
ORDER_NOT_CANCELLABLE
```

## Coupon

```text
COUPON_INVALID
COUPON_INACTIVE
COUPON_NOT_STARTED
COUPON_EXPIRED
COUPON_MINIMUM_NOT_MET
COUPON_USAGE_LIMIT_REACHED
```

## Payment

```text
PAYMENT_REQUIRED
PAYMENT_NOT_REQUIRED
PAYMENT_ALREADY_PAID
PAYMENT_ALREADY_IN_PROGRESS
PAYMENT_FAILED
PAYMENT_CANCELLED
PAYMENT_AMOUNT_MISMATCH
PAYMENT_CURRENCY_MISMATCH
PAYMENT_NOT_REFUNDABLE
REFUND_AMOUNT_INVALID
REFUND_LIMIT_EXCEEDED
REFUND_ALREADY_PROCESSED
```

## Staff / Invitation

```text
INVITATION_NOT_FOUND
INVITATION_EXPIRED
INVITATION_REVOKED
INVITATION_ALREADY_ACCEPTED
MEMBER_ALREADY_EXISTS
OWNER_ROLE_PROTECTED
```

## QR

```text
INVALID_QR
QR_NOT_FOUND
QR_TABLE_INACTIVE
```

## Conflict

```text
CONFLICT
RESOURCE_CHANGED
CONCURRENT_UPDATE
```

## Rate / Abuse

```text
RATE_LIMITED
TOO_MANY_REQUESTS
```

---

# 12. Client Error Mapping

Example Dart domain mapping:

```text
PRODUCT_UNAVAILABLE
→ ProductUnavailableException

INVALID_STATUS_TRANSITION
→ OrderStatusConflictException

FORBIDDEN
→ PermissionDeniedException

PAYMENT_ALREADY_PAID
→ PaymentAlreadyPaidException
```

UI must map domain errors to screen-safe copy.

---

# 13. Direct Table API Policy

Not every operation requires RPC.

Direct Supabase Data API may be used where:

```text
operation is simple CRUD
RLS is sufficient
no multi-table transaction is required
no external secret is involved
no authoritative financial calculation is involved
```

Examples:

```text
profile read/update
category CRUD
product CRUD
modifier CRUD
table metadata CRUD
opening-hours CRUD
```

Critical operations should use RPC/Edge Functions.

---

# 14. Critical Operations Requiring RPC / Edge Function

```text
resolve QR
create restaurant
create order
change order status
cancel order
confirm cash payment
rotate QR
staff invitation acceptance
owner transfer
online payment creation
payment webhook
refund
dashboard/report aggregation
```

---

# 15. DTO — Profile

```json
{
  "id": "uuid",
  "full_name": "Rahul Kumar",
  "phone": "+919876543210",
  "avatar_path": "avatars/uuid/avatar.webp",
  "created_at": "2026-09-12T10:00:00+00:00",
  "updated_at": "2026-09-12T10:00:00+00:00"
}
```

Nullable:

```text
full_name
phone
avatar_path
```

---

# 16. DTO — RestaurantSummary

```json
{
  "id": "uuid",
  "name": "Pizza House",
  "slug": "pizza-house",
  "logo_path": "restaurant-assets/uuid/logo.webp",
  "currency_code": "INR",
  "timezone": "Asia/Kolkata",
  "is_active": true
}
```

---

# 17. DTO — BranchSummary

```json
{
  "id": "uuid",
  "restaurant_id": "uuid",
  "name": "Patna Main",
  "code": "PATNA-MAIN",
  "phone": "+919876543210",
  "city": "Patna",
  "state": "Bihar",
  "country_code": "IN",
  "is_active": true,
  "menu_version": 12
}
```

---

# 18. DTO — DiningTableSummary

```json
{
  "id": "uuid",
  "branch_id": "uuid",
  "name": "Table 12",
  "capacity": 4,
  "is_active": true
}
```

Never expose QR rotation/internal fields in normal customer menu responses unless required.

---

# 19. DTO — Category

```json
{
  "id": "uuid",
  "name": "Pizza",
  "description": "Freshly baked pizzas",
  "image_path": "menu-images/...",
  "sort_order": 10
}
```

Public menu omits inactive categories.

---

# 20. DTO — Modifier

```json
{
  "id": "uuid",
  "name": "Large",
  "price_delta_minor": 10000,
  "sort_order": 20,
  "is_available": true
}
```

---

# 21. DTO — ModifierGroup

```json
{
  "id": "uuid",
  "name": "Size",
  "min_select": 1,
  "max_select": 1,
  "is_required": true,
  "sort_order": 10,
  "modifiers": [
    {
      "id": "uuid",
      "name": "Medium",
      "price_delta_minor": 0,
      "sort_order": 10,
      "is_available": true
    },
    {
      "id": "uuid",
      "name": "Large",
      "price_delta_minor": 10000,
      "sort_order": 20,
      "is_available": true
    }
  ]
}
```

---

# 22. DTO — Product

```json
{
  "id": "uuid",
  "category_id": "uuid",
  "name": "Farmhouse Pizza",
  "description": "Capsicum, onion, tomato and cheese",
  "base_price_minor": 39900,
  "image_path": "menu-images/restaurant/branch/products/uuid/main.webp",
  "is_veg": true,
  "is_available": true,
  "sort_order": 10,
  "preparation_minutes": 15,
  "tags": [
    "popular",
    "vegetarian"
  ],
  "modifier_groups": []
}
```

Public DTO must not contain:

```text
cost price
profit margin
supplier
internal stock data
staff notes
```

---

# 23. DTO — MoneySummary

```json
{
  "currency_code": "INR",
  "subtotal_minor": 85000,
  "tax_minor": 4250,
  "service_charge_minor": 0,
  "delivery_fee_minor": 0,
  "discount_minor": 5000,
  "total_minor": 84250
}
```

---

# 24. DTO — OrderItemSnapshot

```json
{
  "id": "uuid",
  "product_id": "uuid",
  "product_name": "Farmhouse Pizza",
  "unit_price_minor": 39900,
  "quantity": 2,
  "modifiers_total_minor": 4000,
  "line_total_minor": 83800,
  "item_note": "No onion",
  "modifiers": [
    {
      "id": "uuid",
      "modifier_id": "uuid",
      "modifier_name": "Extra Cheese",
      "price_delta_minor": 2000
    }
  ]
}
```

---

# 25. DTO — OrderSummary

```json
{
  "id": "uuid",
  "order_number": 1042,
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "table_id": "uuid",
  "order_type": "dine_in",
  "status": "preparing",
  "currency_code": "INR",
  "subtotal_minor": 85000,
  "tax_minor": 4250,
  "service_charge_minor": 0,
  "delivery_fee_minor": 0,
  "discount_minor": 0,
  "total_minor": 89250,
  "placed_at": "2026-09-12T12:30:00+00:00",
  "completed_at": null,
  "cancelled_at": null,
  "created_at": "2026-09-12T12:30:00+00:00",
  "updated_at": "2026-09-12T12:37:00+00:00"
}
```

---

# 26. DTO — OrderStatusEvent

```json
{
  "id": "uuid",
  "order_id": "uuid",
  "old_status": "accepted",
  "new_status": "preparing",
  "changed_by": "uuid",
  "reason": null,
  "created_at": "2026-09-12T12:37:00+00:00"
}
```

Customer-safe DTO may omit `changed_by`.

---

# 27. DTO — PaymentSummary

```json
{
  "id": "uuid",
  "order_id": "uuid",
  "method": "online",
  "provider": "provider_name",
  "amount_minor": 89250,
  "currency_code": "INR",
  "status": "paid",
  "paid_at": "2026-09-12T12:31:00+00:00",
  "refunded_at": null
}
```

Do not return:

```text
provider secret
signature secret
full provider_metadata unless explicitly safe
```

---

# 28. DTO — RefundSummary

```json
{
  "id": "uuid",
  "payment_id": "uuid",
  "amount_minor": 30000,
  "reason": "Item unavailable",
  "status": "succeeded",
  "created_at": "2026-09-12T13:00:00+00:00",
  "updated_at": "2026-09-12T13:01:00+00:00"
}
```

---

# 29. DTO — RestaurantMembership

```json
{
  "restaurant_id": "uuid",
  "restaurant_name": "Pizza House",
  "restaurant_logo_path": "restaurant-assets/...",
  "role": "owner",
  "is_active": true
}
```

---

# 30. DTO — BranchAccess

```json
{
  "branch_id": "uuid",
  "branch_name": "Patna Main",
  "restaurant_id": "uuid",
  "is_active": true
}
```

---

# 31. RPC — `resolve_qr`

## Purpose

Resolve an opaque table QR token into safe customer ordering context.

## Auth

Recommended:

```text
authenticated
```

including anonymous Supabase customer sessions.

## Flutter Call

Conceptually:

```dart
supabase.rpc(
  'resolve_qr',
  params: {
    'p_qr_token': token,
  },
);
```

## Parameters

```json
{
  "p_qr_token": "uuid"
}
```

## Success

```json
{
  "ok": true,
  "data": {
    "restaurant": {
      "id": "uuid",
      "name": "Pizza House",
      "slug": "pizza-house",
      "logo_path": "restaurant-assets/...",
      "currency_code": "INR",
      "timezone": "Asia/Kolkata"
    },
    "branch": {
      "id": "uuid",
      "name": "Patna Main",
      "phone": "+919876543210",
      "city": "Patna",
      "state": "Bihar",
      "country_code": "IN",
      "menu_version": 12
    },
    "table": {
      "id": "uuid",
      "name": "Table 12",
      "capacity": 4
    },
    "ordering": {
      "allow_dine_in": true,
      "allow_takeaway": true,
      "allow_delivery": false,
      "is_ordering_paused": false
    }
  },
  "error": null
}
```

## Failures

```text
INVALID_QR
QR_NOT_FOUND
QR_TABLE_INACTIVE
BRANCH_INACTIVE
RESTAURANT_INACTIVE
ORDERING_PAUSED
```

## Security

Do not return:

```text
restaurant_members
payment secrets
gateway config secrets
cost data
raw staff data
```

---

# 32. RPC — `get_public_menu`

## Purpose

Return one complete public menu payload to avoid N+1 queries.

## Auth

```text
authenticated customer
```

Could later support public/anon role if product intentionally allows unauthenticated browsing.

## Parameters

```json
{
  "p_branch_id": "uuid"
}
```

Optional future:

```json
{
  "p_branch_id": "uuid",
  "p_known_menu_version": 12
}
```

## Success

```json
{
  "ok": true,
  "data": {
    "restaurant": {
      "id": "uuid",
      "name": "Pizza House",
      "logo_path": "restaurant-assets/...",
      "currency_code": "INR",
      "timezone": "Asia/Kolkata"
    },
    "branch": {
      "id": "uuid",
      "name": "Patna Main",
      "menu_version": 12
    },
    "ordering": {
      "allow_dine_in": true,
      "allow_takeaway": true,
      "allow_delivery": false,
      "is_ordering_paused": false,
      "pause_reason": null
    },
    "categories": [
      {
        "id": "uuid",
        "name": "Pizza",
        "description": null,
        "image_path": null,
        "sort_order": 10,
        "products": [
          {
            "id": "uuid",
            "category_id": "uuid",
            "name": "Farmhouse Pizza",
            "description": "Capsicum, onion, tomato and cheese",
            "base_price_minor": 39900,
            "image_path": "menu-images/...",
            "is_veg": true,
            "is_available": true,
            "sort_order": 10,
            "preparation_minutes": 15,
            "tags": [
              "popular"
            ],
            "modifier_groups": [
              {
                "id": "uuid",
                "name": "Size",
                "min_select": 1,
                "max_select": 1,
                "is_required": true,
                "sort_order": 10,
                "modifiers": [
                  {
                    "id": "uuid",
                    "name": "Large",
                    "price_delta_minor": 10000,
                    "sort_order": 20,
                    "is_available": true
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  },
  "error": null
}
```

## Rules

Return only:

```text
active categories
active products
active modifier groups
active modifiers
```

Sold-out product may remain visible:

```json
"is_available": false
```

Sold-out modifier may be omitted or included with:

```json
"is_available": false
```

Choose one behavior and keep it consistent.

Recommended:

```text
include unavailable menu options so UI can show Sold Out
```

## Failures

```text
BRANCH_NOT_FOUND
BRANCH_INACTIVE
RESTAURANT_INACTIVE
```

---

# 33. RPC — `create_restaurant`

## Priority

Required only if self-service restaurant onboarding is in MVP.

## Auth

```text
authenticated merchant user
```

## Parameters

```json
{
  "p_name": "Pizza House",
  "p_slug": "pizza-house",
  "p_currency_code": "INR",
  "p_timezone": "Asia/Kolkata",
  "p_branch": {
    "name": "Patna Main",
    "code": "PATNA-MAIN",
    "phone": "+919876543210",
    "address_line1": "Example address",
    "city": "Patna",
    "state": "Bihar",
    "postal_code": "800001",
    "country_code": "IN"
  }
}
```

## Important

Do not accept:

```text
owner_user_id
```

Backend uses:

```text
auth.uid()
```

## Success

```json
{
  "ok": true,
  "data": {
    "restaurant_id": "uuid",
    "branch_id": "uuid",
    "role": "owner"
  },
  "error": null
}
```

## Transaction

Must create atomically:

```text
restaurant
restaurant_settings
owner membership
first branch
branch_settings
```

---

# 34. RPC — `create_order`

## Purpose

Authoritative atomic order creation.

This is the most important customer write contract.

## Auth

```text
authenticated customer
```

Anonymous Supabase Auth is valid.

## Request

```json
{
  "p_request": {
    "branch_id": "uuid",
    "table_id": "uuid",
    "order_type": "dine_in",
    "idempotency_key": "1c11a552-1f34-4bee-b556-bd69ca259314",
    "customer_name": "Rahul",
    "customer_phone": "+919876543210",
    "customer_note": "Please bring extra plates",
    "coupon_code": null,
    "items": [
      {
        "product_id": "uuid",
        "quantity": 2,
        "modifier_ids": [
          "uuid",
          "uuid"
        ],
        "note": "No onion"
      }
    ]
  }
}
```

Recommended SQL signature:

```text
create_order(p_request jsonb)
returns jsonb
```

## Client Must Not Send

Authoritative:

```text
base price
modifier price
subtotal
tax
discount amount
service charge
delivery fee
total
payment status
order status
restaurant ID if derivable from branch
```

## Server Validation Order

1. authenticate customer
2. validate request structure
3. validate idempotency key
4. validate branch
5. derive restaurant from branch
6. validate restaurant active
7. validate branch active
8. validate branch ordering pause
9. validate order type enabled
10. validate table for dine-in
11. validate products
12. validate quantity
13. validate modifier assignments
14. validate modifier availability
15. validate group min/max rules
16. fetch prices
17. validate coupon if supplied
18. calculate financial totals
19. create order
20. create snapshots
21. create initial status history
22. create payment row if business flow requires
23. return authoritative result

## Initial Status

If payment required before kitchen:

```text
awaiting_payment
```

If cash/pay-later and restaurant permits immediate kitchen placement:

```text
placed
```

## Success

```json
{
  "ok": true,
  "data": {
    "order": {
      "id": "uuid",
      "order_number": 1042,
      "restaurant_id": "uuid",
      "branch_id": "uuid",
      "table_id": "uuid",
      "order_type": "dine_in",
      "status": "awaiting_payment",
      "currency_code": "INR",
      "subtotal_minor": 85000,
      "tax_minor": 4250,
      "service_charge_minor": 0,
      "delivery_fee_minor": 0,
      "discount_minor": 0,
      "total_minor": 89250,
      "created_at": "2026-09-12T12:30:00+00:00"
    },
    "payment": {
      "required": true,
      "status": "pending"
    },
    "changes": []
  },
  "error": null
}
```

## Price / Availability Change Detail

If checkout must stop for explicit reconfirmation:

```json
{
  "ok": false,
  "data": null,
  "error": {
    "code": "RESOURCE_CHANGED",
    "message": "Your cart contains items that changed.",
    "details": {
      "items": [
        {
          "product_id": "uuid",
          "change_type": "price_changed",
          "old_price_minor": 19900,
          "new_price_minor": 21900
        }
      ]
    }
  }
}
```

For unavailable:

```json
{
  "code": "PRODUCT_UNAVAILABLE",
  "message": "One or more products are unavailable.",
  "details": {
    "product_ids": [
      "uuid"
    ]
  }
}
```

## Idempotency

Same:

```text
auth.uid()
+
idempotency_key
```

must resolve to the same order.

A retry after timeout must not create a second order.

## Failure Codes

```text
UNAUTHENTICATED
INVALID_ORDER
EMPTY_ORDER
INVALID_IDEMPOTENCY_KEY
BRANCH_NOT_FOUND
BRANCH_INACTIVE
RESTAURANT_INACTIVE
ORDERING_PAUSED
RESTAURANT_CLOSED
ORDER_TYPE_DISABLED
TABLE_NOT_FOUND
TABLE_INACTIVE
TABLE_BRANCH_MISMATCH
PRODUCT_NOT_FOUND
PRODUCT_INACTIVE
PRODUCT_UNAVAILABLE
PRODUCT_BRANCH_MISMATCH
INVALID_QUANTITY
INVALID_MODIFIER
MODIFIER_UNAVAILABLE
MODIFIER_NOT_ALLOWED
MODIFIER_SELECTION_REQUIRED
MODIFIER_SELECTION_TOO_FEW
MODIFIER_SELECTION_TOO_MANY
COUPON_INVALID
COUPON_EXPIRED
COUPON_MINIMUM_NOT_MET
```

---

# 35. RPC — `get_order_details`

## Purpose

Return a complete customer/admin-safe order aggregate without N+1 requests.

## Parameters

```json
{
  "p_order_id": "uuid"
}
```

## Authorization

Customer:

```text
own order only
```

Merchant:

```text
authorized restaurant/branch only
```

The backend can shape different fields based on role, or separate customer/admin RPCs can be created.

## Customer Success

```json
{
  "ok": true,
  "data": {
    "order": {
      "id": "uuid",
      "order_number": 1042,
      "order_type": "dine_in",
      "status": "preparing",
      "currency_code": "INR",
      "subtotal_minor": 85000,
      "tax_minor": 4250,
      "service_charge_minor": 0,
      "delivery_fee_minor": 0,
      "discount_minor": 0,
      "total_minor": 89250,
      "customer_note": "Please bring extra plates",
      "placed_at": "2026-09-12T12:30:00+00:00",
      "completed_at": null,
      "cancelled_at": null,
      "created_at": "2026-09-12T12:30:00+00:00"
    },
    "restaurant": {
      "id": "uuid",
      "name": "Pizza House",
      "logo_path": "restaurant-assets/..."
    },
    "branch": {
      "id": "uuid",
      "name": "Patna Main"
    },
    "table": {
      "id": "uuid",
      "name": "Table 12"
    },
    "items": [],
    "payment": {
      "method": "online",
      "status": "paid",
      "amount_minor": 89250,
      "currency_code": "INR",
      "paid_at": "2026-09-12T12:31:00+00:00"
    },
    "status_history": []
  },
  "error": null
}
```

## Failure

```text
ORDER_NOT_FOUND
FORBIDDEN
```

Do not reveal whether an unauthorized foreign order exists.

---

# 36. RPC — `change_order_status`

## Purpose

Perform legal merchant order-state transition.

## Auth

```text
authenticated merchant/staff
```

## Parameters

```json
{
  "p_order_id": "uuid",
  "p_new_status": "preparing",
  "p_reason": null
}
```

## Success

```json
{
  "ok": true,
  "data": {
    "order_id": "uuid",
    "old_status": "accepted",
    "new_status": "preparing",
    "updated_at": "2026-09-12T12:37:00+00:00"
  },
  "error": null
}
```

## Legal State Examples

```text
placed → accepted
accepted → preparing
preparing → ready
ready → served        dine-in
ready → completed     takeaway if configured
served → completed
```

Cancellation is policy-controlled from early statuses.

## Failure

```text
ORDER_NOT_FOUND
BRANCH_ACCESS_DENIED
ROLE_PERMISSION_DENIED
INVALID_STATUS_TRANSITION
ORDER_ALREADY_COMPLETED
ORDER_ALREADY_CANCELLED
CONCURRENT_UPDATE
```

## Concurrency

Transition must verify current status atomically.

---

# 37. RPC — `cancel_order`

Recommended separate contract for clearer permission/reason handling.

## Parameters

```json
{
  "p_order_id": "uuid",
  "p_reason": "Customer requested cancellation"
}
```

## Success

```json
{
  "ok": true,
  "data": {
    "order_id": "uuid",
    "status": "cancelled",
    "cancelled_at": "2026-09-12T12:40:00+00:00",
    "refund_required": true
  },
  "error": null
}
```

## Failure

```text
ORDER_NOT_CANCELLABLE
ROLE_PERMISSION_DENIED
ORDER_ALREADY_COMPLETED
PAYMENT_NOT_REFUNDABLE
```

Cancellation and refund may be separate transactions/business workflows.

---

# 38. RPC — `confirm_cash_payment`

## Purpose

Allow authorized merchant staff to confirm cash receipt.

## Auth

```text
owner
manager
cashier
```

depending on policy.

## Parameters

```json
{
  "p_order_id": "uuid"
}
```

Optional if explicit amount confirmation is required:

```json
{
  "p_order_id": "uuid",
  "p_amount_minor": 89250
}
```

Server must still compare against authoritative payable amount.

## Success

```json
{
  "ok": true,
  "data": {
    "payment": {
      "id": "uuid",
      "order_id": "uuid",
      "method": "cash",
      "amount_minor": 89250,
      "currency_code": "INR",
      "status": "paid",
      "paid_at": "2026-09-12T12:45:00+00:00"
    }
  },
  "error": null
}
```

## Failure

```text
ORDER_NOT_FOUND
BRANCH_ACCESS_DENIED
ROLE_PERMISSION_DENIED
PAYMENT_ALREADY_PAID
PAYMENT_AMOUNT_MISMATCH
```

---

# 39. RPC — `rotate_table_qr`

## Purpose

Invalidate old printed QR and generate a new opaque token.

## Auth

```text
owner
manager
```

## Parameters

```json
{
  "p_table_id": "uuid"
}
```

## Success

```json
{
  "ok": true,
  "data": {
    "table_id": "uuid",
    "qr_token": "uuid",
    "qr_url": "https://order.example.com/q/uuid"
  },
  "error": null
}
```

## Failure

```text
TABLE_NOT_FOUND
BRANCH_ACCESS_DENIED
ROLE_PERMISSION_DENIED
```

---

# 40. RPC — `get_dashboard_summary`

## Purpose

Fast admin operational dashboard aggregate.

## Auth

Merchant authorized for requested branch.

## Parameters

```json
{
  "p_branch_id": "uuid",
  "p_start_at": "2026-09-12T00:00:00+05:30",
  "p_end_at": "2026-09-13T00:00:00+05:30"
}
```

Recommended backend handling:

```text
convert/report using restaurant timezone rules
```

## Success

```json
{
  "ok": true,
  "data": {
    "currency_code": "INR",
    "orders_count": 86,
    "gross_order_value_minor": 2482000,
    "paid_revenue_minor": 2400000,
    "refunds_minor": 12000,
    "net_revenue_minor": 2388000,
    "average_order_value_minor": 28860,
    "active_orders_count": 7,
    "status_counts": {
      "placed": 2,
      "accepted": 0,
      "preparing": 3,
      "ready": 2
    },
    "payment_method_totals": [
      {
        "method": "cash",
        "amount_minor": 800000
      },
      {
        "method": "online",
        "amount_minor": 1600000
      }
    ],
    "top_products": [
      {
        "product_id": "uuid",
        "product_name": "Farmhouse Pizza",
        "quantity": 31,
        "sales_minor": 1236900
      }
    ]
  },
  "error": null
}
```

## Failure

```text
BRANCH_NOT_FOUND
BRANCH_ACCESS_DENIED
ROLE_PERMISSION_DENIED
```

---

# 41. RPC — `get_sales_report`

## Purpose

Historical report aggregate.

## Parameters

```json
{
  "p_branch_id": "uuid",
  "p_start_at": "2026-09-01T00:00:00+05:30",
  "p_end_at": "2026-10-01T00:00:00+05:30",
  "p_group_by": "day"
}
```

Allowed `group_by`:

```text
hour
day
week
month
```

## Success

```json
{
  "ok": true,
  "data": {
    "summary": {
      "orders_count": 2100,
      "gross_order_value_minor": 62000000,
      "paid_revenue_minor": 60000000,
      "refunds_minor": 500000,
      "net_revenue_minor": 59500000,
      "average_order_value_minor": 29524
    },
    "series": [
      {
        "bucket_start": "2026-09-01T00:00:00+05:30",
        "orders_count": 65,
        "net_revenue_minor": 1850000
      }
    ]
  },
  "error": null
}
```

---

# 42. RPC — `invite_staff`

Recommended server-controlled operation.

## Parameters

```json
{
  "p_contact": {
    "email": "staff@example.com",
    "phone": null
  },
  "p_restaurant_id": "uuid",
  "p_role": "kitchen",
  "p_branch_ids": [
    "uuid"
  ]
}
```

## Success

```json
{
  "ok": true,
  "data": {
    "invitation_id": "uuid",
    "expires_at": "2026-09-19T12:00:00+00:00"
  },
  "error": null
}
```

## Failure

```text
ROLE_PERMISSION_DENIED
MEMBER_ALREADY_EXISTS
CONFLICT
```

Do not return raw invitation token if invitation delivery is server-side.

---

# 43. RPC — `accept_staff_invitation`

## Auth

Authenticated invited user.

## Parameters

```json
{
  "p_token": "opaque-invitation-token"
}
```

Server stores only token hash in database.

## Success

```json
{
  "ok": true,
  "data": {
    "restaurant_id": "uuid",
    "role": "kitchen",
    "branch_ids": [
      "uuid"
    ]
  },
  "error": null
}
```

## Failure

```text
INVITATION_NOT_FOUND
INVITATION_EXPIRED
INVITATION_REVOKED
INVITATION_ALREADY_ACCEPTED
```

---

# 44. Direct Data Contract — Merchant Categories

## Select

Filter:

```text
branch_id = currentBranchId
```

Suggested returned fields:

```json
{
  "id": "uuid",
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "name": "Pizza",
  "description": null,
  "image_path": null,
  "sort_order": 10,
  "is_active": true,
  "created_at": "...",
  "updated_at": "..."
}
```

## Insert

Client may provide:

```json
{
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "name": "Pizza",
  "description": null,
  "image_path": null,
  "sort_order": 10,
  "is_active": true
}
```

RLS must verify restaurant/branch access.

---

# 45. Direct Data Contract — Merchant Products

## Insert / Update Fields

```json
{
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "category_id": "uuid",
  "name": "Farmhouse Pizza",
  "description": "Capsicum, onion, tomato and cheese",
  "sku": "PIZZA-FARM",
  "base_price_minor": 39900,
  "tax_basis_points_override": null,
  "image_path": "menu-images/...",
  "is_veg": true,
  "is_available": true,
  "is_active": true,
  "sort_order": 10,
  "preparation_minutes": 15
}
```

## Rules

Client can suggest values.

Database/RLS validates tenant access.

Historical order prices are unaffected by product price updates.

---

# 46. Direct Data Contract — Modifier Groups

```json
{
  "restaurant_id": "uuid",
  "name": "Size",
  "min_select": 1,
  "max_select": 1,
  "is_required": true,
  "sort_order": 10,
  "is_active": true
}
```

---

# 47. Direct Data Contract — Modifiers

```json
{
  "restaurant_id": "uuid",
  "group_id": "uuid",
  "name": "Large",
  "price_delta_minor": 10000,
  "sort_order": 20,
  "is_available": true,
  "is_active": true
}
```

---

# 48. Direct Data Contract — Product Modifier Mapping

```json
{
  "restaurant_id": "uuid",
  "product_id": "uuid",
  "modifier_group_id": "uuid",
  "sort_order": 10
}
```

---

# 49. Direct Data Contract — Dining Tables

Insert:

```json
{
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "dining_area_id": null,
  "name": "Table 12",
  "capacity": 4,
  "is_active": true
}
```

Do not allow client to choose predictable QR token if server policy prefers generated default.

Recommended:

```text
omit qr_token on insert
```

Database generates token.

---

# 50. Direct Data Contract — Opening Hours

```json
{
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "weekday": 1,
  "slot_order": 0,
  "opens_at": "10:00:00",
  "closes_at": "23:00:00",
  "is_closed": false
}
```

Closed day:

```json
{
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "weekday": 0,
  "slot_order": 0,
  "opens_at": null,
  "closes_at": null,
  "is_closed": true
}
```

---

# 51. Direct Data Contract — Profile Update

Allowed customer self-update fields:

```json
{
  "full_name": "Rahul Kumar",
  "phone": "+919876543210",
  "avatar_path": "avatars/uuid/avatar.webp"
}
```

Do not allow user to update:

```text
id
created_at
authorization role
restaurant membership
```

---

# 52. Edge Function — `create-payment`

## Method

```text
POST
```

## Auth

Required authenticated customer.

## Request

```json
{
  "order_id": "uuid",
  "payment_method": "online",
  "idempotency_key": "uuid"
}
```

Provider-specific payment method details may be added only when necessary.

## Server Responsibilities

1. verify caller
2. load order
3. verify customer owns order
4. verify status is payable
5. verify not already paid
6. load amount from order
7. use server payment credentials
8. reuse/avoid duplicate payment session
9. create provider order/session
10. persist payment/provider IDs
11. return safe client checkout data

## Success

Generic:

```json
{
  "ok": true,
  "data": {
    "order_id": "uuid",
    "payment_id": "uuid",
    "provider": "provider_name",
    "provider_order_id": "provider_order_123",
    "amount_minor": 89250,
    "currency_code": "INR",
    "checkout": {
      "public_key": "provider_public_key_if_required",
      "session_id": "safe-session-value",
      "customer_reference": "optional-safe-reference"
    }
  },
  "error": null
}
```

The exact `checkout` shape may be provider-specific.

Never return:

```text
provider secret
webhook secret
private signing key
```

## Failure

HTTP status examples:

```text
401 authentication
403 authorization
409 payment conflict
422 validation/business rule
500 unexpected server failure
502 provider failure
```

Domain codes:

```text
ORDER_NOT_FOUND
FORBIDDEN
PAYMENT_NOT_REQUIRED
PAYMENT_ALREADY_PAID
PAYMENT_ALREADY_IN_PROGRESS
PAYMENT_FAILED
```

---

# 53. Edge Function — `payment-webhook`

## Method

```text
POST
```

## Auth

Provider signature, not Supabase user session.

## Request

Raw provider webhook body.

The Edge Function must preserve the exact raw body if signature verification requires it.

## Responsibilities

1. verify provider signature
2. identify provider event ID
3. idempotency check `webhook_events`
4. parse event
5. locate payment/order
6. validate amount
7. validate currency
8. validate provider identifiers
9. update payment
10. update order if required
11. append order status history if state changes
12. store webhook event result
13. return 2xx for successfully handled duplicate events

## Example Internal Normalized Event

```json
{
  "provider": "provider_name",
  "provider_event_id": "evt_123",
  "event_type": "payment.succeeded",
  "provider_order_id": "order_123",
  "provider_payment_id": "pay_123",
  "amount_minor": 89250,
  "currency_code": "INR"
}
```

This normalized object is internal.

## Success Response

Provider usually only requires simple 2xx:

```json
{
  "ok": true
}
```

---

# 54. Edge Function — `refund-payment`

## Method

```text
POST
```

## Auth

Authenticated merchant.

## Request

```json
{
  "payment_id": "uuid",
  "amount_minor": 30000,
  "reason": "Item unavailable",
  "idempotency_key": "uuid"
}
```

## Server Responsibilities

1. authenticate merchant
2. load payment/order/branch
3. validate merchant branch access
4. validate role/capability
5. validate payment refundable
6. validate refund amount
7. check cumulative refunds
8. call provider
9. record `payment_refunds`
10. update payment status
11. audit
12. remain idempotent

## Success

```json
{
  "ok": true,
  "data": {
    "refund": {
      "id": "uuid",
      "payment_id": "uuid",
      "amount_minor": 30000,
      "status": "processing",
      "provider_refund_id": "refund_123",
      "created_at": "2026-09-12T13:00:00+00:00"
    }
  },
  "error": null
}
```

## Failure

```text
PAYMENT_NOT_FOUND
ROLE_PERMISSION_DENIED
PAYMENT_NOT_REFUNDABLE
REFUND_AMOUNT_INVALID
REFUND_LIMIT_EXCEEDED
REFUND_ALREADY_PROCESSED
```

---

# 55. Edge Function — Push Notification Dispatch

This is server/internal.

Flutter should not be allowed to send arbitrary notifications to other users.

Internal normalized payload:

```json
{
  "audience": {
    "user_ids": [
      "uuid"
    ]
  },
  "notification": {
    "title": "Order ready",
    "body": "Order #1042 is ready.",
    "type": "order_ready",
    "data": {
      "order_id": "uuid"
    }
  }
}
```

Merchant new-order example:

```json
{
  "type": "new_order",
  "data": {
    "order_id": "uuid",
    "branch_id": "uuid"
  }
}
```

---

# 56. Device Token Registration Contract

Can use direct table CRUD under RLS.

## Upsert

```json
{
  "user_id": "auth.uid()",
  "token": "device-push-token",
  "platform": "android",
  "app_type": "customer",
  "is_active": true,
  "last_seen_at": "2026-09-12T12:00:00+00:00"
}
```

Client must not register token for another `user_id`.

---

# 57. Customer Order History Query Contract

Recommended RPC or RLS-protected query.

## Request

```json
{
  "limit": 20,
  "before_created_at": "2026-09-12T12:00:00+00:00",
  "before_id": "uuid"
}
```

For first page:

```json
{
  "limit": 20,
  "before_created_at": null,
  "before_id": null
}
```

## Response

```json
{
  "items": [
    {
      "id": "uuid",
      "order_number": 1042,
      "restaurant_name": "Pizza House",
      "branch_name": "Patna Main",
      "order_type": "dine_in",
      "status": "completed",
      "currency_code": "INR",
      "total_minor": 89250,
      "created_at": "2026-09-12T12:30:00+00:00"
    }
  ],
  "page": {
    "has_more": true,
    "next_cursor": {
      "before_created_at": "2026-09-01T10:00:00+00:00",
      "before_id": "uuid"
    }
  }
}
```

Prefer keyset pagination over large offsets.

---

# 58. Admin Order History Query Contract

Filters:

```json
{
  "branch_id": "uuid",
  "statuses": [
    "completed",
    "cancelled"
  ],
  "order_types": [
    "dine_in",
    "takeaway"
  ],
  "payment_statuses": [
    "paid"
  ],
  "search": "1042",
  "start_at": "2026-09-01T00:00:00+05:30",
  "end_at": "2026-10-01T00:00:00+05:30",
  "limit": 50,
  "cursor": null
}
```

Response:

```json
{
  "items": [],
  "page": {
    "has_more": false,
    "next_cursor": null
  }
}
```

---

# 59. Realtime — `orders`

## Purpose

```text
merchant live orders
KDS
customer tracking
```

## Source

Postgres Changes / Supabase Realtime on:

```text
public.orders
```

## Primary Key

```text
id
```

## Important

Realtime event filtering improves efficiency but is **not authorization**.

RLS must still protect rows.

---

# 60. Realtime Order Row Shape

Expected row fields may include:

```json
{
  "id": "uuid",
  "order_number": 1042,
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "table_id": "uuid",
  "customer_id": "uuid",
  "order_type": "dine_in",
  "status": "preparing",
  "currency_code": "INR",
  "subtotal_minor": 85000,
  "tax_minor": 4250,
  "service_charge_minor": 0,
  "delivery_fee_minor": 0,
  "discount_minor": 0,
  "total_minor": 89250,
  "placed_at": "2026-09-12T12:30:00+00:00",
  "completed_at": null,
  "cancelled_at": null,
  "created_at": "2026-09-12T12:30:00+00:00",
  "updated_at": "2026-09-12T12:37:00+00:00"
}
```

Client should not depend on every row field being available in every event type without a refetch strategy.

---

# 61. Realtime — Merchant Subscription

Filter concept:

```text
branch_id = currentBranchId
```

Active statuses handled client/server:

```text
placed
accepted
preparing
ready
served
```

On reconnect:

```text
refetch active orders
```

---

# 62. Realtime — Customer Subscription

Filter concept:

```text
id = currentOrderId
```

RLS additionally requires:

```text
customer_id = auth.uid()
```

On event:

```text
update lightweight status
or
refetch full order details
```

Recommended:

```text
refetch full order on material status/payment change
```

---

# 63. Realtime — `order_status_history`

Optional second subscription.

Useful for:

```text
timeline
audit
```

Customer can also simply refetch details when order row changes.

For MVP, one `orders` subscription is enough for customer tracking.

---

# 64. Realtime Client Event Model

Normalize Supabase event to app model:

```json
{
  "event_type": "UPDATE",
  "table": "orders",
  "record_id": "uuid",
  "record": {},
  "old_record": {}
}
```

The Flutter repository owns conversion from raw Supabase event.

Views never process raw Realtime payloads.

---

# 65. Storage Contract — Restaurant Assets

Bucket:

```text
restaurant-assets
```

Path:

```text
<restaurant_id>/logo.webp
```

Alternative explicit:

```text
restaurants/<restaurant_id>/logo.webp
```

Choose one path convention and use it consistently.

---

# 66. Storage Contract — Menu Images

Bucket:

```text
menu-images
```

Path:

```text
<restaurant_id>/<branch_id>/products/<product_id>/main.webp
```

Category:

```text
<restaurant_id>/<branch_id>/categories/<category_id>/main.webp
```

---

# 67. Storage Contract — Avatars

Bucket:

```text
avatars
```

Path:

```text
<user_id>/avatar.webp
```

---

# 68. Image Upload Contract

Client:

1. validate MIME type
2. compress/resize
3. upload new file
4. update DB path
5. delete old file after DB success

Do not:

```text
delete old file before new path is safely saved
```

---

# 69. Public Image DTO Rule

Store path:

```json
{
  "image_path": "uuid/uuid/products/uuid/main.webp"
}
```

Repository/UI may convert path to public/signed URL.

Do not permanently store expiring signed URL in database.

---

# 70. Menu Cache Contract

Local customer cache key should include:

```text
branch_id
menu_version
```

Example metadata:

```json
{
  "branch_id": "uuid",
  "menu_version": 12,
  "cached_at": "2026-09-12T12:00:00+00:00",
  "payload": {}
}
```

Checkout always revalidates server-side.

---

# 71. Cart Local Contract

Example:

```json
{
  "version": 1,
  "restaurant_id": "uuid",
  "branch_id": "uuid",
  "table_id": "uuid",
  "updated_at": "2026-09-12T12:10:00+00:00",
  "items": [
    {
      "local_id": "uuid",
      "product_id": "uuid",
      "product_name": "Farmhouse Pizza",
      "base_price_minor_preview": 39900,
      "quantity": 2,
      "modifier_ids": [
        "uuid"
      ],
      "modifier_snapshots_preview": [
        {
          "id": "uuid",
          "name": "Extra Cheese",
          "price_delta_minor": 2000
        }
      ],
      "note": "No onion"
    }
  ]
}
```

All local prices are preview-only.

---

# 72. Checkout Local Recovery Contract

Persist before critical request:

```json
{
  "idempotency_key": "uuid",
  "branch_id": "uuid",
  "created_at": "2026-09-12T12:20:00+00:00"
}
```

After order success:

```json
{
  "order_id": "uuid",
  "payment_pending": true
}
```

On restart:

```text
query backend before creating anything new
```

---

# 73. Payment Recovery Contract

Persist:

```json
{
  "order_id": "uuid",
  "payment_id": "uuid",
  "provider_order_id": "safe-id",
  "started_at": "2026-09-12T12:31:00+00:00"
}
```

Never persist:

```text
secret
private key
webhook secret
card data
```

---

# 74. Admin Active Order DTO

Recommended optimized shape:

```json
{
  "id": "uuid",
  "order_number": 1042,
  "order_type": "dine_in",
  "status": "placed",
  "table": {
    "id": "uuid",
    "name": "Table 12"
  },
  "currency_code": "INR",
  "total_minor": 89250,
  "item_count": 3,
  "item_preview": [
    {
      "name": "Farmhouse Pizza",
      "quantity": 2
    }
  ],
  "payment": {
    "method": "online",
    "status": "paid"
  },
  "created_at": "2026-09-12T12:30:00+00:00"
}
```

For KDS, full items/modifiers may be needed.

---

# 75. KDS Order DTO

```json
{
  "id": "uuid",
  "order_number": 1042,
  "order_type": "dine_in",
  "status": "preparing",
  "table_name": "Table 12",
  "created_at": "2026-09-12T12:30:00+00:00",
  "accepted_at": "2026-09-12T12:31:00+00:00",
  "items": [
    {
      "id": "uuid",
      "product_name": "Farmhouse Pizza",
      "quantity": 2,
      "item_note": "No onion",
      "modifiers": [
        {
          "modifier_name": "Large"
        },
        {
          "modifier_name": "Extra Cheese"
        }
      ]
    }
  ],
  "customer_note": "Please bring extra plates"
}
```

`accepted_at` may be derived from status history if not stored on order.

---

# 76. Merchant Product Availability Update

Simple RLS-protected update:

```json
{
  "is_available": false
}
```

Filter:

```text
id = productId
branch_id = currentBranchId
```

Backend/RLS checks access.

Client displays:

```text
Sold Out
```

---

# 77. Merchant Branch Pause Contract

Recommended controlled RPC or RLS-safe branch_settings update.

Input:

```json
{
  "is_ordering_paused": true,
  "ordering_pause_reason": "Kitchen overloaded"
}
```

If direct update is used, RLS must restrict to authorized roles.

---

# 78. Query Pagination Standard

Prefer keyset pagination.

Generic:

```json
{
  "limit": 50,
  "cursor": {
    "created_at": "2026-09-12T12:00:00+00:00",
    "id": "uuid"
  }
}
```

Response:

```json
{
  "items": [],
  "page": {
    "has_more": true,
    "next_cursor": {
      "created_at": "...",
      "id": "uuid"
    }
  }
}
```

Maximum client-requested limit should be capped server-side.

Recommended:

```text
customer history max 50
admin list max 100
```

---

# 79. Search Standard

Search request:

```json
{
  "query": "farm",
  "limit": 20
}
```

Trim:

```text
leading/trailing whitespace
```

Limit query length server/client side.

Do not expose unrestricted SQL wildcard behavior from raw user input.

---

# 80. Sort Standard

Allowed explicit sort values only.

Example:

```text
created_desc
created_asc
name_asc
name_desc
sort_order
```

Do not accept arbitrary SQL column expressions from client.

---

# 81. Filter Standard

Arrays use enum values:

```json
{
  "statuses": [
    "placed",
    "preparing"
  ]
}
```

Empty array means:

```text
no filter
```

unless endpoint explicitly defines otherwise.

---

# 82. Idempotency Standard

Use UUID/string key generated once per logical operation.

Operations requiring idempotency:

```text
create_order
create_payment
refund_payment
external webhook processing
possibly staff invitation send
```

Retry uses the SAME key.

Do not generate a new key after transport timeout.

---

# 83. Order Idempotency

Database uniqueness:

```text
(customer_id, idempotency_key)
```

Same key + same customer:

```text
return same order
```

If same key is reused for a materially different request, backend should return:

```text
CONFLICT
```

or original result according to implementation policy.

Recommended:

```text
detect request mismatch and return CONFLICT
```

---

# 84. Payment Idempotency

Recommended logical uniqueness:

```text
order_id + active provider payment attempt
```

and explicit client `idempotency_key`.

Do not create multiple payable provider sessions unnecessarily.

---

# 85. Refund Idempotency

Use:

```text
payment_id + idempotency_key
```

Database schema already supports unique partial index.

Same retry returns same refund.

---

# 86. Webhook Idempotency

Database uniqueness:

```text
provider + provider_event_id
```

Duplicate event:

```text
return 2xx
do not duplicate side effects
```

---

# 87. HTTP Status Contract — Edge Functions

Recommended:

```text
200 / 201 success
400 malformed request
401 unauthenticated
403 unauthorized
404 resource not found
409 conflict/idempotency/state conflict
422 valid request but business rule failure
429 rate limit
500 unexpected internal failure
502 external provider failure
503 temporary dependency unavailable
```

RPC domain errors use the JSON envelope.

---

# 88. Auth API Contract

Use official Supabase Auth SDK.

Customer:

```text
signInAnonymously
phone OTP later
```

Merchant:

```text
signInWithPassword
password reset
```

Do not wrap standard Auth calls in custom Edge Functions unless required.

---

# 89. Customer Repository Interface Contract

Suggested Dart-level interface:

```dart
abstract interface class RestaurantRepository {
  Future<QrContext> resolveQr(String token);
}

abstract interface class MenuRepository {
  Future<RestaurantMenu> getPublicMenu(
    String branchId,
  );
}

abstract interface class OrderRepository {
  Future<CreateOrderResult> createOrder(
    CreateOrderRequest request,
  );

  Future<OrderDetails> getOrderDetails(
    String orderId,
  );

  Stream<OrderSummary> watchOrder(
    String orderId,
  );

  Future<OrderPage> getMyOrders({
    OrderCursor? cursor,
    int limit = 20,
  });
}

abstract interface class PaymentRepository {
  Future<CreatePaymentResult> createPayment(
    CreatePaymentRequest request,
  );

  Future<PaymentSummary> getPaymentForOrder(
    String orderId,
  );
}
```

Exact implementation may differ but payload semantics must match this document.

---

# 90. Admin Repository Interface Contract

Suggested:

```dart
abstract interface class AdminOrderRepository {
  Future<List<AdminOrderSummary>>
      getActiveOrders(String branchId);

  Stream<OrderRealtimeEvent>
      watchActiveOrders(String branchId);

  Future<OrderDetails> getOrderDetails(
    String orderId,
  );

  Future<OrderStatusChangeResult>
      changeStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
  });
}
```

Menu/staff/payment/report repositories follow screen specification documents.

---

# 91. API DTO Naming in Dart

Recommended:

```text
QrContextDto
PublicMenuDto
CategoryDto
ProductDto
ModifierGroupDto
ModifierDto
CreateOrderRequestDto
CreateOrderResponseDto
OrderSummaryDto
OrderDetailsDto
PaymentSummaryDto
CreatePaymentResponseDto
RefundResponseDto
DashboardSummaryDto
ApiErrorDto
ApiResultDto<T>
```

Domain model conversion:

```text
DTO
→ Domain Model
→ UI
```

For MVP, DTO/domain may share model if kept clean.

---

# 92. JSON Naming

Backend JSON:

```text
snake_case
```

Dart fields:

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

```text
totalMinor
```

---

# 93. Nullability Rules

Missing optional data should generally use:

```json
null
```

not empty string.

Examples:

```text
phone
image_path
table_id
completed_at
cancelled_at
```

Collections should generally return:

```json
[]
```

instead of `null`.

---

# 94. Boolean Rules

Always use actual JSON booleans:

```json
true
false
```

Never:

```text
"true"
1
```

---

# 95. Empty Collection Rules

Use:

```json
"items": []
```

not:

```json
"items": null
```

unless the field is truly optional/omitted.

---

# 96. Order Status Transition Contract

Canonical state machine:

```text
awaiting_payment
  ├── payment success → placed
  └── cancel/expiry   → cancelled

placed
  ├── accepted
  └── cancelled

accepted
  ├── preparing
  └── cancelled if policy allows

preparing
  └── ready

ready
  ├── served      dine-in
  └── completed   takeaway if configured

served
  └── completed
```

Delivery requires additional future statuses before production delivery support.

---

# 97. Payment-to-Order State Contract

Online, payment-before-kitchen:

```text
create order
→ awaiting_payment
→ provider payment succeeds
→ webhook verifies
→ payment paid
→ order placed
```

Cash/pay-later:

```text
create order
→ placed
→ cash payment pending
→ cashier confirms
→ payment paid
```

Exact cash policy may be restaurant-configurable.

---

# 98. Customer Payment UI Contract

Client SDK callback:

```text
not authoritative
```

On SDK "success":

```text
show confirming payment
query server
wait for webhook-confirmed state
```

---

# 99. Payment Amount Contract

Provider payment amount must come from:

```text
orders.total_minor
```

loaded server-side.

Never from:

```text
Flutter total
create-payment request amount
```

---

# 100. Coupon Contract

Client may send:

```json
{
  "coupon_code": "WELCOME10"
}
```

Server:

```text
normalizes code
loads coupon
validates restaurant
validates active dates
validates usage limits
validates minimum
calculates discount
snapshots result
```

Client never sends authoritative discount.

---

# 101. Customer Contact Contract

Checkout may submit:

```json
{
  "customer_name": "Rahul",
  "customer_phone": "+919876543210"
}
```

Backend snapshots these into order if accepted.

Historical order display uses snapshot.

Profile changes do not rewrite order history.

---

# 102. Item Note Contract

Max per schema:

```text
500 characters
```

Client should enforce the same maximum.

---

# 103. Order Note Contract

Max per schema:

```text
1000 characters
```

Client should enforce the same maximum.

---

# 104. Quantity Contract

Schema maximum:

```text
1–999
```

Product/business logic may enforce a lower operational limit.

Recommended app limit for normal restaurant order:

```text
1–99
```

unless merchant requires more.

Server always validates.

---

# 105. QR URL Contract

Canonical:

```text
https://order.example.com/q/<uuid-token>
```

Flutter parser should reject unrelated arbitrary URLs as table QR.

---

# 106. Deep Link Contract

Supported MVP:

```text
/q/<token>
/order/<uuid>
```

Future:

```text
/r/<slug>
/b/<slug>
```

Do not use query parameters as trusted restaurant/table identity.

---

# 107. Notification Data Contract

Customer:

```json
{
  "type": "order_ready",
  "order_id": "uuid"
}
```

Merchant:

```json
{
  "type": "new_order",
  "order_id": "uuid",
  "branch_id": "uuid"
}
```

App opens route and backend reauthorizes.

---

# 108. Branch Context Contract

Local admin context:

```json
{
  "restaurant_id": "uuid",
  "restaurant_name": "Pizza House",
  "branch_id": "uuid",
  "branch_name": "Patna Main",
  "role": "manager"
}
```

This is UI convenience only.

Every backend query remains RLS-protected.

---

# 109. Customer Context Contract

Local:

```json
{
  "restaurant_id": "uuid",
  "restaurant_name": "Pizza House",
  "branch_id": "uuid",
  "branch_name": "Patna Main",
  "table_id": "uuid",
  "table_name": "Table 12",
  "currency_code": "INR",
  "resolved_at": "2026-09-12T12:00:00+00:00"
}
```

Server must revalidate at checkout.

---

# 110. Public Menu Versioning

Branch schema contains:

```text
menu_version
```

Recommended future contract:

If client sends current version and unchanged:

```json
{
  "ok": true,
  "data": {
    "not_modified": true,
    "menu_version": 12
  },
  "error": null
}
```

MVP may always return full menu.

---

# 111. API Logging Rules

Safe log context:

```text
request_id
user_id
restaurant_id
branch_id
order_id
payment_id
domain_error_code
```

Do not log:

```text
password
OTP
full access token
payment secret
webhook secret
raw card data
unnecessary full customer PII
```

---

# 112. Correlation / Request ID

Optional but recommended for Edge Functions.

Response header:

```text
x-request-id
```

or JSON metadata:

```json
{
  "meta": {
    "request_id": "uuid"
  }
}
```

Do not require this for initial RPC MVP if it complicates implementation.

---

# 113. Rate Limiting Candidates

Apply server-side protection to:

```text
QR resolution abuse
OTP
payment creation
refund
staff invitations
coupon attempts
```

Return:

```text
RATE_LIMITED
```

or HTTP 429.

---

# 114. Backward Compatibility

When adding a response field:

```text
safe
```

when old clients ignore unknown fields.

Removing/renaming required field:

```text
breaking
```

Changing enum semantics:

```text
breaking
```

---

# 115. API Contract Change Procedure

Before changing API:

1. update this file
2. update SQL/RPC/Edge implementation
3. update Dart DTO
4. update repository
5. update tests
6. deploy backward-compatible backend first if needed
7. release app
8. remove legacy contract later

---

# 116. Test Contract — `resolve_qr`

Must test:

```text
valid
unknown token
inactive table
inactive branch
inactive restaurant
cross-tenant data does not leak
```

---

# 117. Test Contract — `get_public_menu`

Must test:

```text
active menu
empty menu
sold-out product
inactive category omitted
inactive product omitted
modifier rules
no private fields
```

---

# 118. Test Contract — `create_order`

Must test:

```text
valid dine-in
valid takeaway
invalid table
table branch mismatch
inactive product
sold-out product
invalid quantity
required modifier missing
too many modifiers
modifier from different group
modifier not attached to product
price change
coupon invalid
duplicate idempotency
concurrent duplicate
```

---

# 119. Test Contract — Status RPC

Must test every legal transition and illegal reverse transition.

Also:

```text
unauthorized role
wrong branch
concurrent change
completed order
cancelled order
```

---

# 120. Test Contract — Payment

Must test:

```text
create payment
already paid
duplicate create
success webhook
duplicate webhook
bad signature
wrong amount
wrong currency
failure
cancel
app restart recovery
```

---

# 121. Test Contract — Refund

Must test:

```text
authorized refund
unauthorized refund
partial
full
too large
duplicate idempotency
provider failure
```

---

# 122. Test Contract — Realtime

Must test:

```text
merchant branch isolation
customer order isolation
new order
status update
disconnect
reconnect
branch switch
logout
```

---

# 123. Flutter Repository Error Rule

Repositories must not leak raw:

```text
PostgrestException
FunctionException
AuthException
SocketException
```

to Views.

Map to application errors.

---

# 124. Flutter Serialization Rule

All JSON parsing must:

```text
handle nullable fields
validate required enum values
fail predictably on unsupported data
```

Unknown enum value should not crash the entire app without recovery.

Recommended fallback:

```text
throw typed parsing/domain error
log safely
show generic recoverable error
```

---

# 125. Client Retry Rule

Automatically retry:

```text
safe reads
some idempotent operations
```

Do not blindly retry:

```text
refund without idempotency
QR rotation
role changes
destructive admin actions
```

---

# 126. Timeout Rule

Network timeout does not imply failure for:

```text
create order
payment
refund
```

After timeout:

```text
recover/query by idempotency or known resource ID
```

---

# 127. Order Recovery Rule

If `create_order` request times out:

```text
retry same idempotency key
```

Never create a new key until operation outcome is known.

---

# 128. Payment Recovery Rule

If payment UI returns and network fails:

```text
query payment/order later
```

Do not show confirmed failure unless backend/provider confirms failure.

---

# 129. Refund Recovery Rule

If refund Edge Function times out:

```text
query existing refund by idempotency/payment
```

Do not issue a second refund with a new key immediately.

---

# 130. Security Invariants

The API is considered correctly implemented only if a modified Flutter client cannot:

```text
read another tenant's data
read another customer's private order
change its staff role
choose a cheaper product price
skip required modifiers
fake discount
fake tax
fake payment success
create invalid status transition
refund without permission
rotate another restaurant's QR
```

---

# 131. Recommended Implementation Files

This contract should be implemented by:

```text
supabase/migrations/
  0001_database_schema.sql
  0002_rls_helpers.sql
  0003_rls_policies.sql
  0004_rpc_qr_menu.sql
  0005_rpc_orders.sql
  0006_rpc_admin.sql
  0007_realtime.sql
  0008_storage.sql

supabase/functions/
  create-payment/
  payment-webhook/
  refund-payment/
  notification-dispatch/
```

Exact migration numbering may differ.

---

# 132. Recommended Next Specification Files

After this file, create:

```text
PROJECT_RULES.md
DATA_MODELS.md
RLS_POLICIES.sql
RPC_FUNCTIONS.sql
EDGE_FUNCTIONS_SPEC.md
TEST_PLAN.md
ENVIRONMENT_AND_DEPLOYMENT.md
IMPLEMENTATION_ORDER.md
```

---

# 133. AI Coding Tool Rules

When implementing from this file:

```text
1. Do not invent RPC parameter names.
2. Do not invent response field names.
3. Keep backend JSON snake_case.
4. Keep Dart properties camelCase.
5. Use integer minor units for money.
6. Use auth.uid() for authenticated identity.
7. Never accept user ID as trusted identity input.
8. Never trust client totals.
9. Never trust client payment success.
10. Reuse idempotency keys on retries.
11. Use RLS for tenant isolation.
12. Use RPC for transactional business operations.
13. Use Edge Functions for provider secrets/webhooks.
14. Refetch after Realtime reconnect.
15. Map raw backend errors into domain errors.
```

---

# 134. Example End-to-End Customer Contract

```text
Customer scans QR
↓
resolve_qr(p_qr_token)
↓
save safe context
↓
get_public_menu(p_branch_id)
↓
customer builds local cart
↓
create_order(p_request)
↓
server returns authoritative order
↓
if online:
  create-payment Edge Function
↓
provider checkout
↓
payment-webhook
↓
payment = paid
order = placed
↓
Realtime orders update
↓
customer tracks order
```

---

# 135. Example End-to-End Merchant Contract

```text
Merchant signs in
↓
load restaurant membership
↓
load branch access
↓
get_dashboard_summary
↓
get active orders
+
Realtime orders
↓
open order
↓
change_order_status
↓
status history inserted
↓
Realtime customer update
```

---

# 136. Definition of API Contract Complete

The contract is sufficiently defined when an AI coding tool can answer:

```text
What is the operation called?
Who can call it?
What parameters are accepted?
Which fields are trusted?
Which fields are server-derived?
What JSON is returned?
What domain errors can occur?
Is the operation idempotent?
How should Flutter recover from timeout?
How does Realtime synchronize it?
What security rule applies?
```

The central rule is:

```text
Flutter requests intent.
Backend determines truth.
```
