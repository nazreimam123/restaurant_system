-- ============================================================================
-- DATABASE_SCHEMA.sql
-- QR Restaurant Ordering Platform
-- Flutter + GetX + MVC + Supabase
--
-- PURPOSE
--   Fresh-database baseline schema for the restaurant QR ordering platform.
--
-- INCLUDES
--   - private schema
--   - PostgreSQL extension(s)
--   - enums
--   - profiles
--   - restaurants / settings / memberships
--   - branches / branch settings / staff assignments
--   - opening hours / temporary closures
--   - dining areas / tables / QR tokens
--   - categories / products / tags
--   - modifier groups / modifiers / product mappings
--   - customer addresses
--   - orders / item snapshots / status history
--   - payments / refunds / webhook event ledger
--   - coupons / order discount snapshots
--   - device tokens
--   - staff invitations
--   - audit logs
--   - updated_at triggers
--   - auth.users -> profiles trigger
--   - indexes
--   - RLS ENABLE statements
--
-- DOES NOT INCLUDE
--   - RLS policies
--   - SQL grants
--   - RPC/business functions such as create_order
--   - Storage bucket policies
--   - Realtime publication setup
--   - Edge Functions
--
-- IMPORTANT
--   1. Run this against a NEW / EMPTY Supabase project or convert it into
--      ordered migrations.
--   2. RLS is enabled at the end of this file, but NO policies are created.
--      Client API access should therefore remain fail-closed until your
--      RLS policy migration is applied.
--   3. Money is stored as integer minor units:
--        INR 199.50 => 19950
--   4. Do not ship a Supabase secret/service-role key in Flutter.
--   5. Critical order/payment state changes belong in RPCs / Edge Functions,
--      not direct client table updates.
-- ============================================================================

begin;

-- ============================================================================
-- 1. EXTENSIONS AND PRIVATE SCHEMA
-- ============================================================================

create extension if not exists pgcrypto;

create schema if not exists private;

comment on schema private is
'Internal helpers and implementation details. Do not expose this schema through the Supabase Data API.';

-- ============================================================================
-- 2. ENUMS
-- ============================================================================

create type public.staff_role as enum (
  'owner',
  'manager',
  'cashier',
  'waiter',
  'kitchen'
);

create type public.order_type as enum (
  'dine_in',
  'takeaway',
  'delivery'
);

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

create type public.payment_status as enum (
  'pending',
  'authorized',
  'paid',
  'failed',
  'cancelled',
  'partially_refunded',
  'refunded'
);

create type public.payment_method as enum (
  'cash',
  'card',
  'upi',
  'wallet',
  'online'
);

create type public.refund_status as enum (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'cancelled'
);

create type public.discount_type as enum (
  'fixed',
  'percentage'
);

create type public.app_client_type as enum (
  'customer',
  'merchant'
);

-- ============================================================================
-- 3. COMMON UPDATED_AT TRIGGER
-- ============================================================================

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

revoke all
on function private.set_updated_at()
from public;

-- ============================================================================
-- 4. PROFILES
-- ============================================================================

create table public.profiles (
  id uuid primary key
    references auth.users(id)
    on delete cascade,

  full_name text,
  phone text,
  avatar_path text,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now()
);

comment on table public.profiles is
'Application profile data for Supabase Auth users. Authorization roles do not live here.';

create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 5. AUTH USER -> PROFILE TRIGGER
-- ============================================================================

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
    nullif(
      btrim(
        coalesce(
          new.raw_user_meta_data ->> 'full_name',
          ''
        )
      ),
      ''
    ),
    new.phone
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all
on function private.handle_new_user()
from public;

create trigger trg_auth_user_profile
after insert on auth.users
for each row
execute function private.handle_new_user();

-- ============================================================================
-- 6. RESTAURANTS
-- ============================================================================

create table public.restaurants (
  id uuid primary key
    default gen_random_uuid(),

  name text not null
    check (char_length(btrim(name)) between 1 and 160),

  slug text not null
    check (
      slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    ),

  logo_path text,

  currency_code text not null
    default 'INR'
    check (
      currency_code ~ '^[A-Z]{3}$'
    ),

  timezone text not null
    default 'Asia/Kolkata',

  tax_inclusive boolean not null
    default false,

  is_active boolean not null
    default true,

  created_by uuid
    references auth.users(id)
    on delete set null,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  unique (slug)
);

comment on table public.restaurants is
'Top-level SaaS tenant. Normal business deactivation should use is_active rather than hard deletion.';

