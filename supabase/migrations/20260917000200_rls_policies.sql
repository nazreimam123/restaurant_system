-- ============================================================================
-- RLS_POLICIES.sql
-- QR Restaurant Ordering Platform
-- Supabase Row Level Security + Least-Privilege Grants
--
-- Requires:
--   DATABASE_SCHEMA.sql
--
-- Designed for:
--   - Supabase anonymous-auth customers (Postgres role = authenticated)
--   - Merchant roles stored in public.restaurant_members
--   - Branch assignments stored in public.branch_members
--   - Multi-tenant restaurant / branch isolation
--
-- SECURITY MODEL
--   Customer:
--     - own profile
--     - own addresses
--     - own orders and order history
--     - own device tokens
--     - public menu / QR through trusted RPCs
--
--   Owner:
--     - all branches in restaurant
--     - menu / tables / settings / staff visibility
--     - financial visibility
--
--   Manager:
--     - all branches in restaurant
--     - operational menu / table / branch management
--     - staff visibility
--     - financial visibility
--     - owner-sensitive mutations should still use trusted RPCs
--
--   Cashier:
--     - assigned branches only
--     - orders + payment visibility
--
--   Waiter:
--     - assigned branches only
--     - orders + table/menu operational reads
--
--   Kitchen:
--     - assigned branches only
--     - orders/menu reads required by KDS
--
-- IMPORTANT
--   1. RLS is row-level, not role-specific column privacy.
--   2. The current orders table contains customer snapshot fields in the same
--      row used for Postgres Changes Realtime. An authorized branch staff member
--      who can SELECT that order row can potentially query all granted columns.
--      If strict kitchen-vs-cashier column privacy is required, move PII into a
--      separately protected table or migrate KDS/live-order delivery to a
--      sanitized server/Broadcast contract.
--   3. Critical writes remain blocked from direct clients:
--        create order
--        order status transition
--        payment state mutation
--        refunds
--        staff membership mutation
--        audit insertion
--        webhook insertion
--      These belong in RPCs / Edge Functions.
--   4. This file intentionally grants no direct access to anon.
--      Supabase anonymous-auth users assume the authenticated role.
--   5. private schema must NOT be exposed through the Supabase Data API.
-- ============================================================================

begin;

-- ============================================================================
-- 1. PRIVATE SCHEMA ACCESS
-- ============================================================================

revoke all on schema private from public;

-- Policies need authenticated callers to be able to execute the helper
-- functions. The schema itself should remain absent from the Data API's exposed
-- schemas configuration.
grant usage on schema private to authenticated;

-- ============================================================================
-- 2. SECURITY-DEFINER AUTHORIZATION HELPERS
-- ============================================================================
--
-- Every helper:
--   - derives identity from auth.uid()
--   - uses SECURITY DEFINER
--   - pins search_path to ''
--   - schema-qualifies every referenced object
--   - returns only authorization facts about the current caller
--
-- Never accept a user_id argument for authorization.
-- ============================================================================

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
    where rm.restaurant_id = target_restaurant_id
      and rm.user_id = (select auth.uid())
      and rm.is_active = true
  );
$$;

create or replace function private.restaurant_role(
  target_restaurant_id uuid
)
returns public.staff_role
language sql
stable
security definer
set search_path = ''
as $$
  select rm.role
  from public.restaurant_members rm
  where rm.restaurant_id = target_restaurant_id
    and rm.user_id = (select auth.uid())
    and rm.is_active = true
  limit 1;
$$;

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
    where rm.restaurant_id = target_restaurant_id
      and rm.user_id = (select auth.uid())
      and rm.is_active = true
      and rm.role = any(allowed_roles)
  );
$$;

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
     and rm.user_id = (select auth.uid())
     and rm.is_active = true
    where b.id = target_branch_id
      and (
        rm.role in (
          'owner'::public.staff_role,
          'manager'::public.staff_role
        )
        or exists (
          select 1
          from public.branch_members bm
          where bm.restaurant_id = b.restaurant_id
            and bm.branch_id = b.id
            and bm.user_id = (select auth.uid())
            and bm.is_active = true
        )
      )
  );
$$;

create or replace function private.can_manage_branch(
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
     and rm.user_id = (select auth.uid())
     and rm.is_active = true
    where b.id = target_branch_id
      and rm.role in (
        'owner'::public.staff_role,
        'manager'::public.staff_role
      )
  );
$$;

