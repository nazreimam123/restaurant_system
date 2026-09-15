# Supabase Backend Specification
## QR Restaurant Ordering Platform — Flutter + GetX + MVC

> Production-oriented Supabase backend blueprint for the restaurant QR ordering platform.
>
> Covers PostgreSQL schema, Auth, RLS, grants, Storage, Realtime, RPCs, Edge Functions, payments, webhooks, migrations, testing, monitoring, and future modules.
>
> Verified against current Supabase concepts/documentation in September 2026. Test all SQL in development/staging before production.

---

# 1. Backend Goals

The backend must support:

- Multi-restaurant tenancy
- Multiple branches per restaurant
- Owners, managers, cashiers, waiters, kitchen staff
- Customer and anonymous/guest ordering
- QR table ordering
- Dine-in, takeaway, and later delivery
- Categories, products, modifier groups, modifiers
- Secure server-calculated pricing
- Transactional order creation
- Cash and online payments
- Payment webhooks and refunds
- KDS/live orders
- Customer live tracking
- Product/menu images
- Push notification device tokens
- Audit logs
- Analytics
- Future coupons, loyalty, reservations, inventory, CRM, subscriptions, and AI

---

# 2. Supabase Services Used

| Service | Purpose |
|---|---|
| PostgreSQL | Main transactional database |
| Auth | Customer and staff identities |
| Data API | Flutter CRUD/RPC access |
| Row Level Security | Authorization and tenant isolation |
| Realtime | Live orders and status updates |
| Storage | Logos, menu images, avatars |
| Database Functions / RPC | Secure transactional business logic |
| Edge Functions | Payments, webhooks, notifications, external APIs |
| CLI + migrations | Version-controlled backend changes |

---

# 3. Core Security Principle

```text
FLUTTER CLIENTS ARE UNTRUSTED
```

Never trust Flutter for:

```text
restaurant ownership
staff role
branch access
product price
modifier price
tax
service charge
discount
coupon validity
final total
payment status
refund status
order status transition
inventory movement
loyalty balance
```

Flutter requests an action. Supabase/PostgreSQL decides whether it is valid.

---

# 4. Architecture

```text
CUSTOMER FLUTTER APP                  MERCHANT FLUTTER APP
        │                                      │
        └──────── publishable key + JWT ──────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │     SUPABASE      │
                 │                   │
                 │ Auth              │
                 │ Data API          │
                 │ PostgreSQL        │
                 │ RLS               │
                 │ Realtime          │
                 │ Storage           │
                 │ RPC Functions     │
                 │ Edge Functions    │
                 └─────────┬─────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
       Payments          Push         External APIs
```

---

# 5. Supabase Repository Layout

```text
supabase/
│
├── config.toml
├── seed.sql
│
├── migrations/
│   ├── 0001_private_schema.sql
│   ├── 0002_enums.sql
│   ├── 0003_profiles.sql
│   ├── 0004_restaurants.sql
│   ├── 0005_branches.sql
│   ├── 0006_menu.sql
│   ├── 0007_orders.sql
│   ├── 0008_payments.sql
│   ├── 0009_indexes.sql
│   ├── 0010_helpers.sql
│   ├── 0011_rpc.sql
│   ├── 0012_rls.sql
│   ├── 0013_grants.sql
│   ├── 0014_storage.sql
│   └── 0015_realtime.sql
│
├── functions/
│   ├── _shared/
│   ├── create-payment/
│   ├── payment-webhook/
│   ├── refund-payment/
│   └── send-order-notification/
│
└── tests/
    ├── rls/
    ├── orders/
    └── payments/
```

---

# 6. Environments

Use separate environments:

```text
Local
Development
Staging
Production
```

Recommended:

- Local: Supabase CLI/Docker
- Staging: dedicated Supabase project
- Production: separate Supabase project

Never test destructive migrations directly in production.

---

# 7. Flutter Supabase Initialization

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  publishableKey: const String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  ),
);
```

Flutter should only contain:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Never ship:

```text
SUPABASE_SECRET_KEY
legacy SERVICE_ROLE_KEY
PAYMENT_GATEWAY_SECRET
WEBHOOK_SECRET
FCM_SERVER_CREDENTIALS
WHATSAPP_SECRET
SMS_SECRET
```

---

# 8. Public vs Server Keys

```text
publishable/anon key
    → client-side
    → safe only with correct grants + RLS

secret/service-role style credentials
    → trusted server only
    → can bypass RLS
```

Never place elevated credentials inside APK, IPA, Flutter Web bundle, Git, or CI logs.

---

# 9. Database Schemas

Recommended:

```text
public
private
```

`public` contains tables/RPCs intentionally exposed through the Data API.

`private` contains authorization helper functions and internal objects.

```sql
create schema if not exists private;
```

Do not expose the `private` schema through the Data API.

---

# 10. Reusable Updated-At Trigger

```sql
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
```

Example:

```sql
create trigger trg_restaurants_updated_at
before update on public.restaurants
for each row
execute function private.set_updated_at();
```

---

# 11. Enums

## Staff roles

```sql
create type public.staff_role as enum (
  'owner',
  'manager',
  'cashier',
  'waiter',
  'kitchen'
);
```

## Order type

```sql
create type public.order_type as enum (
  'dine_in',
  'takeaway',
  'delivery'
);
```

## Order status

```sql
create type public.order_status as enum (
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

## Payment status

```sql
create type public.payment_status as enum (
  'pending',
  'authorized',
  'paid',
  'failed',
  'cancelled',
  'partially_refunded',
  'refunded'
);
```

## Payment method

```sql
create type public.payment_method as enum (
  'cash',
  'card',
  'upi',
  'wallet',
  'online'
);
```

## Discount type

```sql
create type public.discount_type as enum (
  'fixed',
  'percentage'
);
```

---

# 12. Profiles

Supabase Auth controls `auth.users`. Application data goes in `public.profiles`.

```sql
create table public.profiles (
  id uuid primary key
    references auth.users(id)
    on delete cascade,

  full_name text,
  phone text,
  avatar_path text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Optional automatic creation:

```sql
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    phone
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.phone
  )
  on conflict (id) do nothing;

  return new;