create trigger trg_restaurants_updated_at
before update on public.restaurants
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 7. RESTAURANT SETTINGS
-- ============================================================================

create table public.restaurant_settings (
  restaurant_id uuid primary key
    references public.restaurants(id)
    on delete cascade,

  allow_dine_in boolean not null
    default true,

  allow_takeaway boolean not null
    default true,

  allow_delivery boolean not null
    default false,

  allow_guest_checkout boolean not null
    default true,

  require_payment_before_kitchen boolean not null
    default false,

  service_charge_basis_points integer not null
    default 0
    check (
      service_charge_basis_points
      between 0 and 10000
    ),

  default_tax_basis_points integer not null
    default 0
    check (
      default_tax_basis_points
      between 0 and 10000
    ),

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now()
);

comment on table public.restaurant_settings is
'Restaurant-level ordering defaults. Branch-specific overrides can be stored in branch_settings.';

create trigger trg_restaurant_settings_updated_at
before update on public.restaurant_settings
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 8. RESTAURANT MEMBERS
-- ============================================================================

create table public.restaurant_members (
  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  role public.staff_role not null,

  is_active boolean not null
    default true,

  invited_by uuid
    references auth.users(id)
    on delete set null,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  primary key (
    restaurant_id,
    user_id
  )
);

comment on table public.restaurant_members is
'Authoritative restaurant role membership. Do not use user-editable Auth metadata for staff authorization.';

create trigger trg_restaurant_members_updated_at
before update on public.restaurant_members
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 9. BRANCHES
-- ============================================================================

create table public.branches (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  name text not null
    check (char_length(btrim(name)) between 1 and 160),

  code text,

  phone text,

  address_line1 text,
  address_line2 text,
  city text,
  state text,
  postal_code text,

  country_code text not null
    default 'IN'
    check (
      country_code ~ '^[A-Z]{2}$'
    ),

  latitude numeric(9,6)
    check (
      latitude is null
      or latitude between -90 and 90
    ),

  longitude numeric(9,6)
    check (
      longitude is null
      or longitude between -180 and 180
    ),

  is_active boolean not null
    default true,

  menu_version bigint not null
    default 1
    check (menu_version > 0),

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  unique (
    id,
    restaurant_id
  ),

  unique (
    restaurant_id,
    code
  )
);

comment on table public.branches is
'Physical or logical restaurant outlet. Cross-tenant child tables use composite references to (id, restaurant_id).';

create trigger trg_branches_updated_at
before update on public.branches
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 10. BRANCH SETTINGS / OVERRIDES
-- ============================================================================

create table public.branch_settings (
  branch_id uuid primary key,

  restaurant_id uuid not null,

  -- NULL means inherit restaurant_settings.
  allow_dine_in boolean,
  allow_takeaway boolean,
  allow_delivery boolean,
  require_payment_before_kitchen boolean,

  service_charge_basis_points integer
    check (
      service_charge_basis_points is null
      or service_charge_basis_points
         between 0 and 10000
    ),

  default_tax_basis_points integer
    check (
      default_tax_basis_points is null
      or default_tax_basis_points
         between 0 and 10000
    ),

  is_ordering_paused boolean not null
    default false,

  ordering_pause_reason text,

  minimum_order_minor bigint
    check (
      minimum_order_minor is null
      or minimum_order_minor >= 0
    ),

  default_prep_minutes integer
    check (
      default_prep_minutes is null
      or default_prep_minutes between 1 and 1440
    ),

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint branch_settings_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade
);

comment on table public.branch_settings is
'Branch-specific operational overrides. Nullable override fields inherit restaurant_settings.';

create trigger trg_branch_settings_updated_at
before update on public.branch_settings
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 11. BRANCH MEMBERS
-- ============================================================================

create table public.branch_members (
  restaurant_id uuid not null,

  branch_id uuid not null,

  user_id uuid not null,

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  primary key (
    branch_id,
    user_id
  ),

  constraint branch_members_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint branch_members_restaurant_member_fk
    foreign key (
      restaurant_id,
      user_id
    )
    references public.restaurant_members(
      restaurant_id,
      user_id
    )
    on delete cascade
);

comment on table public.branch_members is
'Optional branch restriction for non-restaurant-wide staff. A branch member must also be a restaurant member.';

create trigger trg_branch_members_updated_at
before update on public.branch_members
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 12. BRANCH OPENING HOURS
-- ============================================================================