create or replace function private.can_manage_staff(
  target_restaurant_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.has_restaurant_role(
    target_restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  );
$$;

create or replace function private.can_access_product(
  target_product_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.products p
    where p.id = target_product_id
      and private.can_access_branch(p.branch_id)
  );
$$;

create or replace function private.can_manage_product(
  target_product_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.products p
    where p.id = target_product_id
      and private.can_manage_branch(p.branch_id)
  );
$$;

create or replace function private.owns_order(
  target_order_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.orders o
    where o.id = target_order_id
      and o.customer_id = (select auth.uid())
  );
$$;

create or replace function private.can_read_order(
  target_order_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.orders o
    where o.id = target_order_id
      and (
        o.customer_id = (select auth.uid())
        or private.can_access_branch(o.branch_id)
      )
  );
$$;

create or replace function private.can_read_order_item(
  target_order_item_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.order_items oi
    where oi.id = target_order_item_id
      and private.can_read_order(oi.order_id)
  );
$$;

create or replace function private.can_view_order_financials(
  target_order_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.orders o
    where o.id = target_order_id
      and private.can_access_branch(o.branch_id)
      and private.has_restaurant_role(
        o.restaurant_id,
        array[
          'owner'::public.staff_role,
          'manager'::public.staff_role,
          'cashier'::public.staff_role
        ]
      )
  );
$$;

-- Helpers are not directly useful to unauthenticated callers.
revoke all
on function private.is_restaurant_member(uuid)
from public;

revoke all
on function private.restaurant_role(uuid)
from public;

revoke all
on function private.has_restaurant_role(
  uuid,
  public.staff_role[]
)
from public;

revoke all
on function private.can_access_branch(uuid)
from public;

revoke all
on function private.can_manage_branch(uuid)
from public;

revoke all
on function private.can_manage_staff(uuid)
from public;

revoke all
on function private.can_access_product(uuid)
from public;

revoke all
on function private.can_manage_product(uuid)
from public;

revoke all
on function private.owns_order(uuid)
from public;

revoke all
on function private.can_read_order(uuid)
from public;

revoke all
on function private.can_read_order_item(uuid)
from public;

revoke all
on function private.can_view_order_financials(uuid)
from public;

grant execute
on function private.is_restaurant_member(uuid)
to authenticated;

grant execute
on function private.restaurant_role(uuid)
to authenticated;

grant execute
on function private.has_restaurant_role(
  uuid,
  public.staff_role[]
)
to authenticated;

grant execute
on function private.can_access_branch(uuid)
to authenticated;

grant execute
on function private.can_manage_branch(uuid)
to authenticated;

grant execute
on function private.can_manage_staff(uuid)
to authenticated;

grant execute
on function private.can_access_product(uuid)
to authenticated;

grant execute
on function private.can_manage_product(uuid)
to authenticated;

grant execute
on function private.owns_order(uuid)
to authenticated;

grant execute
on function private.can_read_order(uuid)
to authenticated;

grant execute
on function private.can_read_order_item(uuid)
to authenticated;

grant execute
on function private.can_view_order_financials(uuid)
to authenticated;

-- ============================================================================
-- 3. REVOKE SUPABASE DEFAULT TABLE PRIVILEGES
-- ============================================================================
--
-- Policies and grants are separate controls. Revoke broad platform defaults
-- before explicitly granting only the operations used by the apps.
-- ============================================================================

revoke all privileges
on all tables in schema public
from anon, authenticated;

revoke all privileges
on all sequences in schema public
from anon, authenticated;

-- Future objects created by the migration owner should also be opt-in.
alter default privileges in schema public
revoke all on tables
from anon, authenticated;

alter default privileges in schema public
revoke all on sequences
from anon, authenticated;

alter default privileges in schema public
revoke execute on functions
from public;

alter default privileges in schema private
revoke execute on functions
from public;

-- Keep public schema callable/queryable only where explicit object grants exist.
grant usage on schema public to anon, authenticated;

-- ============================================================================
-- 4. PROFILES
-- ============================================================================

drop policy if exists profiles_select_self
on public.profiles;

create policy profiles_select_self
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
);

drop policy if exists profiles_update_self
on public.profiles;

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

grant select
on public.profiles
to authenticated;

grant update (
  full_name,
  phone,
  avatar_path
)
on public.profiles
to authenticated;

-- No client INSERT is required because DATABASE_SCHEMA.sql creates profiles from
-- the auth.users trigger. No client DELETE is granted.

-- ============================================================================
-- 5. RESTAURANTS
-- ============================================================================

drop policy if exists restaurants_select_member
on public.restaurants;

create policy restaurants_select_member
on public.restaurants
for select
to authenticated
using (
  private.is_restaurant_member(id)
);

drop policy if exists restaurants_update_owner
on public.restaurants;

create policy restaurants_update_owner
on public.restaurants
for update
to authenticated
using (
  private.has_restaurant_role(
    id,
    array['owner'::public.staff_role]
  )
)
with check (
  private.has_restaurant_role(
    id,
    array['owner'::public.staff_role]
  )
);