end;
$$;
```

```sql
create trigger trg_auth_user_profile
after insert on auth.users
for each row
execute function private.handle_new_user();
```

Do not use user-editable metadata for authorization roles.

---

# 13. Restaurants

```sql
create table public.restaurants (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  slug text not null unique,
  logo_path text,

  currency_code text not null default 'INR',
  timezone text not null default 'Asia/Kolkata',
  tax_inclusive boolean not null default false,

  is_active boolean not null default true,

  created_by uuid references auth.users(id),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

---

# 14. Restaurant Settings

```sql
create table public.restaurant_settings (
  restaurant_id uuid primary key
    references public.restaurants(id)
    on delete cascade,

  allow_dine_in boolean not null default true,
  allow_takeaway boolean not null default true,
  allow_delivery boolean not null default false,
  allow_guest_checkout boolean not null default true,

  require_payment_before_kitchen boolean
    not null default false,

  service_charge_basis_points integer
    not null default 0,

  default_tax_basis_points integer
    not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Basis points:

```text
18% = 1800
10% = 1000
5%  = 500
```

---

# 15. Restaurant Members

```sql
create table public.restaurant_members (
  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  role public.staff_role not null,
  is_active boolean not null default true,

  invited_by uuid references auth.users(id),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (restaurant_id, user_id)
);
```

One user can belong to multiple restaurants.

---

# 16. Branches

```sql
create table public.branches (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  name text not null,
  code text,
  phone text,

  address_line1 text,
  address_line2 text,
  city text,
  state text,
  postal_code text,
  country_code text not null default 'IN',

  latitude numeric,
  longitude numeric,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (restaurant_id, code)
);
```

---

# 17. Branch Members

Use this when non-owner staff are limited to specific branches.

```sql
create table public.branch_members (
  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  is_active boolean not null default true,
  created_at timestamptz not null default now(),

  primary key (branch_id, user_id)
);
```

Suggested rule:

```text
owner/manager → all branches of restaurant
cashier/waiter/kitchen → only branch_members assignments
```

---

# 18. Branch Opening Hours

```sql
create table public.branch_opening_hours (
  id uuid primary key default gen_random_uuid(),

  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  weekday smallint not null
    check (weekday between 0 and 6),

  opens_at time,
  closes_at time,
  is_closed boolean not null default false
);
```

If a branch has split shifts, allow multiple rows for the same weekday.

---

# 19. Dining Areas

```sql
create table public.dining_areas (
  id uuid primary key default gen_random_uuid(),

  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true
);
```

Examples:

```text
Ground Floor
Rooftop
Garden
VIP
```

---

# 20. Dining Tables

```sql
create table public.dining_tables (
  id uuid primary key default gen_random_uuid(),

  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  dining_area_id uuid
    references public.dining_areas(id)
    on delete set null,

  name text not null,
  capacity integer,

  qr_token uuid not null
    default gen_random_uuid()
    unique,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (branch_id, name)
);
```

Use the random `qr_token`, not a predictable numeric table ID, in public QR codes.

---

# 21. QR URL

Recommended:

```text
https://order.example.com/q/<qr_token>
```

Flow:

```text
QR token
 ↓
resolve_qr RPC
 ↓
active table?
 ↓
active branch?
 ↓
active restaurant?
 ↓
return safe ordering context
```

---

# 22. Categories

```sql
create table public.categories (
  id uuid primary key default gen_random_uuid(),

  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  name text not null,
  description text,
  image_path text,

  sort_order integer not null default 0,
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

---

# 23. Products

Store money in minor units.

```text
₹199.00 → 19900
₹99.50  → 9950
```

```sql
create table public.products (
  id uuid primary key default gen_random_uuid(),

  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  category_id uuid not null
    references public.categories(id),

  name text not null,
  description text,

  base_price_minor bigint not null
    check (base_price_minor >= 0),

  image_path text,
  is_veg boolean,

  is_available boolean not null default true,
  is_active boolean not null default true,

  sort_order integer not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Use `is_available=false` for temporarily sold out.

Use `is_active=false` for archived/removed.

---

# 24. Product Tags

Optional:

```sql
create table public.product_tags (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  name text not null,

  unique (restaurant_id, name)
);
```

```sql
create table public.product_tag_links (
  product_id uuid not null
    references public.products(id)
    on delete cascade,

  tag_id uuid not null
    references public.product_tags(id)
    on delete cascade,

  primary key (product_id, tag_id)
);
```

Examples:

```text
Bestseller
Spicy
Vegan
Chef Special
```

---

# 25. Modifier Groups

```sql
create table public.modifier_groups (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  name text not null,

  min_select integer not null default 0,
  max_select integer not null default 1,
  is_required boolean not null default false,

  sort_order integer not null default 0,
  is_active boolean not null default true,

  check (
    min_select >= 0
    and max_select >= min_select
  )
);
```

---

# 26. Modifiers

```sql
create table public.modifiers (
  id uuid primary key default gen_random_uuid(),

  group_id uuid not null
    references public.modifier_groups(id)
    on delete cascade,

  name text not null,
  price_delta_minor bigint not null default 0,

  sort_order integer not null default 0,
  is_available boolean not null default true,
  is_active boolean not null default true
);
```

---

# 27. Product Modifier Mapping

```sql
create table public.product_modifier_groups (
  product_id uuid not null
    references public.products(id)
    on delete cascade,

  modifier_group_id uuid not null
    references public.modifier_groups(id)
    on delete cascade,

  sort_order integer not null default 0,

  primary key (
    product_id,
    modifier_group_id
  )
);
```

---

# 28. Customer Addresses

For delivery later:

```sql
create table public.customer_addresses (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  label text,
  contact_name text,
  contact_phone text,

  address_line1 text not null,
  address_line2 text,
  landmark text,
  city text,
  state text,
  postal_code text,
  country_code text default 'IN',

  latitude numeric,
  longitude numeric,

  is_default boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

---

# 29. Orders

```sql
create table public.orders (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id),

  branch_id uuid not null
    references public.branches(id),

  table_id uuid
    references public.dining_tables(id),

  customer_id uuid
    references auth.users(id),

  order_number bigint,

  order_type public.order_type not null,
  status public.order_status not null default 'placed',

  currency_code text not null default 'INR',

  subtotal_minor bigint not null
    check (subtotal_minor >= 0),

  tax_minor bigint not null default 0
    check (tax_minor >= 0),

  service_charge_minor bigint not null default 0
    check (service_charge_minor >= 0),

  delivery_fee_minor bigint not null default 0
    check (delivery_fee_minor >= 0),

  discount_minor bigint not null default 0
    check (discount_minor >= 0),

  total_minor bigint not null
    check (total_minor >= 0),

  customer_name_snapshot text,
  customer_phone_snapshot text,
  customer_note text,

  idempotency_key text,

  placed_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Clients should not directly set monetary columns.

---

# 30. Human-Friendly Order Numbers

Keep UUID as the real identifier.

Display:

```text
#1042
```

Possible numbering strategies:

```text
global sequence
per restaurant sequence
per branch/day sequence
```

Never use the display order number for authorization.

---

# 31. Order Items

Snapshot name and price at order time.

```sql
create table public.order_items (
  id uuid primary key default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  product_id uuid
    references public.products(id),

  product_name text not null,
  unit_price_minor bigint not null,

  quantity integer not null
    check (quantity > 0),

  modifiers_total_minor bigint not null default 0,
  line_total_minor bigint not null,
  item_note text,

  created_at timestamptz not null default now()
);
```

---

# 32. Order Item Modifier Snapshots

```sql
create table public.order_item_modifiers (
  id uuid primary key default gen_random_uuid(),

  order_item_id uuid not null
    references public.order_items(id)
    on delete cascade,

  modifier_id uuid
    references public.modifiers(id),

  modifier_name text not null,
  price_delta_minor bigint not null default 0,

  created_at timestamptz not null default now()
);
```

---

# 33. Order Status History

```sql
create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  old_status public.order_status,
  new_status public.order_status not null,

  changed_by uuid
    references auth.users(id),

  reason text,

  created_at timestamptz not null default now()
);
```

Treat as append-only from the client perspective.

---

# 34. Payments

```sql
create table public.payments (
  id uuid primary key default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id),

  method public.payment_method,
  provider text,

  provider_order_id text,
  provider_payment_id text,

  amount_minor bigint not null
    check (amount_minor >= 0),

  currency_code text not null default 'INR',

  status public.payment_status not null default 'pending',

  failure_code text,
  failure_message text,

  provider_metadata jsonb,

  paid_at timestamptz,
  refunded_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Client direct write access should be extremely limited or disabled.

---

# 35. Refunds

```sql
create table public.payment_refunds (
  id uuid primary key default gen_random_uuid(),

  payment_id uuid not null
    references public.payments(id),

  amount_minor bigint not null
    check (amount_minor > 0),

  provider_refund_id text,
  reason text,

  requested_by uuid
    references auth.users(id),

  status text not null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Refunds must be server-controlled.

---

# 36. Webhook Event Ledger

```sql
create table public.webhook_events (
  id uuid primary key default gen_random_uuid(),

  provider text not null,
  provider_event_id text not null,
  event_type text,

  payload jsonb,

  processed_at timestamptz,
  processing_error text,

  created_at timestamptz not null default now(),

  unique (provider, provider_event_id)
);
```

Purpose:

- webhook idempotency
- debugging
- replay analysis

No client write access.

---

# 37. Coupons

Optional after MVP:

```sql
create table public.coupons (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  code text not null,
  discount_type public.discount_type not null,
  discount_value bigint not null,

  minimum_order_minor bigint not null default 0,
  maximum_discount_minor bigint,

  starts_at timestamptz,
  ends_at timestamptz,

  max_total_uses integer,
  max_uses_per_customer integer,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),

  unique (restaurant_id, code)
);
```

Coupon validation must be server-side.

---

# 38. Order Discounts

```sql
create table public.order_discounts (
  id uuid primary key default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  coupon_id uuid
    references public.coupons(id),

  code_snapshot text,
  discount_minor bigint not null,

  created_at timestamptz not null default now()
);
```

---

# 39. Device Tokens

```sql
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  token text not null,
  platform text,

  app_type text check (
    app_type in ('customer', 'merchant')
  ),

  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),

  unique (user_id, token)
);
```

---

# 40. Audit Logs

```sql
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid
    references public.restaurants(id),

  branch_id uuid
    references public.branches(id),

  actor_user_id uuid
    references auth.users(id),

  action text not null,
  entity_type text,
  entity_id uuid,

  metadata jsonb,

  created_at timestamptz not null default now()
);
```

Examples:

```text
product.price_changed
product.disabled
order.cancelled
payment.refund_requested
staff.role_changed
restaurant.settings_changed
```

Clients should not update/delete audit history.

---

# 41. Staff Invitations

Optional secure invitation flow:

```sql
create table public.staff_invitations (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  email text,
  phone text,
  role public.staff_role not null,

  token_hash text not null,
  expires_at timestamptz not null,

  invited_by uuid not null
    references auth.users(id),

  accepted_at timestamptz,
  created_at timestamptz not null default now()
);
```

Store a token hash, not the raw invitation secret.

---

# 42. Main Relationships

```text
auth.users
  ├── profiles
  ├── restaurant_members
  ├── branch_members
  ├── customer_addresses
  └── device_tokens