create table public.branch_opening_hours (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  branch_id uuid not null,

  weekday smallint not null
    check (weekday between 0 and 6),

  slot_order smallint not null
    default 0
    check (slot_order >= 0),

  opens_at time,
  closes_at time,

  is_closed boolean not null
    default false,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint branch_opening_hours_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint branch_opening_hours_state_check
    check (
      (
        is_closed = true
        and opens_at is null
        and closes_at is null
      )
      or
      (
        is_closed = false
        and opens_at is not null
        and closes_at is not null
      )
    ),

  unique (
    branch_id,
    weekday,
    slot_order
  )
);

comment on table public.branch_opening_hours is
'Supports one or multiple service windows per weekday by using slot_order. Overnight windows are allowed.';

create trigger trg_branch_opening_hours_updated_at
before update on public.branch_opening_hours
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 13. TEMPORARY BRANCH CLOSURES
-- ============================================================================

create table public.branch_closures (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  branch_id uuid not null,

  starts_at timestamptz not null,

  ends_at timestamptz not null,

  reason text,

  created_by uuid
    references auth.users(id)
    on delete set null,

  created_at timestamptz
    not null default now(),

  constraint branch_closures_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  check (ends_at > starts_at)
);

-- ============================================================================
-- 14. DINING AREAS
-- ============================================================================

create table public.dining_areas (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  branch_id uuid not null,

  name text not null
    check (char_length(btrim(name)) between 1 and 120),

  sort_order integer not null
    default 0,

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint dining_areas_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  unique (
    id,
    branch_id,
    restaurant_id
  ),

  unique (
    branch_id,
    name
  )
);

create trigger trg_dining_areas_updated_at
before update on public.dining_areas
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 15. DINING TABLES
-- ============================================================================

create table public.dining_tables (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  branch_id uuid not null,

  dining_area_id uuid,

  name text not null
    check (char_length(btrim(name)) between 1 and 120),

  capacity integer
    check (
      capacity is null
      or capacity > 0
    ),

  qr_token uuid not null
    default gen_random_uuid(),

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint dining_tables_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint dining_tables_area_fk
    foreign key (
      dining_area_id,
      branch_id,
      restaurant_id
    )
    references public.dining_areas(
      id,
      branch_id,
      restaurant_id
    ),

  unique (qr_token),

  unique (
    id,
    branch_id,
    restaurant_id
  ),

  unique (
    branch_id,
    name
  )
);

comment on table public.dining_tables is
'Public QR uses qr_token, not the predictable table UUID/name as authorization.';

create trigger trg_dining_tables_updated_at
before update on public.dining_tables
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 16. CATEGORIES
-- ============================================================================

create table public.categories (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  branch_id uuid not null,

  name text not null
    check (char_length(btrim(name)) between 1 and 160),

  description text,

  image_path text,

  sort_order integer not null
    default 0,

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint categories_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  unique (
    id,
    branch_id,
    restaurant_id
  )
);

create trigger trg_categories_updated_at
before update on public.categories
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 17. PRODUCTS
-- ============================================================================

create table public.products (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  branch_id uuid not null,

  category_id uuid not null,

  name text not null
    check (char_length(btrim(name)) between 1 and 200),

  description text,

  sku text,

  base_price_minor bigint not null
    check (base_price_minor >= 0),

  tax_basis_points_override integer
    check (
      tax_basis_points_override is null
      or tax_basis_points_override
         between 0 and 10000
    ),

  image_path text,

  is_veg boolean,

  is_available boolean not null
    default true,

  is_active boolean not null
    default true,

  sort_order integer not null
    default 0,

  preparation_minutes integer
    check (
      preparation_minutes is null
      or preparation_minutes between 0 and 1440
    ),

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint products_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint products_category_fk
    foreign key (
      category_id,
      branch_id,
      restaurant_id
    )
    references public.categories(
      id,
      branch_id,
      restaurant_id
    ),

  unique (
    id,
    restaurant_id
  ),

  unique (
    id,
    branch_id,
    restaurant_id
  ),

  unique (
    branch_id,
    sku
  )
);

comment on table public.products is
'Menu products. is_available is temporary sold-out state; is_active is archive/removal state.';

create trigger trg_products_updated_at
before update on public.products
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 18. PRODUCT TAGS
-- ============================================================================

create table public.product_tags (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  name text not null
    check (char_length(btrim(name)) between 1 and 80),

  created_at timestamptz
    not null default now(),

  unique (
    id,
    restaurant_id
  )
);