grant select
on public.restaurants
to authenticated;

grant update (
  name,
  slug,
  logo_path,
  currency_code,
  timezone,
  tax_inclusive,
  is_active
)
on public.restaurants
to authenticated;

-- Restaurant INSERT/owner assignment belongs in create_restaurant RPC.

-- ============================================================================
-- 6. RESTAURANT SETTINGS
-- ============================================================================

drop policy if exists restaurant_settings_select_member
on public.restaurant_settings;

create policy restaurant_settings_select_member
on public.restaurant_settings
for select
to authenticated
using (
  private.is_restaurant_member(
    restaurant_id
  )
);

drop policy if exists restaurant_settings_update_owner
on public.restaurant_settings;

create policy restaurant_settings_update_owner
on public.restaurant_settings
for update
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array['owner'::public.staff_role]
  )
)
with check (
  private.has_restaurant_role(
    restaurant_id,
    array['owner'::public.staff_role]
  )
);

grant select
on public.restaurant_settings
to authenticated;

grant update (
  allow_dine_in,
  allow_takeaway,
  allow_delivery,
  allow_guest_checkout,
  require_payment_before_kitchen,
  service_charge_basis_points,
  default_tax_basis_points
)
on public.restaurant_settings
to authenticated;

-- ============================================================================
-- 7. RESTAURANT MEMBERS
-- ============================================================================

drop policy if exists restaurant_members_select_self_or_manager
on public.restaurant_members;

create policy restaurant_members_select_self_or_manager
on public.restaurant_members
for select
to authenticated
using (
  user_id = (select auth.uid())
  or
  private.can_manage_staff(
    restaurant_id
  )
);

grant select
on public.restaurant_members
to authenticated;

-- No direct INSERT/UPDATE/DELETE.
-- Staff membership mutations belong in trusted staff RPCs.

-- ============================================================================
-- 8. BRANCHES
-- ============================================================================

drop policy if exists branches_select_accessible
on public.branches;

create policy branches_select_accessible
on public.branches
for select
to authenticated
using (
  private.can_access_branch(id)
);

drop policy if exists branches_insert_manager
on public.branches;

create policy branches_insert_manager
on public.branches
for insert
to authenticated
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists branches_update_manager
on public.branches;

create policy branches_update_manager
on public.branches
for update
to authenticated
using (
  private.can_manage_branch(id)
)
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

grant select
on public.branches
to authenticated;

grant insert (
  restaurant_id,
  name,
  code,
  phone,
  address_line1,
  address_line2,
  city,
  state,
  postal_code,
  country_code,
  latitude,
  longitude,
  is_active
)
on public.branches
to authenticated;

grant update (
  name,
  code,
  phone,
  address_line1,
  address_line2,
  city,
  state,
  postal_code,
  country_code,
  latitude,
  longitude,
  is_active
)
on public.branches
to authenticated;

-- Hard DELETE intentionally not granted.

-- ============================================================================
-- 9. BRANCH SETTINGS
-- ============================================================================

drop policy if exists branch_settings_select_accessible
on public.branch_settings;

create policy branch_settings_select_accessible
on public.branch_settings
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists branch_settings_insert_manager
on public.branch_settings;

create policy branch_settings_insert_manager
on public.branch_settings
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists branch_settings_update_manager
on public.branch_settings;

create policy branch_settings_update_manager
on public.branch_settings
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

grant select
on public.branch_settings
to authenticated;

grant insert (
  branch_id,
  restaurant_id,
  allow_dine_in,
  allow_takeaway,
  allow_delivery,
  require_payment_before_kitchen,
  service_charge_basis_points,
  default_tax_basis_points,
  is_ordering_paused,
  ordering_pause_reason,
  minimum_order_minor,
  default_prep_minutes
)
on public.branch_settings
to authenticated;

grant update (
  allow_dine_in,
  allow_takeaway,
  allow_delivery,
  require_payment_before_kitchen,
  service_charge_basis_points,
  default_tax_basis_points,
  is_ordering_paused,
  ordering_pause_reason,
  minimum_order_minor,
  default_prep_minutes
)
on public.branch_settings
to authenticated;

-- ============================================================================
-- 10. BRANCH MEMBERS
-- ============================================================================

drop policy if exists branch_members_select_self_or_manager
on public.branch_members;

create policy branch_members_select_self_or_manager
on public.branch_members
for select
to authenticated
using (
  user_id = (select auth.uid())
  or
  private.can_manage_staff(
    restaurant_id
  )
);

grant select
on public.branch_members
to authenticated;

-- Membership writes remain RPC-controlled.

-- ============================================================================
-- 11. BRANCH OPENING HOURS
-- ============================================================================

drop policy if exists branch_opening_hours_select_accessible
on public.branch_opening_hours;