restaurants
  ├── restaurant_settings
  ├── restaurant_members
  ├── branches
  ├── modifier_groups
  ├── coupons
  └── audit_logs

branches
  ├── branch_members
  ├── opening_hours
  ├── dining_areas
  ├── dining_tables
  ├── categories
  ├── products
  └── orders

orders
  ├── order_items
  │    └── order_item_modifiers
  ├── order_status_history
  ├── payments
  │    └── payment_refunds
  └── order_discounts
```

---

# 43. Indexes

## Membership

```sql
create index idx_restaurant_members_user
on public.restaurant_members (
  user_id,
  restaurant_id
)
where is_active = true;
```

```sql
create index idx_branch_members_user
on public.branch_members (
  user_id,
  branch_id
)
where is_active = true;
```

## Menu

```sql
create index idx_categories_branch
on public.categories (
  branch_id,
  sort_order
)
where is_active = true;
```

```sql
create index idx_products_branch_category
on public.products (
  branch_id,
  category_id,
  sort_order
)
where is_active = true;
```

## Orders

```sql
create index idx_orders_branch_status_created
on public.orders (
  branch_id,
  status,
  created_at desc
);
```

```sql
create index idx_orders_customer_created
on public.orders (
  customer_id,
  created_at desc
)
where customer_id is not null;
```

## Payments

```sql
create unique index idx_payments_provider_order
on public.payments (
  provider,
  provider_order_id
)
where provider_order_id is not null;
```

```sql
create unique index idx_payments_provider_payment
on public.payments (
  provider,
  provider_payment_id
)
where provider_payment_id is not null;
```

## Idempotency

```sql
create unique index idx_orders_customer_idempotency
on public.orders (
  customer_id,
  idempotency_key
)
where
  customer_id is not null
  and idempotency_key is not null;
```

---

# 44. Authorization Helper — Restaurant Member

```sql
create or replace function private.is_restaurant_member(
  target_restaurant_id uuid
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
      rm.restaurant_id = target_restaurant_id
      and rm.user_id = (select auth.uid())
      and rm.is_active = true
  );
$$;
```

---

# 45. Authorization Helper — Role

```sql
create or replace function private.has_restaurant_role(
  target_restaurant_id uuid,
  allowed_roles public.staff_role[]
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
      rm.restaurant_id = target_restaurant_id
      and rm.user_id = (select auth.uid())
      and rm.is_active = true
      and rm.role = any(allowed_roles)
  );
$$;
```

---

# 46. Authorization Helper — Branch Access

```sql
create or replace function private.can_access_branch(
  target_branch_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.branches b
    join public.restaurant_members rm
      on rm.restaurant_id = b.restaurant_id
    where
      b.id = target_branch_id
      and rm.user_id = (select auth.uid())
      and rm.is_active = true
      and (
        rm.role in ('owner', 'manager')
        or exists (
          select 1
          from public.branch_members bm
          where
            bm.branch_id = b.id
            and bm.user_id = (select auth.uid())
            and bm.is_active = true
        )
      )
  );
$$;
```

---

# 47. Security-Definer Rules

For every `security definer` function:

```text
use private schema where possible
set search_path = ''
schema-qualify all tables/functions
keep logic minimal
revoke broad execution
explicitly grant only required roles
test non-member cases
```

Example:

```sql
revoke execute
on function private.is_restaurant_member(uuid)
from public;
```

Grant only what is necessary after testing policy behavior.

---

# 48. Enable RLS

Every exposed table needs RLS.

Example:

```sql
alter table public.restaurants enable row level security;
alter table public.branches enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payments enable row level security;
```

Do this for every client-exposed table.

---

# 49. Grants + RLS

RLS and SQL grants both matter.

Example public read:

```sql
grant select
on public.products
to anon, authenticated;
```

Example staff CRUD capability:

```sql
grant select, insert, update
on public.products
to authenticated;
```

RLS then decides which rows/actions are actually permitted.

Use least privilege.

---

# 50. Profile RLS

```sql
create policy profiles_select_self
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
);
```

```sql
create policy profiles_update_self
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
)
with check (
  id = (select auth.uid())
);
```

---

# 51. Restaurant RLS

```sql
create policy restaurants_select_member
on public.restaurants
for select
to authenticated
using (
  (select private.is_restaurant_member(id))
);
```

Public QR/menu access should preferably use controlled RPCs rather than broad restaurant table reads.

---

# 52. Branch RLS

```sql
create policy branches_select_staff
on public.branches
for select
to authenticated
using (
  (select private.can_access_branch(id))
);
```

---

# 53. Product RLS

Public active menu read is possible:

```sql
create policy products_public_read
on public.products
for select
to anon, authenticated
using (
  is_active = true
  and is_available = true
);
```

For tighter field exposure, prefer a `get_public_menu` RPC/view.

Authorized staff update:

```sql
create policy products_update_staff
on public.products
for update
to authenticated
using (
  (select private.can_access_branch(branch_id))
)
with check (
  (select private.can_access_branch(branch_id))
);
```

Add role checks if only owner/manager may edit menu.

---

# 54. Customer Order RLS

```sql
create policy orders_customer_read
on public.orders
for select
to authenticated
using (
  customer_id = (select auth.uid())
);
```

---

# 55. Staff Order RLS

```sql
create policy orders_staff_read
on public.orders
for select
to authenticated
using (
  (select private.can_access_branch(branch_id))
);
```

Multiple SELECT policies combine permissively, so customer ownership and staff branch access can coexist.

---

# 56. Do Not Directly Insert Orders from Flutter

Recommended:

```text
Flutter
 ↓