create unique index uq_product_tags_restaurant_name_ci
on public.product_tags (
  restaurant_id,
  lower(name)
);

create table public.product_tag_links (
  restaurant_id uuid not null,

  product_id uuid not null,

  tag_id uuid not null,

  created_at timestamptz
    not null default now(),

  primary key (
    product_id,
    tag_id
  ),

  constraint product_tag_links_product_fk
    foreign key (
      product_id,
      restaurant_id
    )
    references public.products(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint product_tag_links_tag_fk
    foreign key (
      tag_id,
      restaurant_id
    )
    references public.product_tags(
      id,
      restaurant_id
    )
    on delete cascade
);

-- ============================================================================
-- 19. MODIFIER GROUPS
-- ============================================================================

create table public.modifier_groups (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  name text not null
    check (char_length(btrim(name)) between 1 and 160),

  min_select integer not null
    default 0
    check (min_select >= 0),

  max_select integer not null
    default 1
    check (max_select >= 0),

  is_required boolean not null
    default false,

  sort_order integer not null
    default 0,

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  check (
    max_select >= min_select
  ),

  check (
    is_required = false
    or min_select >= 1
  ),

  unique (
    id,
    restaurant_id
  )
);

create trigger trg_modifier_groups_updated_at
before update on public.modifier_groups
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 20. MODIFIERS
-- ============================================================================

create table public.modifiers (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null,

  group_id uuid not null,

  name text not null
    check (char_length(btrim(name)) between 1 and 160),

  price_delta_minor bigint not null
    default 0,

  sort_order integer not null
    default 0,

  is_available boolean not null
    default true,

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint modifiers_group_fk
    foreign key (
      group_id,
      restaurant_id
    )
    references public.modifier_groups(
      id,
      restaurant_id
    )
    on delete cascade,

  unique (
    id,
    restaurant_id
  )
);

create trigger trg_modifiers_updated_at
before update on public.modifiers
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 21. PRODUCT <-> MODIFIER GROUP MAPPING
-- ============================================================================

create table public.product_modifier_groups (
  restaurant_id uuid not null,

  product_id uuid not null,

  modifier_group_id uuid not null,

  sort_order integer not null
    default 0,

  created_at timestamptz
    not null default now(),

  primary key (
    product_id,
    modifier_group_id
  ),

  constraint product_modifier_groups_product_fk
    foreign key (
      product_id,
      restaurant_id
    )
    references public.products(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint product_modifier_groups_group_fk
    foreign key (
      modifier_group_id,
      restaurant_id
    )
    references public.modifier_groups(
      id,
      restaurant_id
    )
    on delete cascade
);

-- ============================================================================
-- 22. CUSTOMER ADDRESSES
-- ============================================================================

create table public.customer_addresses (
  id uuid primary key
    default gen_random_uuid(),

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

  country_code text not null
    default 'IN'
    check (
      country_code ~ '^[A-Z]{2}$'
    ),

  latitude numeric(9,6)
    check (
      latitude is null
      or latitude between -90 and 90
    ),

  longitude numeric(9,6)
    check (
      longitude is null
      or longitude between -180 and 180
    ),

  is_default boolean not null
    default false,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now()
);

create trigger trg_customer_addresses_updated_at
before update on public.customer_addresses
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 23. ORDERS
-- ============================================================================

create table public.orders (
  id uuid primary key
    default gen_random_uuid(),

  order_number bigint generated by default as identity
    unique,

  restaurant_id uuid not null,

  branch_id uuid not null,

  table_id uuid,

  customer_id uuid
    references auth.users(id)
    on delete set null,

  order_type public.order_type not null,

  status public.order_status not null
    default 'placed',

  currency_code text not null
    default 'INR'
    check (
      currency_code ~ '^[A-Z]{3}$'
    ),

  subtotal_minor bigint not null
    check (subtotal_minor >= 0),

  tax_minor bigint not null
    default 0
    check (tax_minor >= 0),

  service_charge_minor bigint not null
    default 0
    check (service_charge_minor >= 0),

  delivery_fee_minor bigint not null
    default 0
    check (delivery_fee_minor >= 0),

  discount_minor bigint not null
    default 0
    check (discount_minor >= 0),

  total_minor bigint not null
    check (total_minor >= 0),

  customer_name_snapshot text,
  customer_phone_snapshot text,

  customer_note text
    check (
      customer_note is null
      or char_length(customer_note) <= 1000
    ),

  idempotency_key text
    check (
      idempotency_key is null
      or char_length(idempotency_key)
         between 8 and 128
    ),

  placed_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  constraint orders_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    ),

  constraint orders_table_fk
    foreign key (
      table_id,
      branch_id,
      restaurant_id
    )
    references public.dining_tables(
      id,
      branch_id,
      restaurant_id
    ),

  constraint orders_table_by_type_check
    check (
      (
        order_type = 'dine_in'
        and table_id is not null
      )
      or
      (
        order_type in ('takeaway', 'delivery')
        and table_id is null
      )
    ),

  unique (
    id,
    restaurant_id,
    branch_id
  )
);

comment on table public.orders is
'Authoritative order header. Financial values must be calculated server-side by create_order or equivalent trusted backend logic.';

create trigger trg_orders_updated_at
before update on public.orders
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 24. ORDER ITEMS (HISTORICAL SNAPSHOTS)
-- ============================================================================

create table public.order_items (
  id uuid primary key
    default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  product_id uuid
    references public.products(id)
    on delete set null,

  product_name text not null,

  unit_price_minor bigint not null
    check (unit_price_minor >= 0),

  quantity integer not null
    check (
      quantity between 1 and 999
    ),

  modifiers_total_minor bigint not null
    default 0,

  line_total_minor bigint not null
    check (line_total_minor >= 0),

  item_note text
    check (
      item_note is null
      or char_length(item_note) <= 500
    ),

  created_at timestamptz
    not null default now()
);

comment on table public.order_items is
'Historical product snapshots. Current product names/prices must not be used to reconstruct past receipts.';

-- ============================================================================
-- 25. ORDER ITEM MODIFIER SNAPSHOTS
-- ============================================================================

create table public.order_item_modifiers (
  id uuid primary key
    default gen_random_uuid(),

  order_item_id uuid not null
    references public.order_items(id)
    on delete cascade,

  modifier_id uuid
    references public.modifiers(id)
    on delete set null,

  modifier_name text not null,

  price_delta_minor bigint not null
    default 0,

  created_at timestamptz
    not null default now()
);

-- ============================================================================
-- 26. ORDER STATUS HISTORY
-- ============================================================================

create table public.order_status_history (
  id uuid primary key
    default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  old_status public.order_status,

  new_status public.order_status not null,

  changed_by uuid
    references auth.users(id)
    on delete set null,

  reason text,

  created_at timestamptz
    not null default now()
);

comment on table public.order_status_history is
'Append-only status transition history. Client UPDATE/DELETE should be prohibited by RLS/grants.';

-- ============================================================================
-- 27. PAYMENTS
-- ============================================================================

create table public.payments (
  id uuid primary key
    default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id),

  method public.payment_method not null,

  provider text,

  provider_order_id text,
  provider_payment_id text,

  amount_minor bigint not null
    check (amount_minor >= 0),

  currency_code text not null
    default 'INR'
    check (
      currency_code ~ '^[A-Z]{3}$'
    ),

  status public.payment_status not null
    default 'pending',

  failure_code text,
  failure_message text,

  provider_metadata jsonb,

  paid_at timestamptz,
  refunded_at timestamptz,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  check (
    method = 'cash'
    or provider is not null
  )
);