create policy branch_opening_hours_select_accessible
on public.branch_opening_hours
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists branch_opening_hours_insert_manager
on public.branch_opening_hours;

create policy branch_opening_hours_insert_manager
on public.branch_opening_hours
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists branch_opening_hours_update_manager
on public.branch_opening_hours;

create policy branch_opening_hours_update_manager
on public.branch_opening_hours
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists branch_opening_hours_delete_manager
on public.branch_opening_hours;

create policy branch_opening_hours_delete_manager
on public.branch_opening_hours
for delete
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
);

grant select, delete
on public.branch_opening_hours
to authenticated;

grant insert (
  restaurant_id,
  branch_id,
  weekday,
  slot_order,
  opens_at,
  closes_at,
  is_closed
)
on public.branch_opening_hours
to authenticated;

grant update (
  weekday,
  slot_order,
  opens_at,
  closes_at,
  is_closed
)
on public.branch_opening_hours
to authenticated;

-- ============================================================================
-- 12. TEMPORARY BRANCH CLOSURES
-- ============================================================================

drop policy if exists branch_closures_select_accessible
on public.branch_closures;

create policy branch_closures_select_accessible
on public.branch_closures
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists branch_closures_insert_manager
on public.branch_closures;

create policy branch_closures_insert_manager
on public.branch_closures
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
  and (
    created_by is null
    or created_by = (select auth.uid())
  )
);

drop policy if exists branch_closures_update_manager
on public.branch_closures;

create policy branch_closures_update_manager
on public.branch_closures
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists branch_closures_delete_manager
on public.branch_closures;

create policy branch_closures_delete_manager
on public.branch_closures
for delete
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
);

grant select, delete
on public.branch_closures
to authenticated;

grant insert (
  restaurant_id,
  branch_id,
  starts_at,
  ends_at,
  reason,
  created_by
)
on public.branch_closures
to authenticated;

grant update (
  starts_at,
  ends_at,
  reason
)
on public.branch_closures
to authenticated;

-- ============================================================================
-- 13. DINING AREAS
-- ============================================================================

drop policy if exists dining_areas_select_accessible
on public.dining_areas;

create policy dining_areas_select_accessible
on public.dining_areas
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists dining_areas_insert_manager
on public.dining_areas;

create policy dining_areas_insert_manager
on public.dining_areas
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists dining_areas_update_manager
on public.dining_areas;

create policy dining_areas_update_manager
on public.dining_areas
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

grant select
on public.dining_areas
to authenticated;

grant insert (
  restaurant_id,
  branch_id,
  name,
  sort_order,
  is_active
)
on public.dining_areas
to authenticated;

grant update (
  name,
  sort_order,
  is_active
)
on public.dining_areas
to authenticated;

-- ============================================================================
-- 14. DINING TABLES
-- ============================================================================

drop policy if exists dining_tables_select_accessible
on public.dining_tables;

create policy dining_tables_select_accessible
on public.dining_tables
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists dining_tables_insert_manager
on public.dining_tables;

create policy dining_tables_insert_manager
on public.dining_tables
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists dining_tables_update_manager
on public.dining_tables;

create policy dining_tables_update_manager
on public.dining_tables
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

grant select
on public.dining_tables
to authenticated;

grant insert (
  restaurant_id,
  branch_id,
  dining_area_id,
  name,
  capacity,
  is_active
)
on public.dining_tables
to authenticated;

grant update (
  dining_area_id,
  name,
  capacity,
  is_active
)
on public.dining_tables
to authenticated;

-- qr_token is deliberately excluded from direct INSERT/UPDATE grants.
-- Rotation must use rotate_table_qr RPC.

-- ============================================================================
-- 15. CATEGORIES
-- ============================================================================

drop policy if exists categories_select_staff
on public.categories;

create policy categories_select_staff
on public.categories
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists categories_insert_manager
on public.categories;

create policy categories_insert_manager
on public.categories
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists categories_update_manager
on public.categories;

create policy categories_update_manager
on public.categories
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

grant select
on public.categories
to authenticated;

grant insert (
  restaurant_id,
  branch_id,
  name,
  description,
  image_path,
  sort_order,
  is_active
)
on public.categories
to authenticated;

grant update (
  name,
  description,
  image_path,
  sort_order,
  is_active
)
on public.categories
to authenticated;

-- Customer public menu access is expected through get_public_menu RPC.

-- ============================================================================
-- 16. PRODUCTS
-- ============================================================================

drop policy if exists products_select_staff
on public.products;

create policy products_select_staff
on public.products
for select
to authenticated
using (
  private.can_access_branch(
    branch_id
  )
);

drop policy if exists products_insert_manager
on public.products;