create_order RPC
 ↓
server validation
 ↓
transaction
```

Revoke direct insert/update access to critical financial fields where possible.

---

# 57. Order Item RLS

Access derives from the parent order.

Concept:

```sql
create policy order_items_read_authorized
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where
      o.id = order_items.order_id
      and (
        o.customer_id = (select auth.uid())
        or (select private.can_access_branch(o.branch_id))
      )
  )
);
```

Test policy performance and recursion carefully.

---

# 58. Payments Security

Recommended permissions:

```text
Customer:
  read sanitized status for own order
  no direct writes

Merchant:
  read authorized branch payment information
  no arbitrary paid/refunded status writes

Edge Function / trusted server:
  create/update gateway payment records
  process refunds
```

---

# 59. Audit Log Security

```text
client insert  → no
client update  → no
client delete  → no
authorized manager read → optional
trusted server insert → yes
```

---

# 60. Storage Buckets

Recommended:

```text
restaurant-assets
menu-images
avatars
```

Optional:

```text
receipts
documents
```

---

# 61. Storage Paths

Restaurant logo:

```text
restaurant-assets/<restaurant_id>/logo.webp
```

Product image:

```text
menu-images/<restaurant_id>/<branch_id>/products/<product_id>/main.webp
```

Avatar:

```text
avatars/<user_id>/avatar.webp
```

---

# 62. Public vs Private Buckets

For genuinely public menu images:

```text
public bucket
```

is simplest.

For private assets:

```text
private bucket + signed URL
```

Do not use signed-URL complexity when an image is intentionally public.

---

# 63. Storage Policies

Write policy must verify tenant membership.

Concept:

```text
path restaurant_id
matches restaurant the current user may manage
```

Also enforce:

```text
allowed MIME types
maximum file size
reasonable image dimensions
```

Never trust arbitrary folder paths from the client.

---

# 64. resolve_qr RPC

Recommended signature:

```text
resolve_qr(p_qr_token uuid)
```

Return only safe public fields:

```text
restaurant_id
restaurant_name
restaurant_logo_path
branch_id
branch_name
table_id
table_name
currency_code
ordering flags
```

Reference implementation:

```sql
create or replace function public.resolve_qr(
  p_qr_token uuid
)
returns table (
  restaurant_id uuid,
  restaurant_name text,
  restaurant_logo_path text,
  branch_id uuid,
  branch_name text,
  table_id uuid,
  table_name text,
  currency_code text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.id,
    r.name,
    r.logo_path,
    b.id,
    b.name,
    t.id,
    t.name,
    r.currency_code
  from public.dining_tables t
  join public.branches b
    on b.id = t.branch_id
  join public.restaurants r
    on r.id = b.restaurant_id
  where
    t.qr_token = p_qr_token
    and t.is_active = true
    and b.is_active = true
    and r.is_active = true
  limit 1;
$$;
```

Treat exposed `security definer` RPCs as privileged API endpoints and audit them carefully.

---

# 65. get_public_menu RPC

Recommended:

```text
get_public_menu(branch_id)
```

Avoid N+1 requests:

```text
categories
  then products per category
  then modifiers per product
```

Prefer one structured response.

Example response:

```json
{
  "restaurant": {
    "id": "...",
    "name": "Pizza House",
    "currency": "INR"
  },
  "branch": {
    "id": "...",
    "name": "Main Branch"
  },
  "categories": [
    {
      "id": "...",
      "name": "Pizza",
      "products": [
        {
          "id": "...",
          "name": "Farmhouse",
          "base_price_minor": 39900,
          "modifier_groups": []
        }
      ]
    }
  ]
}
```

Only expose fields the customer actually needs.

---

# 66. create_order RPC

This is the most important business operation.

Client input should contain IDs/quantities, not trusted prices.

Example:

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
      "modifier_ids": ["..."],
      "note": "No onion"
    }
  ],
  "customer_note": "..."
}
```

---

# 67. create_order Server Responsibilities

```text
1. Read auth.uid()
2. Validate restaurant/branch active
3. Validate table belongs to branch
4. Validate order type enabled
5. Validate branch ordering availability
6. Validate every product belongs to branch
7. Validate products active/available
8. Fetch product prices from DB
9. Validate modifier groups
10. Validate required modifier selections
11. Validate min/max modifier count
12. Fetch modifier prices from DB
13. Calculate item totals
14. Calculate subtotal
15. Calculate service charge
16. Calculate tax
17. Validate coupon
18. Calculate discount
19. Calculate delivery fee if needed
20. Calculate final total
21. Enforce idempotency
22. Insert order
23. Insert order item snapshots
24. Insert modifier snapshots
25. Insert discount snapshot
26. Insert initial status history
27. Return safe server-calculated response
```

---

# 68. Atomicity

Create order in one PostgreSQL transaction/function.

Never do this from Flutter:

```text
insert order
insert item 1
insert item 2
insert status
```

because a failure can leave partial data.

A server function ensures:

```text
all succeeds
or
all rolls back
```

---

# 69. create_order Response

Recommended:

```json
{
  "order_id": "...",
  "order_number": 1042,
  "status": "awaiting_payment",
  "currency_code": "INR",
  "subtotal_minor": 50000,
  "tax_minor": 2500,
  "service_charge_minor": 0,
  "discount_minor": 0,
  "total_minor": 52500,
  "payment_required": true
}
```

Flutter displays server values.

---

# 70. Initial Order Status

Cash/pay-later:

```text
placed
```

Online payment required before kitchen:

```text
awaiting_payment
```

Verified payment webhook:

```text
awaiting_payment → placed
```

---

# 71. Idempotency

Mobile clients retry requests.

Without protection:

```text
Order #100
Order #101
```

Use `idempotency_key`.

Same user + same key should return the existing order rather than create a duplicate.

Payments/webhooks also require idempotency.

---

# 72. change_order_status RPC

Never let staff arbitrarily update `orders.status`.

Use:

```text
change_order_status(
  order_id,
  new_status,
  reason
)
```

Server validates:

```text
staff identity
branch access
role permission
current status
legal next status
order type
```

---

# 73. Order State Machine

```text
awaiting_payment
  ├── payment success → placed
  └── cancelled/failed → cancelled

placed
  ├── accepted
  └── cancelled

accepted
  ├── preparing
  └── cancelled if policy permits

preparing
  └── ready

ready
  ├── served      (dine-in)
  └── completed   (takeaway where appropriate)

served
  └── completed
```

Reject invalid transitions such as:

```text
completed → preparing
```

---

# 74. Status Side Effects

After valid transition:

```text
update orders.status
insert order_status_history
set relevant timestamp
optionally enqueue/send notification
insert audit record if important
```

---

# 75. Payment Architecture

```text
Flutter
 ↓
create_order RPC
 ↓
awaiting_payment
 ↓
create-payment Edge Function
 ↓
payment provider
 ↓
customer payment
 ↓
provider webhook
 ↓
payment-webhook Edge Function
 ↓
signature verification
 ↓
payment = paid
 ↓
order = placed
 ↓
Realtime
 ↓
KDS
```

---

# 76. create-payment Edge Function

Responsibilities:

```text
authenticate caller
load order server-side
verify caller may pay order
read final amount from DB
prevent duplicate provider session
create provider order/session
store provider order ID
return public checkout data
```

Never accept the amount from Flutter as truth.

---

# 77. Payment Webhook Function

Responsibilities:

```text
receive raw provider request
verify signature
reject invalid signatures
parse event
check provider event id
find payment record
check amount
check currency
check provider identifiers
make event idempotent
update payment
update order
insert status history
log event
return success response
```

Webhook is authoritative, not the Flutter “success” callback.

---

# 78. Edge Function Secrets

Examples:

```text
RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET
RAZORPAY_WEBHOOK_SECRET
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET
FCM credentials
WHATSAPP credentials
SMS provider credentials
```

Use Supabase Function Secrets / environment variables.

Never commit secret `.env` files.

---

# 79. Edge Function Layout

```text
supabase/functions/
│
├── _shared/
│   ├── auth.ts
│   ├── cors.ts
│   ├── errors.ts
│   └── supabase.ts
│
├── create-payment/
│   └── index.ts
│
├── payment-webhook/
│   └── index.ts
│
├── refund-payment/
│   └── index.ts
│
└── send-order-notification/
    └── index.ts
```

---

# 80. Edge Function Client Strategy

For normal user-scoped operations:

```text
propagate user Authorization header
let RLS apply
```

Use elevated server credentials only where truly needed.

Do not use service-level access for every function by default.

---

# 81. Realtime Tables

Recommended for MVP:

```text
orders
order_status_history
```

Possibly:

```text
order_items
```

if order item edits are supported after placement.

Do not enable Realtime on every table automatically.

---

# 82. Customer Realtime

Customer subscribes only to their own order.

RLS must ensure:

```text
customer A cannot subscribe/read customer B order
```

---

# 83. Merchant Realtime

Merchant subscribes to active orders for an authorized branch.

RLS must enforce branch access.

Client filter:

```text
branch_id = X
```

is not authorization by itself.

---

# 84. Flutter Realtime Pattern

```dart
supabase
  .from('orders')
  .stream(primaryKey: ['id'])
  .eq('branch_id', branchId);
```

Or use channels/Postgres Changes for more control.

---

# 85. Realtime Reconnect Rule

On resume/reconnect:

```text
1. ensure session valid
2. re-subscribe
3. re-fetch active orders/order detail
4. reconcile current DB state
```

Realtime is not your durable history.

PostgreSQL remains source of truth.

---

# 86. KDS Query

Active statuses:

```text
placed
accepted
preparing
ready
```

Query:

```text
branch_id = current_branch
status in active statuses
order by created_at asc
```

Use the live-orders index.

---

# 87. Anonymous Customer Auth

Recommended guest flow:

```text
anonymous Supabase auth
 ↓
auth.uid() exists
 ↓
order ownership can use RLS
```

This is cleaner than completely unauthenticated private order history.

Customer can later verify phone/account depending on product flow.

---

# 88. Auth Strategy

Customer:

```text
anonymous
phone OTP
email OTP optional
social login optional
```

Merchant:

```text
email/password
phone OTP
MFA later
```

Authorization lives in membership tables, not user-editable profile metadata.

---

# 89. Restaurant Onboarding RPC

Recommended:

```text
create_restaurant(...)
```

Transaction:

```text
insert restaurant
insert settings
insert owner restaurant_members row using auth.uid()
insert first branch
insert audit record
```

Never accept arbitrary owner user ID from Flutter.

---

# 90. Staff Invitation Flow

```text
owner creates invitation
 ↓
server generates invitation token
 ↓
store token hash
 ↓
invite sent
 ↓
staff authenticates
 ↓
accept_staff_invitation RPC
 ↓
validate token + expiry
 ↓
insert restaurant_members
 ↓
optional branch_members
```

Do not allow a user to directly assign themselves owner/manager.

---

# 91. Multi-Tenant Integrity

Every branch-owned entity must remain inside one tenant.

Validate relationships such as:

```text
product.branch_id
category.branch_id
order.branch_id
table.branch_id
```

A product from Restaurant A must never reference a category from Restaurant B.

Foreign keys alone may not enforce every cross-tenant invariant.

Use:

```text
server functions
composite constraints
triggers where justified
```

---

# 92. Stronger Composite Constraints

Optional stronger pattern:

```sql
alter table public.categories
add constraint categories_id_branch_unique
unique (id, branch_id);
```

Then products can reference both:

```text
(category_id, branch_id)
```

This increases complexity but improves tenant consistency.

---

# 93. Money Rules

Use integer minor units.

Never use float/double as the authoritative stored amount.

```text
₹199.99 → 19999
$10.50  → 1050
```

---

# 94. Taxes

Tax configuration is server-side.

Flutter can show a preview but cannot determine final tax.

Future tables if needed:

```text
tax_rules
product_tax_categories
branch_tax_settings
```

---

# 95. Service Charge

Use basis points.

```text
10% = 1000
```

Formula concept:

```text
charge = subtotal × basis_points / 10000
```

Define rounding rules explicitly.

---

# 96. Discount Calculation Order

Document one exact calculation pipeline.

Example:

```text
item subtotal
 ↓
item discounts
 ↓
order discount
 ↓
service charge
 ↓
tax
 ↓
delivery fee
 ↓
final total
```

Choose the order that matches local tax/accounting rules.

---

# 97. Order Snapshot Principle

Store historical snapshots:

```text
product name
unit price
modifier name
modifier price
tax/discount values
currency
customer receipt contact if required
```

Never recalculate historical receipts from the current menu.

---

# 98. Soft Delete Strategy

Prefer:

```text
is_active = false
```

for:

```text
products
categories
tables
memberships
```

Use `is_available=false` for temporary sold-out products.

Transactional history should remain intact.

---

# 99. Views

Views can simplify reporting.

When exposed to clients, use secure view behavior.

Example:

```sql
create view public.active_orders_view
with (security_invoker = true)
as
select *
from public.orders
where status in (
  'placed',
  'accepted',
  'preparing',
  'ready'
);
```

Still test grants + RLS.

---

# 100. Dashboard RPC

Prefer:

```text
get_dashboard_summary(branch_id, from, to)
```

over many client queries.

Return:

```text
orders_count
paid_sales
average_order_value
cancelled_orders
active_orders
top_products
```

Always validate branch access inside the RPC.

---

# 101. Revenue Semantics

Decide whether revenue means:

```text
paid payment amount
completed cash orders
placed order totals
```

For online payments, verified successful payments are usually the safest accounting source.

Document the rule.

---

# 102. Push Notifications

Architecture:

```text
order/payment/status event
 ↓
Edge Function or notification job
 ↓
FCM/push provider
 ↓
device token
```

Use Realtime for open-app synchronization.

Use push for background attention.

---

# 103. Notification Queue Later

At scale:

```text
notification_jobs
```

Statuses:

```text
pending
processing
sent
failed
```

Notification failure should normally not invalidate a valid order/payment transaction.

---

# 104. Restaurant Closure Rules

Possible sources:

```text
is_active
opening hours
special closures
temporary pause
service-type pause
```

Checkout must validate availability server-side.

---

# 105. Special Closures

Optional:

```sql
create table public.branch_closures (
  id uuid primary key default gen_random_uuid(),

  branch_id uuid not null
    references public.branches(id)
    on delete cascade,

  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text
);
```

---

# 106. Delivery Zones Later

Possible tables:

```text
delivery_zones
delivery_zone_rules
```

Eligibility options:

```text
postal code
radius
polygon/PostGIS later
```

Backend calculates delivery eligibility and fee.

---

# 107. Inventory Future

Tables:

```text
ingredients
recipes
recipe_items
stock_locations
stock_transactions
suppliers
purchase_orders
purchase_order_items
waste_logs
```

Use an append-only stock movement ledger:

```text
purchase +100
sale -3
waste -2
adjustment +1
```

Do not implement naive read-modify-write stock updates under concurrency.

---

# 108. Loyalty Future

Tables:

```text
loyalty_accounts
loyalty_transactions
loyalty_rules
```

Use a transaction ledger, not only a mutable point balance.

---

# 109. Reservations Future

Tables:

```text
reservations
reservation_tables
reservation_status_history
```

Statuses:

```text
pending
confirmed
seated
completed
cancelled
no_show
```

---

# 110. SaaS Subscription Future

Tables:

```text
plans
plan_features
restaurant_subscriptions
subscription_events
restaurant_features
```

Backend must enforce paid feature limits.

Hiding a button in Flutter is not entitlement security.

---

# 111. Capability-Based Permissions Future

Possible permissions:

```text
orders.read
orders.accept
orders.cancel
orders.refund
payments.read
payments.refund
menu.read
menu.edit
staff.manage
reports.view
settings.edit
```

Tables:

```text
permissions
role_permissions
staff_permission_overrides
```

MVP can start with fixed roles.

---

# 112. Least Privilege Staff Design

Kitchen should ideally need:

```text
active order items
kitchen notes
status update capability
```

Kitchen should not automatically need:

```text
customer address
payment details
staff management
financial reports
```

Build toward granular least privilege.

---

# 113. Public Menu Field Safety

Do not expose entire product rows forever.

Future internal fields may include:

```text
cost_price
supplier_id
profit_margin
internal_notes
```

A public menu RPC/view lets you intentionally expose only customer-safe fields.

---

# 114. Table QR Rotation

Support:

```text
rotate_table_qr(table_id)
```

Use when:

```text
QR leaks
security incident
table changes
```

Changing `qr_token` invalidates the old QR.

---

# 115. Menu Versioning Optional

```sql
alter table public.branches
add column menu_version bigint
not null default 1;
```

Increment when:

```text
category changes
product changes
modifier changes
```

Customer can refresh only when version changes.

---

# 116. Realtime Is Not Needed for Everything

High value:

```text
orders
status history
```

Usually unnecessary for MVP:

```text
all menu tables
profiles
payments raw internals
audit logs
settings
```

Keep Realtime scope intentional.

---

# 117. Database Is the Source of Truth

```text
Realtime event = notification that state changed
PostgreSQL row = durable truth
```

On reconnect, query PostgreSQL again.

---

# 118. Offline POS Warning

True offline POS requires a different architecture:

```text
local durable database
local IDs
sync queue
conflict resolution
reconciliation
offline payment rules
```

Supabase Realtime alone does not create full offline POS.

---

# 119. Error Contract

Standardize errors.

Example:

```json
{
  "code": "PRODUCT_UNAVAILABLE",
  "message": "One item is no longer available",
  "details": {
    "product_id": "..."
  }
}
```

Useful codes:

```text
INVALID_QR
BRANCH_INACTIVE
RESTAURANT_CLOSED
INVALID_TABLE
PRODUCT_NOT_FOUND
PRODUCT_UNAVAILABLE
INVALID_MODIFIER
REQUIRED_MODIFIER_MISSING
COUPON_INVALID
COUPON_EXPIRED
ORDER_DUPLICATE
ORDER_NOT_PAYABLE
PAYMENT_ALREADY_COMPLETED
INVALID_STATUS_TRANSITION
UNAUTHORIZED
```

Flutter maps these to user-friendly UI.

---

# 120. Logging

Log useful identifiers:

```text
request ID
order ID
payment ID
provider event ID
restaurant ID
branch ID
actor user ID
error code
```

Never log:

```text
password
OTP
secret keys
full payment credentials
sensitive raw tokens
```

---

# 121. Rate Limiting Targets

Consider rate limiting:

```text
OTP requests
resolve_qr
create_order
coupon validation
payment creation
webhooks
login attempts
```

Do not rely only on disabled Flutter buttons.

---

# 122. Abuse Controls

Possible controls:

```text
max quantity per item
max order amount
max active orders per customer/session
coupon attempt limits
QR abuse detection
```

Especially useful with anonymous users.

---

# 123. Migration Strategy

Every database change goes through migrations.

Flow:

```text
change locally
 ↓
create migration
 ↓
reset/test local DB
 ↓
apply staging
 ↓
run RLS/integration tests
 ↓
review
 ↓
apply production
```

Do not rely on undocumented Dashboard edits.

---

# 124. Suggested Migration Order

```text
0001 private schema/extensions
0002 enums
0003 profiles
0004 restaurants/settings/members
0005 branches/branch members/hours
0006 dining areas/tables
0007 categories/products
0008 modifiers
0009 orders/items/status history
0010 payments/refunds/webhook events
0011 optional coupons
0012 devices/audit
0013 indexes
0014 helper functions
0015 RPCs
0016 RLS
0017 grants
0018 storage
0019 realtime
0020 seed updates
```

---

# 125. Seed Data

`seed.sql` may create:

```text
demo restaurant
demo branch
demo categories
demo products
demo modifiers
demo tables
```

Never include real customer data or production secrets.

---

# 126. RLS Tests

Required tests:

```text
customer A cannot read customer B order
restaurant A staff cannot read restaurant B
cashier cannot change owner membership
kitchen cannot refund payment
public user cannot edit menu
anonymous customer cannot read staff tables
owner can edit own restaurant
manager branch access works
waiter branch restriction works
```

RLS testing is mandatory for multi-tenant SaaS.

---

# 127. create_order Tests

Test:

```text
valid dine-in
valid takeaway
wrong table/branch
inactive table
inactive branch
inactive product
sold-out product
cross-branch product
invalid modifier
missing required modifier
too many modifiers
zero quantity
negative quantity
huge quantity
expired coupon
duplicate idempotency key
concurrent duplicate request
```

---

# 128. Payment Tests

```text
successful payment
failed payment
duplicate webhook
invalid signature
wrong amount
wrong currency
unknown provider order
partial refund
full refund
webhook before client success callback
client success callback before webhook
```

Webhook remains authoritative.

---

# 129. Realtime Tests

```text
new order reaches correct branch
order does not reach another restaurant
status reaches correct customer
reconnect catches latest state
logout removes subscriptions
token refresh keeps session behavior correct
```

---

# 130. Storage Tests

```text
customer cannot upload menu image
unauthorized staff cannot write another restaurant path
manager can upload own restaurant image
public can read intended public menu images
private files require authorization
```

---

# 131. RLS Performance

Index fields used by policies.

Common hot paths:

```text
restaurant_members.user_id
branch_members.user_id
orders.branch_id
orders.customer_id
products.branch_id
```

Use efficient stable helper functions.

Supabase documents optimization patterns such as using `(select auth.uid())` in appropriate policy expressions.

Benchmark real queries.

---

# 132. Query Pagination

Do not load all historical orders.

Use:

```text
date filters
page/range pagination
cursor/keyset pagination at scale
```

---

# 133. Time Zones

Use:

```text
timestamptz
```

for events.

Store restaurant timezone separately:

```text
Asia/Kolkata
```

Convert for display/reporting.

---

# 134. Currency

Snapshot currency on each order/payment.

Do not assume old orders always use the restaurant's current currency setting.

For MVP, one currency per restaurant is simplest.

---

# 135. Backups

Plan for:

```text
Supabase backups/PITR according to plan
pre-migration backup for risky changes
restore testing
critical data export where required
```

A backup strategy is incomplete until restore has been tested.

---

# 136. Privacy and Retention

Define retention for:

```text
orders
payments
webhook payloads
audit logs
device tokens
anonymous accounts
addresses
analytics events
```

Collect only needed PII.

---

# 137. Account Deletion

Do not blindly delete legally required transaction history.

A deletion workflow may:

```text
remove profile data
remove addresses
remove device tokens
remove marketing consent
anonymize customer references
preserve required financial/order records
```

Adapt to applicable legal/accounting requirements.

---

# 138. Monitoring

Monitor:

```text
database CPU/storage
slow queries
connection usage
Realtime usage
Edge Function failures
payment webhook failures
auth failures
storage growth
```

Use `EXPLAIN ANALYZE` in staging for heavy queries.

---

# 139. CI/CD Backend Pipeline

Recommended:

```text
SQL lint/review
 ↓
local migrations
 ↓
DB tests
 ↓
RLS tests
 ↓
Edge Function tests
 ↓
staging deploy
 ↓
integration tests
 ↓
manual approval
 ↓
production deploy
```

---

# 140. Migration Safety

For large production tables:

```text
avoid long blocking migrations
add nullable column first
backfill separately
add constraints after backfill
```

Before destructive changes:

```text
check mobile backward compatibility
backup
staging test
lock impact
rollback plan
```

---

# 141. API Backward Compatibility

Mobile users do not update instantly.

For major RPC contract changes consider:

```text
create_order_v1
create_order_v2
```

or maintain backward-compatible request fields temporarily.

---

# 142. App Configuration

Optional table/RPC can expose:

```text
customer_min_version
merchant_min_version
maintenance_mode
feature flags
```

Keep sensitive config private.

---

# 143. Suggested MVP Tables

Required first:

```text
profiles
restaurants
restaurant_settings
restaurant_members
branches
branch_members
dining_tables
categories
products
modifier_groups
modifiers
product_modifier_groups
orders
order_items
order_item_modifiers
order_status_history
payments
webhook_events
device_tokens
audit_logs
```

Useful soon after:

```text
opening hours
dining areas
payment_refunds
coupons
order_discounts
customer_addresses
```

---

# 144. Suggested MVP RPCs

```text
resolve_qr
get_public_menu
create_restaurant
create_order
change_order_status
get_order_details
rotate_table_qr
get_dashboard_summary
```

---

# 145. Suggested MVP Edge Functions

```text
create-payment
payment-webhook
send-order-notification
refund-payment
```

Later:

```text
send-whatsapp
send-sms
send-email
generate-receipt
```

---

# 146. Database vs Edge Function Decision

Use PostgreSQL/RPC for:

```text
transactions
pricing
order creation
status transitions
coupon validation
tenant-aware database operations
```

Use Edge Functions for:

```text
payment gateways
webhooks
push notifications
email/SMS/WhatsApp
external HTTP APIs
AI providers
```

---

# 147. Avoid Overusing Edge Functions

Simple menu CRUD can be:

```text
Flutter → Data API → RLS
```

Critical high-integrity flows should use controlled RPC/server operations.

---

# 148. Direct CRUD vs Controlled Functions

Good RLS CRUD candidates:

```text
categories
products
modifier groups
modifiers
tables
basic settings
```

Controlled RPC candidates:

```text
create restaurant
transfer ownership
accept staff invite
create order
change order status
rotate QR
apply high-integrity discount
```

Edge/server-only candidates:

```text
mark online payment paid
refund gateway payment
process webhook
send privileged notification
```

---

# 149. Complete Customer Order Sequence

```text
1. Customer gets anonymous/user Auth session
2. Customer scans QR
3. Flutter calls resolve_qr
4. Supabase validates table/branch/restaurant
5. Flutter calls get_public_menu
6. Customer builds cart locally
7. Flutter calls create_order
8. PostgreSQL validates products/modifiers
9. PostgreSQL calculates authoritative total
10. Snapshot rows inserted transactionally
11. Cash order → placed
12. Online order → awaiting_payment
13. Flutter invokes create-payment
14. Gateway handles payment
15. Gateway calls payment-webhook
16. Edge Function verifies signature
17. Payment becomes paid
18. Order becomes placed
19. Realtime reaches merchant KDS
20. Staff invokes change_order_status
21. Status history inserted
22. Customer receives Realtime status
23. Order completes
```

---

# 150. Complete Merchant Menu Sequence

```text
1. Merchant authenticates
2. JWT reaches Supabase
3. restaurant_members resolves tenant + role
4. branch_members resolves branch access
5. Merchant loads menu under RLS
6. Merchant edits product
7. RLS checks branch authorization
8. Storage policy checks upload authorization
9. DB stores new menu state
10. Customer receives new menu on refresh/load
```

---

# 151. Restaurant Onboarding Sequence

```text
1. Owner authenticates
2. create_restaurant RPC
3. restaurant inserted
4. settings inserted
5. owner membership inserted with auth.uid()
6. first branch inserted
7. categories/products created
8. table created
9. QR token generated
10. QR printed
```

---

# 152. Backend Truth Boundaries

Supabase owns truth for:

```text
identity
tenant membership
role
branch permission
product price
modifier price
availability
tax
service charge
coupon validity
discount
order total
order status
payment status
refund status
order history
```

Flutter owns:

```text
screen state
navigation
local cart
selected options
temporary subtotal preview
loading/error state
cached menu
```

---

# 153. Common Mistakes to Avoid

Do not:

```text
disable RLS “temporarily” and forget it
put service-role/secret key in Flutter
trust client price
trust client total
trust client role
let client mark payment paid
create an order through many independent inserts
allow cross-restaurant IDs without validation
recalculate old invoices from current product prices
enable Realtime everywhere
store large images in Postgres
commit secrets
put unsafe security-definer helpers in exposed schemas
forget SQL grants
skip RLS tests
```

---

# 154. Production Checklist

```text
[ ] RLS enabled on every exposed table
[ ] SQL grants reviewed
[ ] publishable key only in Flutter
[ ] server secrets only in trusted environment
[ ] membership helpers audited
[ ] security-definer search_path pinned
[ ] cross-tenant tests pass
[ ] product/modifier price server-calculated
[ ] create_order transactional
[ ] order idempotency works
[ ] historical snapshots stored
[ ] legal status transitions enforced
[ ] payment webhook signature verified
[ ] webhook idempotency works
[ ] refunds protected
[ ] Storage policies tested
[ ] Realtime isolation tested
[ ] active queries indexed
[ ] logs avoid secrets
[ ] backups configured
[ ] migrations rebuild local DB successfully
[ ] staging deployment tested
```

---

# 155. Migration Checklist Per Table

```text
[ ] primary key
[ ] foreign keys
[ ] delete behavior
[ ] constraints
[ ] timestamps
[ ] updated_at trigger if needed
[ ] indexes
[ ] RLS
[ ] policies
[ ] grants
[ ] Realtime decision
[ ] Storage relation if any
[ ] tests
```

---

# 156. RPC Checklist

```text
[ ] caller authenticated/identified as intended
[ ] tenant validated
[ ] branch validated
[ ] object relationships validated
[ ] no trusted client prices
[ ] no arbitrary privileged user IDs
[ ] search_path secure
[ ] grants minimal
[ ] idempotent where needed
[ ] structured errors
[ ] audit event where appropriate
```

---

# 157. Edge Function Checklist

```text
[ ] authentication validated
[ ] secrets server-side
[ ] input schema validated
[ ] tenant authorization checked
[ ] external timeout handled
[ ] idempotency handled
[ ] safe logs
[ ] structured errors
[ ] rate limits considered
[ ] CORS configured for web if required
```

---

# 158. Payment Checklist

```text
[ ] amount loaded server-side
[ ] currency loaded server-side
[ ] provider order ID unique
[ ] webhook signature verified
[ ] duplicate webhook safe
[ ] wrong amount rejected
[ ] wrong currency rejected
[ ] payment state machine defined
[ ] order/payment update coordinated
[ ] refund path server-controlled
[ ] audit logs exist
```

---

# 159. Realtime Checklist

```text
[ ] only required tables enabled
[ ] customer isolation tested
[ ] branch isolation tested
[ ] reconnect performs refetch
[ ] subscriptions removed on logout
[ ] active query indexed
[ ] database remains source of truth
```

---

# 160. Storage Checklist

```text
[ ] public/private bucket chosen intentionally
[ ] MIME types restricted
[ ] size limits applied
[ ] tenant-aware write policies
[ ] image compression
[ ] safe image replacement
[ ] orphan cleanup strategy
```

---

# 161. Auth Checklist

```text
[ ] anonymous customer strategy
[ ] phone/email strategy
[ ] merchant login strategy
[ ] staff invitation flow
[ ] owner assigned only server-side
[ ] membership tables define authorization
[ ] user metadata not trusted for roles
[ ] logout removes device tokens/subscriptions as appropriate
[ ] MFA roadmap
```

---

# 162. Phase 1 — Secure MVP Backend

Build:

```text
Auth
profiles
restaurants
restaurant_members
branches
branch_members
dining_tables
categories
products
modifiers
RLS/grants
resolve_qr
get_public_menu
orders
create_order
status history
Realtime
change_order_status
```

---

# 163. Phase 2 — Payments and Operations

Add:

```text
online payments
payment webhooks
refunds
push notifications
opening hours
coupons
order history
dashboard analytics
```

---

# 164. Phase 3 — Customer Growth Features

Add:

```text
delivery
customer addresses
delivery zones
loyalty
CRM
WhatsApp
reservations
```

---

# 165. Phase 4 — Inventory

Add:

```text
ingredients
recipes
stock ledger
waste
suppliers
purchase orders
```

---

# 166. Phase 5 — Enterprise SaaS

Add:

```text
advanced permissions
subscription plans
feature flags
franchise hierarchy
multi-branch reporting
accounting integrations
```

---

# 167. Phase 6 — AI

Add only after the operational core is stable:

```text
AI waiter
recommendations
menu translation
forecasting
marketing automation
```

---

# 168. Official Supabase References

Keep these current docs bookmarked:

- Flutter initialization: `https://supabase.com/docs/reference/dart/initializing`
- Flutter quickstart: `https://supabase.com/docs/guides/getting-started/quickstarts/flutter`
- Flutter reference: `https://supabase.com/docs/reference/dart/introduction`
- Row Level Security: `https://supabase.com/docs/guides/database/postgres/row-level-security`
- Data API security: `https://supabase.com/docs/guides/api/securing-your-api`
- Realtime: `https://supabase.com/docs/guides/realtime`
- Flutter Realtime subscriptions: `https://supabase.com/docs/reference/dart/subscribe`
- Edge Functions: `https://supabase.com/docs/guides/functions`
- Function secrets: `https://supabase.com/docs/guides/functions/secrets`
- Storage: `https://supabase.com/docs/guides/storage`
- Auth: `https://supabase.com/docs/guides/auth`
- Local development: `https://supabase.com/docs/guides/local-development`

Check current docs before using version-specific SDK/CLI syntax.

---

# 169. Final Architecture

```text
                       SUPABASE
                          │
          ┌───────────────┼───────────────┐
          │               │               │
        AUTH          POSTGRESQL        STORAGE
          │               │               │
          │          ┌────┴────┐          │
          │          │   RLS   │          │
          │          └────┬────┘          │
          │               │               │
          │       RPC / Transactions      │
          │               │               │
          └────────── REALTIME ───────────┘
                          │
                   EDGE FUNCTIONS
                          │
          ┌───────────────┼───────────────┐
          │               │               │
      PAYMENTS          PUSH        EXTERNAL APIs
          │
  ┌───────┴────────┐
  │                │
CUSTOMER APP   MERCHANT APP
```

---

# 170. Final Security Chain

```text
Flutter
 ↓
publishable key
 ↓
user JWT
 ↓
SQL grants
 ↓
RLS
 ↓
RPC validation
 ↓
constraints/transaction
 ↓
trusted database state
```

Payments:

```text
Payment Provider
 ↓
signed webhook
 ↓
Edge Function
 ↓
signature verification
 ↓
trusted server access
 ↓
payment/order update
```

---

# 171. Final Rules

1. Enable RLS on every exposed table.
2. Review SQL grants in addition to RLS.
3. Never place Supabase secret/service credentials in Flutter.
4. Use membership tables for authorization.
5. Keep privileged helper functions in a private schema where possible.
6. Pin `search_path` for `security definer` functions.
7. Never trust price, tax, discount, or totals from Flutter.
8. Create orders through one transactional server operation.
9. Store historical product/modifier snapshots.
10. Make checkout idempotent.
11. Verify online payments through signed server-side webhooks.
12. Make webhooks idempotent.
13. Validate order-state transitions on the backend.
14. Use PostgreSQL as durable truth; Realtime is synchronization.
15. Store files in Storage, not as large DB blobs.
16. Add indexes for tenant and active-order query paths.
17. Protect payments, refunds, and audit data from client writes.
18. Test RLS using multiple tenants and roles.
19. Version every backend change through migrations.
20. Build QR → menu → secure order → KDS before advanced features.

---

# 172. Backend MVP Completion Definition

The backend MVP is complete when:

```text
[ ] customer can authenticate anonymously
[ ] merchant can authenticate
[ ] owner can create/manage restaurant
[ ] restaurant isolation works
[ ] branch isolation works
[ ] merchant can manage menu securely
[ ] merchant can create table QR
[ ] resolve_qr is safe
[ ] public menu loads
[ ] customer cannot edit menu
[ ] create_order validates server-side
[ ] order creation is atomic
[ ] duplicate checkout prevented
[ ] item/modifier snapshots stored
[ ] live order reaches correct KDS
[ ] other restaurant cannot receive/read it
[ ] staff can only perform legal status transitions
[ ] customer sees live status
[ ] customer cannot read another customer's order
[ ] cash ordering works or online payment is verified server-side
[ ] RLS tests pass
[ ] core indexes exist
[ ] production secrets are server-side only
[ ] migrations rebuild the backend from scratch
```

---

# 173. Recommended Companion Backend Files

Create next:

```text
SUPABASE_DATABASE_SCHEMA.sql
SUPABASE_RLS_POLICIES.sql
SUPABASE_RPC_FUNCTIONS.sql
SUPABASE_STORAGE_POLICIES.sql
SUPABASE_REALTIME_SETUP.sql
SUPABASE_SEED.sql
SUPABASE_TEST_PLAN.md
PAYMENT_EDGE_FUNCTIONS.md
```

This Markdown file should remain the backend architecture/specification. Executable SQL should live in versioned migration files.

---

# 174. Recommended Implementation Order

```text
Schema
 ↓
Constraints
 ↓
Indexes
 ↓
Private authorization helpers
 ↓
RLS
 ↓
Grants
 ↓
Core RPCs
 ↓
Storage policies
 ↓
Realtime
 ↓
Edge Functions
 ↓
Payments
 ↓
Automated security tests
 ↓
Staging
 ↓
Production
```

The Supabase backend is correctly designed only when a malicious or modified Flutter client cannot cross restaurant boundaries, fake authority, manipulate pricing, fake payment, or create an invalid order state.