comment on table public.payments is
'Payment state is server-controlled. Flutter must never mark a provider payment paid based only on client SDK callbacks.';

create trigger trg_payments_updated_at
before update on public.payments
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 28. PAYMENT REFUNDS
-- ============================================================================

create table public.payment_refunds (
  id uuid primary key
    default gen_random_uuid(),

  payment_id uuid not null
    references public.payments(id),

  amount_minor bigint not null
    check (amount_minor > 0),

  provider_refund_id text,

  reason text,

  requested_by uuid
    references auth.users(id)
    on delete set null,

  idempotency_key text
    check (
      idempotency_key is null
      or char_length(idempotency_key)
         between 8 and 128
    ),

  status public.refund_status not null
    default 'pending',

  failure_code text,
  failure_message text,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now()
);

create trigger trg_payment_refunds_updated_at
before update on public.payment_refunds
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 29. PAYMENT / EXTERNAL WEBHOOK EVENT LEDGER
-- ============================================================================

create table public.webhook_events (
  id uuid primary key
    default gen_random_uuid(),

  provider text not null,

  provider_event_id text not null,

  event_type text,

  payload jsonb,

  processed_at timestamptz,

  processing_error text,

  created_at timestamptz
    not null default now(),

  unique (
    provider,
    provider_event_id
  )
);