create policy products_insert_manager
on public.products
for insert
to authenticated
with check (
  private.can_manage_branch(
    branch_id
  )
);

drop policy if exists products_update_manager
on public.products;

create policy products_update_manager
on public.products
for update
to authenticated
using (
  private.can_manage_branch(
    branch_id
  )
)
with check (
  private.can_manage_branch(
    branch_id
  )
);

grant select
on public.products
to authenticated;

grant insert (
  restaurant_id,
  branch_id,
  category_id,
  name,
  description,
  sku,
  base_price_minor,
  tax_basis_points_override,
  image_path,
  is_veg,
  is_available,
  is_active,
  sort_order,
  preparation_minutes
)
on public.products
to authenticated;

grant update (
  category_id,
  name,
  description,
  sku,
  base_price_minor,
  tax_basis_points_override,
  image_path,
  is_veg,
  is_available,
  is_active,
  sort_order,
  preparation_minutes
)
on public.products
to authenticated;

-- Hard DELETE intentionally not granted.

-- ============================================================================
-- 17. PRODUCT TAGS
-- ============================================================================

drop policy if exists product_tags_select_member
on public.product_tags;

create policy product_tags_select_member
on public.product_tags
for select
to authenticated
using (
  private.is_restaurant_member(
    restaurant_id
  )
);

drop policy if exists product_tags_insert_manager
on public.product_tags;

create policy product_tags_insert_manager
on public.product_tags
for insert
to authenticated
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists product_tags_update_manager
on public.product_tags;

create policy product_tags_update_manager
on public.product_tags
for update
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
)
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists product_tags_delete_manager
on public.product_tags;

create policy product_tags_delete_manager
on public.product_tags
for delete
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

grant select, delete
on public.product_tags
to authenticated;

grant insert (
  restaurant_id,
  name
)
on public.product_tags
to authenticated;

grant update (
  name
)
on public.product_tags
to authenticated;

-- ============================================================================
-- 18. PRODUCT TAG LINKS
-- ============================================================================

drop policy if exists product_tag_links_select_staff
on public.product_tag_links;

create policy product_tag_links_select_staff
on public.product_tag_links
for select
to authenticated
using (
  private.can_access_product(
    product_id
  )
);

drop policy if exists product_tag_links_insert_manager
on public.product_tag_links;

create policy product_tag_links_insert_manager
on public.product_tag_links
for insert
to authenticated
with check (
  private.can_manage_product(
    product_id
  )
);

drop policy if exists product_tag_links_delete_manager
on public.product_tag_links;

create policy product_tag_links_delete_manager
on public.product_tag_links
for delete
to authenticated
using (
  private.can_manage_product(
    product_id
  )
);

grant select, delete
on public.product_tag_links
to authenticated;

grant insert (
  restaurant_id,
  product_id,
  tag_id
)
on public.product_tag_links
to authenticated;

-- ============================================================================
-- 19. MODIFIER GROUPS
-- ============================================================================

drop policy if exists modifier_groups_select_member
on public.modifier_groups;

create policy modifier_groups_select_member
on public.modifier_groups
for select
to authenticated
using (
  private.is_restaurant_member(
    restaurant_id
  )
);

drop policy if exists modifier_groups_insert_manager
on public.modifier_groups;

create policy modifier_groups_insert_manager
on public.modifier_groups
for insert
to authenticated
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists modifier_groups_update_manager
on public.modifier_groups;

create policy modifier_groups_update_manager
on public.modifier_groups
for update
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
)
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

grant select
on public.modifier_groups
to authenticated;

grant insert (
  restaurant_id,
  name,
  min_select,
  max_select,
  is_required,
  sort_order,
  is_active
)
on public.modifier_groups
to authenticated;

grant update (
  name,
  min_select,
  max_select,
  is_required,
  sort_order,
  is_active
)
on public.modifier_groups
to authenticated;

-- ============================================================================
-- 20. MODIFIERS
-- ============================================================================

drop policy if exists modifiers_select_member
on public.modifiers;

create policy modifiers_select_member
on public.modifiers
for select
to authenticated
using (
  private.is_restaurant_member(
    restaurant_id
  )
);

drop policy if exists modifiers_insert_manager
on public.modifiers;

create policy modifiers_insert_manager
on public.modifiers
for insert
to authenticated
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists modifiers_update_manager
on public.modifiers;

create policy modifiers_update_manager
on public.modifiers
for update
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
)
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

grant select
on public.modifiers
to authenticated;

grant insert (
  restaurant_id,
  group_id,
  name,
  price_delta_minor,
  sort_order,
  is_available,
  is_active
)
on public.modifiers
to authenticated;

grant update (
  group_id,
  name,
  price_delta_minor,
  sort_order,
  is_available,
  is_active
)
on public.modifiers
to authenticated;

-- ============================================================================
-- 21. PRODUCT MODIFIER GROUP MAPPING
-- ============================================================================

drop policy if exists product_modifier_groups_select_staff
on public.product_modifier_groups;

create policy product_modifier_groups_select_staff
on public.product_modifier_groups
for select
to authenticated
using (
  private.can_access_product(
    product_id
  )
);

drop policy if exists product_modifier_groups_insert_manager
on public.product_modifier_groups;

create policy product_modifier_groups_insert_manager
on public.product_modifier_groups
for insert
to authenticated
with check (
  private.can_manage_product(
    product_id
  )
);

drop policy if exists product_modifier_groups_delete_manager
on public.product_modifier_groups;

create policy product_modifier_groups_delete_manager
on public.product_modifier_groups
for delete
to authenticated
using (
  private.can_manage_product(
    product_id
  )
);

grant select, delete
on public.product_modifier_groups
to authenticated;

grant insert (
  restaurant_id,
  product_id,
  modifier_group_id,
  sort_order
)
on public.product_modifier_groups
to authenticated;

-- ============================================================================
-- 22. CUSTOMER ADDRESSES
-- ============================================================================

drop policy if exists customer_addresses_select_self
on public.customer_addresses;

create policy customer_addresses_select_self
on public.customer_addresses
for select
to authenticated
using (
  user_id = (select auth.uid())
);

drop policy if exists customer_addresses_insert_self
on public.customer_addresses;

create policy customer_addresses_insert_self
on public.customer_addresses
for insert
to authenticated
with check (
  user_id = (select auth.uid())
);

drop policy if exists customer_addresses_update_self
on public.customer_addresses;

create policy customer_addresses_update_self
on public.customer_addresses
for update
to authenticated
using (
  user_id = (select auth.uid())
)
with check (
  user_id = (select auth.uid())
);

drop policy if exists customer_addresses_delete_self
on public.customer_addresses;

create policy customer_addresses_delete_self
on public.customer_addresses
for delete
to authenticated
using (
  user_id = (select auth.uid())
);

grant select, delete
on public.customer_addresses
to authenticated;

grant insert (
  user_id,
  label,
  contact_name,
  contact_phone,
  address_line1,
  address_line2,
  landmark,
  city,
  state,
  postal_code,
  country_code,
  latitude,
  longitude,
  is_default
)
on public.customer_addresses
to authenticated;

grant update (
  label,
  contact_name,
  contact_phone,
  address_line1,
  address_line2,
  landmark,
  city,
  state,
  postal_code,
  country_code,
  latitude,
  longitude,
  is_default
)
on public.customer_addresses
to authenticated;

-- ============================================================================
-- 23. ORDERS
-- ============================================================================
--
-- Direct INSERT / UPDATE / DELETE are intentionally blocked.
-- create_order / change_order_status / cancel_order RPCs own mutations.
-- ============================================================================

drop policy if exists orders_select_customer_or_staff
on public.orders;

create policy orders_select_customer_or_staff
on public.orders
for select
to authenticated
using (
  customer_id = (select auth.uid())
  or
  private.can_access_branch(
    branch_id
  )
);

grant select
on public.orders
to authenticated;

-- NOTE:
-- Table-level SELECT supports the current Postgres Changes Realtime architecture.
-- Because RLS cannot hide individual columns by restaurant role, strict staff
-- PII segregation requires a future schema/Broadcast refinement as described at
-- the top of this file.

-- ============================================================================
-- 24. ORDER ITEMS
-- ============================================================================

drop policy if exists order_items_select_order_reader
on public.order_items;

create policy order_items_select_order_reader
on public.order_items
for select
to authenticated
using (
  private.can_read_order(
    order_id
  )
);

grant select
on public.order_items
to authenticated;

-- ============================================================================
-- 25. ORDER ITEM MODIFIERS
-- ============================================================================

drop policy if exists order_item_modifiers_select_order_reader
on public.order_item_modifiers;

create policy order_item_modifiers_select_order_reader
on public.order_item_modifiers
for select
to authenticated
using (
  private.can_read_order_item(
    order_item_id
  )
);

grant select
on public.order_item_modifiers
to authenticated;

-- ============================================================================
-- 26. ORDER STATUS HISTORY
-- ============================================================================

drop policy if exists order_status_history_select_order_reader
on public.order_status_history;

create policy order_status_history_select_order_reader
on public.order_status_history
for select
to authenticated
using (
  private.can_read_order(
    order_id
  )
);

grant select
on public.order_status_history
to authenticated;

-- No client INSERT/UPDATE/DELETE. Trusted status RPC inserts history.