comment on table public.webhook_events is
'Idempotency/debug ledger for external webhooks. Do not expose this table to Flutter clients.';

-- ============================================================================
-- 30. COUPONS
-- ============================================================================

create table public.coupons (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  code text not null
    check (char_length(btrim(code)) between 1 and 80),

  discount_type public.discount_type not null,

  -- fixed      => minor currency units
  -- percentage => basis points (10000 = 100%)
  discount_value bigint not null
    check (discount_value > 0),

  minimum_order_minor bigint not null
    default 0
    check (minimum_order_minor >= 0),

  maximum_discount_minor bigint
    check (
      maximum_discount_minor is null
      or maximum_discount_minor >= 0
    ),

  starts_at timestamptz,
  ends_at timestamptz,

  max_total_uses integer
    check (
      max_total_uses is null
      or max_total_uses > 0
    ),

  max_uses_per_customer integer
    check (
      max_uses_per_customer is null
      or max_uses_per_customer > 0
    ),

  is_active boolean not null
    default true,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  check (
    starts_at is null
    or ends_at is null
    or ends_at > starts_at
  ),

  check (
    discount_type <> 'percentage'
    or discount_value <= 10000
  )
);

create unique index uq_coupons_restaurant_code_ci
on public.coupons (
  restaurant_id,
  lower(code)
);

create trigger trg_coupons_updated_at
before update on public.coupons
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 31. ORDER DISCOUNT SNAPSHOTS
-- ============================================================================

create table public.order_discounts (
  id uuid primary key
    default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  coupon_id uuid
    references public.coupons(id)
    on delete set null,

  code_snapshot text,

  discount_type public.discount_type,

  discount_value_snapshot bigint,

  discount_minor bigint not null
    check (discount_minor > 0),

  created_at timestamptz
    not null default now()
);

-- ============================================================================
-- 32. DEVICE TOKENS
-- ============================================================================

create table public.device_tokens (
  id uuid primary key
    default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  token text not null,

  platform text
    check (
      platform is null
      or platform in (
        'android',
        'ios',
        'web',
        'windows',
        'macos',
        'linux'
      )
    ),

  app_type public.app_client_type not null,

  is_active boolean not null
    default true,

  last_seen_at timestamptz not null
    default now(),

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  unique (
    token,
    app_type
  )
);

create trigger trg_device_tokens_updated_at
before update on public.device_tokens
for each row
execute function private.set_updated_at();

-- ============================================================================
-- 33. STAFF INVITATIONS
-- ============================================================================

create table public.staff_invitations (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete cascade,

  email text,
  phone text,

  role public.staff_role not null,

  token_hash text not null
    unique,

  expires_at timestamptz not null,

  invited_by uuid not null
    references auth.users(id),

  accepted_at timestamptz,
  revoked_at timestamptz,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now(),

  check (
    email is not null
    or phone is not null
  ),

  check (
    expires_at > created_at
  ),

  unique (
    id,
    restaurant_id
  )
);

create trigger trg_staff_invitations_updated_at
before update on public.staff_invitations
for each row
execute function private.set_updated_at();

create table public.staff_invitation_branches (
  invitation_id uuid not null,

  restaurant_id uuid not null,

  branch_id uuid not null,

  created_at timestamptz
    not null default now(),

  primary key (
    invitation_id,
    branch_id
  ),

  constraint staff_invitation_branches_invitation_fk
    foreign key (
      invitation_id,
      restaurant_id
    )
    references public.staff_invitations(
      id,
      restaurant_id
    )
    on delete cascade,

  constraint staff_invitation_branches_branch_fk
    foreign key (
      branch_id,
      restaurant_id
    )
    references public.branches(
      id,
      restaurant_id
    )
    on delete cascade
);

-- ============================================================================
-- 34. AUDIT LOGS
-- ============================================================================

create table public.audit_logs (
  id uuid primary key
    default gen_random_uuid(),

  restaurant_id uuid
    references public.restaurants(id),

  branch_id uuid
    references public.branches(id),

  actor_user_id uuid
    references auth.users(id)
    on delete set null,

  action text not null
    check (char_length(btrim(action)) between 1 and 160),

  entity_type text,
  entity_id uuid,

  metadata jsonb,

  created_at timestamptz
    not null default now()
);

comment on table public.audit_logs is
'Append-only operational audit ledger for sensitive merchant/admin actions.';

-- ============================================================================
-- 35. CORE INDEXES
-- ============================================================================

-- Restaurant / staff membership.
create index idx_restaurant_members_user_active
on public.restaurant_members (
  user_id,
  restaurant_id
)
where is_active = true;

create index idx_restaurant_members_restaurant_role
on public.restaurant_members (
  restaurant_id,
  role
)
where is_active = true;

-- Branches / branch membership.
create index idx_branches_restaurant_active
on public.branches (
  restaurant_id,
  is_active,
  name
);

create index idx_branch_members_user_active
on public.branch_members (
  user_id,
  branch_id
)
where is_active = true;

create index idx_branch_members_restaurant_user
on public.branch_members (
  restaurant_id,
  user_id
)
where is_active = true;

-- Opening / closure queries.
create index idx_branch_opening_hours_branch_weekday
on public.branch_opening_hours (
  branch_id,
  weekday,
  slot_order
);

create index idx_branch_closures_branch_time
on public.branch_closures (
  branch_id,
  starts_at,
  ends_at
);

-- Tables.
create index idx_dining_areas_branch_sort
on public.dining_areas (
  branch_id,
  sort_order,
  name
)
where is_active = true;

create index idx_dining_tables_branch_active
on public.dining_tables (
  branch_id,
  is_active,
  name
);

-- Menu.
create index idx_categories_branch_sort_active
on public.categories (
  branch_id,
  sort_order,
  name
)
where is_active = true;

create index idx_products_branch_category_sort_active
on public.products (
  branch_id,
  category_id,
  sort_order,
  name
)
where is_active = true;

create index idx_products_branch_available
on public.products (
  branch_id,
  is_available,
  sort_order
)
where is_active = true;

create index idx_product_tag_links_product
on public.product_tag_links (
  product_id
);

create index idx_modifier_groups_restaurant_active
on public.modifier_groups (
  restaurant_id,
  sort_order,
  name
)
where is_active = true;

create index idx_modifiers_group_active
on public.modifiers (
  group_id,
  sort_order,
  name
)
where is_active = true;

create index idx_product_modifier_groups_product_sort
on public.product_modifier_groups (
  product_id,
  sort_order
);

-- Customer.
create index idx_customer_addresses_user
on public.customer_addresses (
  user_id,
  is_default desc,
  created_at desc
);

-- Orders / KDS.
create index idx_orders_branch_status_created
on public.orders (
  branch_id,
  status,
  created_at desc
);

create index idx_orders_branch_created
on public.orders (
  branch_id,
  created_at desc
);

create index idx_orders_restaurant_created
on public.orders (
  restaurant_id,
  created_at desc
);

create index idx_orders_customer_created
on public.orders (
  customer_id,
  created_at desc
)
where customer_id is not null;

create index idx_orders_table_created
on public.orders (
  table_id,
  created_at desc
)
where table_id is not null;

create unique index uq_orders_customer_idempotency
on public.orders (
  customer_id,
  idempotency_key
)
where
  customer_id is not null
  and idempotency_key is not null;

create index idx_order_items_order
on public.order_items (
  order_id,
  created_at
);

create index idx_order_item_modifiers_item
on public.order_item_modifiers (
  order_item_id,
  created_at
);

create index idx_order_status_history_order_created
on public.order_status_history (
  order_id,
  created_at
);

-- Payments.
create index idx_payments_order_created
on public.payments (
  order_id,
  created_at desc
);

create index idx_payments_status_created
on public.payments (
  status,
  created_at desc
);

create unique index uq_payments_provider_order
on public.payments (
  provider,
  provider_order_id
)
where
  provider is not null
  and provider_order_id is not null;

create unique index uq_payments_provider_payment
on public.payments (
  provider,
  provider_payment_id
)
where
  provider is not null
  and provider_payment_id is not null;

create index idx_payment_refunds_payment_created
on public.payment_refunds (
  payment_id,
  created_at desc
);

create unique index uq_payment_refunds_payment_idempotency
on public.payment_refunds (
  payment_id,
  idempotency_key
)
where idempotency_key is not null;

create unique index uq_payment_refunds_provider_refund
on public.payment_refunds (
  provider_refund_id
)
where provider_refund_id is not null;

-- Coupons.
create index idx_coupons_restaurant_active_dates
on public.coupons (
  restaurant_id,
  is_active,
  starts_at,
  ends_at
);