-- ============================================================================
-- 27. PAYMENTS
-- ============================================================================
--
-- Customer payment summary should be returned by a trusted order/payment RPC.
-- Direct payment table SELECT is limited to merchant financial roles.
-- ============================================================================

drop policy if exists payments_select_financial_staff
on public.payments;

create policy payments_select_financial_staff
on public.payments
for select
to authenticated
using (
  private.can_view_order_financials(
    order_id
  )
);

grant select
on public.payments
to authenticated;

-- No direct INSERT/UPDATE/DELETE.

-- ============================================================================
-- 28. PAYMENT REFUNDS
-- ============================================================================

drop policy if exists payment_refunds_select_financial_staff
on public.payment_refunds;

create policy payment_refunds_select_financial_staff
on public.payment_refunds
for select
to authenticated
using (
  exists (
    select 1
    from public.payments p
    where p.id = payment_refunds.payment_id
      and private.can_view_order_financials(
        p.order_id
      )
  )
);

grant select
on public.payment_refunds
to authenticated;

-- Refund creation/mutation is Edge Function/server controlled.

-- ============================================================================
-- 29. WEBHOOK EVENTS
-- ============================================================================
--
-- NO client policies.
-- NO anon/authenticated grants.
-- Server-only ledger.
-- ============================================================================

-- Intentionally empty.

-- ============================================================================
-- 30. COUPONS
-- ============================================================================

drop policy if exists coupons_select_manager
on public.coupons;

create policy coupons_select_manager
on public.coupons
for select
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists coupons_insert_manager
on public.coupons;

create policy coupons_insert_manager
on public.coupons
for insert
to authenticated
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

drop policy if exists coupons_update_manager
on public.coupons;

create policy coupons_update_manager
on public.coupons
for update
to authenticated
using (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
)
with check (
  private.has_restaurant_role(
    restaurant_id,
    array[
      'owner'::public.staff_role,
      'manager'::public.staff_role
    ]
  )
);

grant select
on public.coupons
to authenticated;

grant insert (
  restaurant_id,
  code,
  discount_type,
  discount_value,
  minimum_order_minor,
  maximum_discount_minor,
  starts_at,
  ends_at,
  max_total_uses,
  max_uses_per_customer,
  is_active
)
on public.coupons
to authenticated;

grant update (
  code,
  discount_type,
  discount_value,
  minimum_order_minor,
  maximum_discount_minor,
  starts_at,
  ends_at,
  max_total_uses,
  max_uses_per_customer,
  is_active
)
on public.coupons
to authenticated;

-- Customers validate/apply coupons through create_order or a dedicated safe RPC.
-- Direct customer coupon enumeration is intentionally blocked.

-- ============================================================================
-- 31. ORDER DISCOUNT SNAPSHOTS
-- ============================================================================

drop policy if exists order_discounts_select_financial_staff
on public.order_discounts;

create policy order_discounts_select_financial_staff
on public.order_discounts
for select
to authenticated
using (
  private.can_view_order_financials(
    order_id
  )
);

grant select
on public.order_discounts
to authenticated;

-- Customer-safe discount data should be returned through get_order_details RPC.

-- ============================================================================
-- 32. DEVICE TOKENS
-- ============================================================================

drop policy if exists device_tokens_select_self
on public.device_tokens;

create policy device_tokens_select_self
on public.device_tokens
for select
to authenticated
using (
  user_id = (select auth.uid())
);

drop policy if exists device_tokens_insert_self
on public.device_tokens;

create policy device_tokens_insert_self
on public.device_tokens
for insert
to authenticated
with check (
  user_id = (select auth.uid())
);

drop policy if exists device_tokens_update_self
on public.device_tokens;

create policy device_tokens_update_self
on public.device_tokens
for update
to authenticated
using (
  user_id = (select auth.uid())
)
with check (
  user_id = (select auth.uid())
);

drop policy if exists device_tokens_delete_self
on public.device_tokens;

create policy device_tokens_delete_self
on public.device_tokens
for delete
to authenticated
using (
  user_id = (select auth.uid())
);

grant select, delete
on public.device_tokens
to authenticated;

grant insert (
  user_id,
  token,
  platform,
  app_type,
  is_active,
  last_seen_at
)
on public.device_tokens
to authenticated;

grant update (
  token,
  platform,
  app_type,
  is_active,
  last_seen_at
)
on public.device_tokens
to authenticated;

-- ============================================================================
-- 33. STAFF INVITATIONS
-- ============================================================================

drop policy if exists staff_invitations_select_manager
on public.staff_invitations;

create policy staff_invitations_select_manager
on public.staff_invitations
for select
to authenticated
using (
  private.can_manage_staff(
    restaurant_id
  )
);

-- Exclude token_hash from direct client SELECT.
grant select (
  id,
  restaurant_id,
  email,
  phone,
  role,
  expires_at,
  invited_by,
  accepted_at,
  revoked_at,
  created_at,
  updated_at
)
on public.staff_invitations
to authenticated;

-- Invitation creation/acceptance/revocation belongs in trusted RPCs.

-- ============================================================================
-- 34. STAFF INVITATION BRANCHES
-- ============================================================================

drop policy if exists staff_invitation_branches_select_manager
on public.staff_invitation_branches;

create policy staff_invitation_branches_select_manager
on public.staff_invitation_branches
for select
to authenticated
using (
  private.can_manage_staff(
    restaurant_id
  )
);

grant select
on public.staff_invitation_branches
to authenticated;

-- ============================================================================
-- 35. AUDIT LOGS
-- ============================================================================

drop policy if exists audit_logs_select_manager
on public.audit_logs;

create policy audit_logs_select_manager
on public.audit_logs
for select
to authenticated
using (
  restaurant_id is not null
  and
  private.can_manage_staff(
    restaurant_id
  )
);

grant select
on public.audit_logs
to authenticated;

-- No client INSERT/UPDATE/DELETE. Trusted RPCs/functions write audits.

-- ============================================================================
-- 36. VERIFY RLS IS ENABLED
-- ============================================================================
--
-- DATABASE_SCHEMA.sql already enables RLS, but repeat safely here so this
-- migration remains defensive.
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
-- 37. INTENTIONAL DIRECT-CLIENT ACCESS SUMMARY
-- ============================================================================
--
-- authenticated SELECT:
--   profiles (self)
--   restaurants/settings/memberships (staff-scoped)
--   branches/settings/memberships (staff-scoped)
--   opening hours/closures (staff-scoped)
--   dining areas/tables (staff-scoped)
--   menu tables (staff-scoped)
--   customer_addresses (self)
--   orders/items/history (customer own OR branch staff)
--   payments/refunds (financial staff only)
--   coupons (owner/manager)
--   device_tokens (self)
--   staff invitation safe fields (owner/manager)
--   audit logs (owner/manager)
--
-- authenticated direct writes:
--   profile self editable fields
--   customer address self CRUD
--   device token self CRUD
--   owner/manager branch operational CRUD
--   owner/manager menu CRUD
--   owner/manager table CRUD
--   owner/manager opening-hours/closure CRUD
--   owner/manager coupon CRUD
--
-- intentionally server/RPC-only:
--   restaurant creation
--   restaurant membership mutations
--   branch membership mutations
--   staff invitation mutations
--   order creation
--   order status mutation
--   order cancellation
--   order item insertion
--   status-history insertion
--   payment creation/mutation
--   refund creation/mutation
--   webhook events
--   order discount snapshots
--   audit insertion
--   QR token rotation
--
-- intentionally NO client access:
--   webhook_events
--
-- ============================================================================
-- 38. REQUIRED TEST MATRIX
-- ============================================================================
--
-- Before production, create supabase/tests RLS tests for:
--
-- Identity cases:
--   anon role
--   anonymous authenticated customer
--   normal customer
--   owner
--   manager
--   cashier
--   waiter
--   kitchen
--   user from restaurant B
--   same restaurant but unassigned branch staff
--
-- Must prove:
--   customer A cannot read customer B order
--   restaurant A cannot read restaurant B
--   branch-restricted staff cannot read another branch
--   customer cannot write products
--   customer cannot update orders
--   customer cannot update payments
--   kitchen cannot refund
--   cashier cannot mutate staff membership
--   manager cannot directly promote owner through membership table
--   no client can write webhook_events
--   no client can write audit_logs
--   qr_token cannot be directly changed by normal table update
--
-- ============================================================================
-- 39. NEXT BACKEND FILES
-- ============================================================================
--
-- Apply / implement next:
--
--   RPC_FUNCTIONS.sql
--     resolve_qr
--     get_public_menu
--     create_restaurant
--     create_order
--     get_order_details
--     change_order_status
--     cancel_order
--     confirm_cash_payment
--     rotate_table_qr
--     get_dashboard_summary
--     invite_staff / accept_staff_invitation
--
--   STORAGE_POLICIES.sql
--     restaurant-assets
--     menu-images
--     avatars
--
--   REALTIME_SETUP.sql
--     orders
--     order_status_history as needed
--
--   Edge Functions
--     create-payment
--     payment-webhook
--     refund-payment
--
-- ============================================================================
-- 40. FINAL SECURITY RULE
-- ============================================================================
--
-- A policy is correct only when BOTH are true:
--
--   grant allows the operation type
--   RLS policy allows only the intended rows
--
-- Never "fix" a 42501 / permission error by broadening the policy to TRUE.
-- Verify grants, membership, branch assignment, and intended operation first.
-- ============================================================================

commit;