create index idx_order_discounts_order
on public.order_discounts (
  order_id,
  created_at
);

-- Device tokens.
create index idx_device_tokens_user_active
on public.device_tokens (
  user_id,
  app_type,
  is_active
);

-- Staff invitations.
create index idx_staff_invitations_restaurant_active
on public.staff_invitations (
  restaurant_id,
  expires_at
)
where
  accepted_at is null
  and revoked_at is null;

create index idx_staff_invitations_email
on public.staff_invitations (
  restaurant_id,
  lower(email)
)
where email is not null;

create index idx_staff_invitations_phone
on public.staff_invitations (
  restaurant_id,
  phone
)
where phone is not null;

-- Audit.
create index idx_audit_logs_restaurant_created
on public.audit_logs (
  restaurant_id,
  created_at desc
);

create index idx_audit_logs_branch_created
on public.audit_logs (
  branch_id,
  created_at desc
)
where branch_id is not null;

create index idx_audit_logs_actor_created
on public.audit_logs (
  actor_user_id,
  created_at desc
)
where actor_user_id is not null;

-- Webhooks.
create index idx_webhook_events_provider_created
on public.webhook_events (
  provider,
  created_at desc
);

create index idx_webhook_events_unprocessed
on public.webhook_events (
  created_at
)
where processed_at is null;

-- ============================================================================
-- 36. ENABLE ROW LEVEL SECURITY (FAIL-CLOSED)
-- ============================================================================
--
-- Policies are intentionally NOT defined in this file.
-- Apply RLS policy/grant migrations next.
-- ============================================================================

alter table public.profiles
enable row level security;

alter table public.restaurants
enable row level security;

alter table public.restaurant_settings
enable row level security;

alter table public.restaurant_members
enable row level security;

alter table public.branches
enable row level security;

alter table public.branch_settings
enable row level security;

alter table public.branch_members
enable row level security;

alter table public.branch_opening_hours
enable row level security;

alter table public.branch_closures
enable row level security;

alter table public.dining_areas
enable row level security;

alter table public.dining_tables
enable row level security;

alter table public.categories
enable row level security;

alter table public.products
enable row level security;

alter table public.product_tags
enable row level security;

alter table public.product_tag_links
enable row level security;

alter table public.modifier_groups
enable row level security;

alter table public.modifiers
enable row level security;

alter table public.product_modifier_groups
enable row level security;

alter table public.customer_addresses
enable row level security;

alter table public.orders
enable row level security;

alter table public.order_items
enable row level security;

alter table public.order_item_modifiers
enable row level security;

alter table public.order_status_history
enable row level security;

alter table public.payments
enable row level security;

alter table public.payment_refunds
enable row level security;

alter table public.webhook_events
enable row level security;

alter table public.coupons
enable row level security;

alter table public.order_discounts
enable row level security;

alter table public.device_tokens
enable row level security;

alter table public.staff_invitations
enable row level security;

alter table public.staff_invitation_branches
enable row level security;

alter table public.audit_logs
enable row level security;

-- ============================================================================
-- 37. FINAL NOTES
-- ============================================================================
--
-- NEXT FILES TO APPLY / IMPLEMENT:
--
--   1. RLS_POLICIES.sql
--      - private membership helper functions
--      - customer policies
--      - merchant policies
--      - least-privilege grants
--
--   2. RPC_FUNCTIONS.sql
--      - resolve_qr
--      - get_public_menu
--      - create_restaurant
--      - create_order
--      - change_order_status
--      - confirm_cash_payment
--      - rotate_table_qr
--      - get_dashboard_summary
--
--   3. STORAGE_POLICIES.sql
--      - restaurant-assets
--      - menu-images
--      - avatars
--
--   4. REALTIME_SETUP.sql
--      - orders
--      - order_status_history
--
--   5. EDGE FUNCTIONS
--      - create-payment
--      - payment-webhook
--      - refund-payment
--      - push notifications
--
-- IMPORTANT BUSINESS RULES THAT ARE NOT SIMPLE TABLE CONSTRAINTS:
--
--   - final price/tax/discount calculations
--   - product availability checks at checkout
--   - modifier min/max validation against selected product
--   - coupon usage limits
--   - opening-hours checks
--   - order-status transition rules
--   - payment state transitions
--   - refund limits / staff permissions
--   - order/payment idempotency response behavior
--
-- Those rules must be enforced by trusted RPCs / Edge Functions.
-- ============================================================================

commit;
