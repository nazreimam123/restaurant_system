-- ============================================================================
-- RPC_FUNCTIONS.sql
-- QR Restaurant Ordering Platform
-- Trusted PostgreSQL RPC / Business Logic Layer
--
-- Requires:
--   DATABASE_SCHEMA.sql
--   RLS_POLICIES.sql
--
-- Implements:
--   - resolve_qr
--   - get_public_menu
--   - create_restaurant
--   - create_order
--   - get_order_details
--   - change_order_status
--   - cancel_order
--   - confirm_cash_payment
--   - rotate_table_qr
--   - get_dashboard_summary
--   - get_sales_report
--   - invite_staff
--   - accept_staff_invitation
--   - update_staff_member (project support RPC)
--
-- SECURITY PRINCIPLES
--   - Flutter expresses intent; the database determines business truth.
--   - All public RPCs derive identity from auth.uid().
--   - SECURITY DEFINER functions pin search_path = ''.
--   - Objects are schema-qualified.
--   - Product/modifier prices are loaded server-side.
--   - Order totals are calculated server-side.
--   - Order creation is atomic and idempotent.
--   - Status transitions are validated and audited.
--   - Payment state is never trusted from Flutter.
--   - Staff membership mutation is controlled.
--
-- MONEY
--   All values use integer minor units.
--
-- TAX MODEL USED BY THIS MVP
--   Effective product tax:
--     product.tax_basis_points_override
--       -> branch_settings.default_tax_basis_points
--       -> restaurant_settings.default_tax_basis_points
--
--   tax_inclusive = false:
--     item menu amount is pre-tax
--     tax is added to total
--
--   tax_inclusive = true:
--     item menu amount already contains tax
--     tax component is extracted
--     subtotal stores the tax-exclusive component
--
--   Service charge is calculated from subtotal_minor.
--   Coupon discount is calculated against subtotal_minor and then subtracted
--   from the final order formula.
--
--   Production deployments must review tax/service-charge rules for their
--   jurisdiction before go-live.
--
-- INVITATIONS
--   invite_staff returns a one-time delivery_token because this SQL file does
--   not itself send email/SMS. Once an Edge Function owns invitation delivery,
--   that wrapper should keep the token server-side and return only the safe
--   invitation metadata to Flutter.
-- ============================================================================

begin;

-- ============================================================================
-- 1. PRIVATE API ENVELOPE HELPERS
-- ============================================================================

create or replace function private.api_ok(
  payload jsonb
)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object(
    'ok', true,
    'data', coalesce(payload, '{}'::jsonb),
    'error', null
  );
$$;

create or replace function private.api_error(
  error_code text,
  error_message text,
  error_details jsonb default '{}'::jsonb
)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_build_object(
    'ok', false,
    'data', null,
    'error', jsonb_build_object(
      'code', error_code,
      'message', error_message,
      'details', coalesce(
        error_details,
        '{}'::jsonb
      )
    )
  );
$$;

revoke all
on function private.api_ok(jsonb)
from public;

revoke all
on function private.api_error(
  text,
  text,
  jsonb
)
from public;

-- ============================================================================
-- 2. PRIVATE PARSING / CONFIG HELPERS
-- ============================================================================

create or replace function private.safe_uuid(
  value text
)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  if value is null
     or btrim(value) = '' then
    return null;
  end if;

  begin
    return value::uuid;
  exception
    when invalid_text_representation then
      return null;
  end;
end;
$$;

create or replace function private.order_base_url()
returns text
language sql
stable
set search_path = ''
as $$
  select rtrim(
    coalesce(
      nullif(
        current_setting(
          'app.order_base_url',
          true
        ),
        ''
      ),
      'https://order.example.com'
    ),
    '/'
  );
$$;

revoke all
on function private.safe_uuid(text)
from public;

revoke all
on function private.order_base_url()
from public;

-- ============================================================================
-- 3. PRIVATE AUDIT HELPER
-- ============================================================================

create or replace function private.write_audit(
  p_restaurant_id uuid,
  p_branch_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_logs (
    restaurant_id,
    branch_id,
    actor_user_id,
    action,
    entity_type,
    entity_id,
    metadata
  )
  values (
    p_restaurant_id,
    p_branch_id,
    (select auth.uid()),
    p_action,
    p_entity_type,
    p_entity_id,
    coalesce(
      p_metadata,
      '{}'::jsonb
    )
  );
end;
$$;

revoke all
on function private.write_audit(
  uuid,
  uuid,
  text,
  text,
  uuid,
  jsonb
)
from public;

-- ============================================================================
-- 4. PRIVATE OPENING-HOURS HELPER
-- ============================================================================

create or replace function private.is_branch_open_at(
  p_branch_id uuid,
  p_at timestamptz default now()
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_timezone text;
  v_local timestamp without time zone;
  v_local_time time;
  v_dow integer;
  v_previous_dow integer;
  v_has_schedule boolean;
begin
  select r.timezone
  into v_timezone
  from public.branches b
  join public.restaurants r
    on r.id = b.restaurant_id
  where b.id = p_branch_id;

  if not found then
    return false;
  end if;

  if exists (
    select 1
    from public.branch_closures bc
    where bc.branch_id = p_branch_id
      and p_at >= bc.starts_at
      and p_at < bc.ends_at
  ) then
    return false;
  end if;

  select exists (
    select 1
    from public.branch_opening_hours oh
    where oh.branch_id = p_branch_id
  )
  into v_has_schedule;

  -- No configured opening-hours rows means "not configured", not closed.
  if not v_has_schedule then
    return true;
  end if;

  v_local := p_at at time zone v_timezone;
  v_local_time := v_local::time;
  v_dow := extract(
    dow from v_local
  )::integer;
  v_previous_dow := (
    v_dow + 6
  ) % 7;

  return exists (
    select 1
    from public.branch_opening_hours oh
    where oh.branch_id = p_branch_id
      and oh.is_closed = false
      and (
        -- Normal same-day slot.
        (
          oh.weekday = v_dow
          and oh.opens_at <= oh.closes_at
          and v_local_time >= oh.opens_at
          and v_local_time < oh.closes_at
        )

        or

        -- Overnight slot, starting today.
        (
          oh.weekday = v_dow
          and oh.opens_at > oh.closes_at
          and v_local_time >= oh.opens_at
        )

        or

        -- Overnight slot that started yesterday.
        (
          oh.weekday = v_previous_dow
          and oh.opens_at > oh.closes_at
          and v_local_time < oh.closes_at
        )
      )
  );
end;
$$;

revoke all
on function private.is_branch_open_at(
  uuid,
  timestamptz
)
from public;

-- ============================================================================
-- 5. PRIVATE ORDER TRANSITION HELPERS
-- ============================================================================

create or replace function private.is_legal_order_transition(
  p_current public.order_status,
  p_next public.order_status,
  p_order_type public.order_type
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case
    when p_current = 'placed'
     and p_next = 'accepted'
      then true

    when p_current = 'accepted'
     and p_next = 'preparing'
      then true

    when p_current = 'preparing'
     and p_next = 'ready'
      then true

    when p_current = 'ready'
     and p_next = 'served'
     and p_order_type = 'dine_in'
      then true

    when p_current = 'ready'
     and p_next = 'completed'
     and p_order_type in (
       'takeaway',
       'delivery'
     )
      then true

    when p_current = 'served'
     and p_next = 'completed'
     and p_order_type = 'dine_in'
      then true

    else false
  end;
$$;

create or replace function private.role_can_transition_order(
  p_role public.staff_role,
  p_current public.order_status,
  p_next public.order_status,
  p_order_type public.order_type
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case
    when p_role in (
      'owner'::public.staff_role,
      'manager'::public.staff_role
    )
      then private.is_legal_order_transition(
        p_current,
        p_next,
        p_order_type
      )

    when p_role = 'kitchen'
      then (
        (p_current = 'placed'
         and p_next = 'accepted')
        or
        (p_current = 'accepted'
         and p_next = 'preparing')
        or
        (p_current = 'preparing'
         and p_next = 'ready')
      )

    when p_role = 'waiter'
      then (
        (p_current = 'placed'
         and p_next = 'accepted')
        or
        (
          p_order_type = 'dine_in'
          and p_current = 'ready'
          and p_next = 'served'
        )
        or
        (
          p_order_type = 'dine_in'
          and p_current = 'served'
          and p_next = 'completed'
        )
      )

    when p_role = 'cashier'
      then (
        (p_current = 'placed'
         and p_next = 'accepted')
        or
        (
          p_order_type in (
            'takeaway',
            'delivery'
          )
          and p_current = 'ready'
          and p_next = 'completed'
        )
        or
        (
          p_order_type = 'dine_in'
          and p_current = 'served'
          and p_next = 'completed'
        )
      )

    else false
  end;
$$;

revoke all
on function private.is_legal_order_transition(
  public.order_status,
  public.order_status,
  public.order_type
)
from public;

revoke all
on function private.role_can_transition_order(
  public.staff_role,
  public.order_status,
  public.order_status,
  public.order_type
)
from public;

-- ============================================================================
-- 6. PRIVATE CREATE-ORDER RESPONSE BUILDER
-- ============================================================================

create or replace function private.create_order_data(
  p_order_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_payment_status public.payment_status;
begin
  select *
  into v_order
  from public.orders
  where id = p_order_id;

  if not found then
    return null;
  end if;

  select p.status
  into v_payment_status
  from public.payments p
  where p.order_id = p_order_id
  order by
    case p.status
      when 'paid' then 1
      when 'partially_refunded' then 2
      when 'refunded' then 3
      when 'authorized' then 4
      when 'pending' then 5
      when 'failed' then 6
      when 'cancelled' then 7
      else 99
    end,
    p.created_at desc
  limit 1;

  return jsonb_build_object(
    'order',
    jsonb_build_object(
      'id', v_order.id,
      'order_number',
        v_order.order_number,
      'restaurant_id',
        v_order.restaurant_id,
      'branch_id',
        v_order.branch_id,
      'table_id',
        v_order.table_id,
      'order_type',
        v_order.order_type::text,
      'status',
        v_order.status::text,
      'currency_code',
        v_order.currency_code,
      'subtotal_minor',
        v_order.subtotal_minor,
      'tax_minor',
        v_order.tax_minor,
      'service_charge_minor',
        v_order.service_charge_minor,
      'delivery_fee_minor',
        v_order.delivery_fee_minor,
      'discount_minor',
        v_order.discount_minor,
      'total_minor',
        v_order.total_minor,
      'created_at',
        v_order.created_at
    ),
    'payment',
    jsonb_build_object(
      'required',
        (
          v_order.status = 'awaiting_payment'
        ),
      'status',
        coalesce(
          v_payment_status::text,
          'pending'
        )
    ),
    'changes',
      '[]'::jsonb
  );
end;
$$;

revoke all
on function private.create_order_data(uuid)
from public;

-- ============================================================================
-- 7. RPC: resolve_qr
-- ============================================================================

create or replace function public.resolve_qr(
  p_qr_token uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_table public.dining_tables%rowtype;
  v_branch public.branches%rowtype;
  v_restaurant public.restaurants%rowtype;
  v_rest_settings public.restaurant_settings%rowtype;
  v_branch_settings public.branch_settings%rowtype;

  v_allow_dine_in boolean;
  v_allow_takeaway boolean;
  v_allow_delivery boolean;
  v_ordering_paused boolean;
begin
  if (select auth.uid()) is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_table
  from public.dining_tables
  where qr_token = p_qr_token;

  if not found then
    return private.api_error(
      'QR_NOT_FOUND',
      'This QR code is not valid.'
    );
  end if;

  if not v_table.is_active then
    return private.api_error(
      'QR_TABLE_INACTIVE',
      'This table is currently unavailable.'
    );
  end if;

  select *
  into v_branch
  from public.branches
  where id = v_table.branch_id;

  if not found
     or not v_branch.is_active then
    return private.api_error(
      'BRANCH_INACTIVE',
      'This branch is not accepting orders.'
    );
  end if;

  select *
  into v_restaurant
  from public.restaurants
  where id = v_branch.restaurant_id;

  if not found
     or not v_restaurant.is_active then
    return private.api_error(
      'RESTAURANT_INACTIVE',
      'This restaurant is not accepting orders.'
    );
  end if;

  select *
  into v_rest_settings
  from public.restaurant_settings
  where restaurant_id = v_restaurant.id;

  select *
  into v_branch_settings
  from public.branch_settings
  where branch_id = v_branch.id;

  v_allow_dine_in := coalesce(
    v_branch_settings.allow_dine_in,
    v_rest_settings.allow_dine_in,
    true
  );

  v_allow_takeaway := coalesce(
    v_branch_settings.allow_takeaway,
    v_rest_settings.allow_takeaway,
    true
  );

  v_allow_delivery := coalesce(
    v_branch_settings.allow_delivery,
    v_rest_settings.allow_delivery,
    false
  );

  v_ordering_paused := coalesce(
    v_branch_settings.is_ordering_paused,
    false
  );

  return private.api_ok(
    jsonb_build_object(
      'restaurant',
      jsonb_build_object(
        'id', v_restaurant.id,
        'name', v_restaurant.name,
        'slug', v_restaurant.slug,
        'logo_path',
          v_restaurant.logo_path,
        'currency_code',
          v_restaurant.currency_code,
        'timezone',
          v_restaurant.timezone
      ),

      'branch',
      jsonb_build_object(
        'id', v_branch.id,
        'name', v_branch.name,
        'phone', v_branch.phone,
        'city', v_branch.city,
        'state', v_branch.state,
        'country_code',
          v_branch.country_code,
        'menu_version',
          v_branch.menu_version
      ),

      'table',
      jsonb_build_object(
        'id', v_table.id,
        'name', v_table.name,
        'capacity',
          v_table.capacity
      ),

      'ordering',
      jsonb_build_object(
        'allow_dine_in',
          v_allow_dine_in,
        'allow_takeaway',
          v_allow_takeaway,
        'allow_delivery',
          v_allow_delivery,
        'is_ordering_paused',
          v_ordering_paused
      )
    )
  );
end;
$$;

revoke all
on function public.resolve_qr(uuid)
from public, anon;

grant execute
on function public.resolve_qr(uuid)
to authenticated, service_role;

-- ============================================================================
-- 8. RPC: get_public_menu
-- ============================================================================

create or replace function public.get_public_menu(
  p_branch_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch public.branches%rowtype;
  v_restaurant public.restaurants%rowtype;
  v_rest_settings public.restaurant_settings%rowtype;
  v_branch_settings public.branch_settings%rowtype;

  v_allow_dine_in boolean;
  v_allow_takeaway boolean;
  v_allow_delivery boolean;
  v_ordering_paused boolean;
  v_pause_reason text;

  v_categories jsonb;
begin
  if (select auth.uid()) is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_branch
  from public.branches
  where id = p_branch_id;

  if not found then
    return private.api_error(
      'BRANCH_NOT_FOUND',
      'Branch not found.'
    );
  end if;

  if not v_branch.is_active then
    return private.api_error(
      'BRANCH_INACTIVE',
      'This branch is not accepting orders.'
    );
  end if;

  select *
  into v_restaurant
  from public.restaurants
  where id = v_branch.restaurant_id;

  if not found
     or not v_restaurant.is_active then
    return private.api_error(
      'RESTAURANT_INACTIVE',
      'This restaurant is not accepting orders.'
    );
  end if;

  select *
  into v_rest_settings
  from public.restaurant_settings
  where restaurant_id = v_restaurant.id;

  select *
  into v_branch_settings
  from public.branch_settings
  where branch_id = v_branch.id;

  v_allow_dine_in := coalesce(
    v_branch_settings.allow_dine_in,
    v_rest_settings.allow_dine_in,
    true
  );

  v_allow_takeaway := coalesce(
    v_branch_settings.allow_takeaway,
    v_rest_settings.allow_takeaway,
    true
  );

  v_allow_delivery := coalesce(
    v_branch_settings.allow_delivery,
    v_rest_settings.allow_delivery,
    false
  );

  v_ordering_paused := coalesce(
    v_branch_settings.is_ordering_paused,
    false
  );

  v_pause_reason :=
    v_branch_settings.ordering_pause_reason;

  select coalesce(
    jsonb_agg(
      category_data
      order by category_sort,
               category_name
    ),
    '[]'::jsonb
  )
  into v_categories
  from (
    select
      c.sort_order as category_sort,
      c.name as category_name,

      jsonb_build_object(
        'id', c.id,
        'name', c.name,
        'description',
          c.description,
        'image_path',
          c.image_path,
        'sort_order',
          c.sort_order,

        'products',
        coalesce(
          (
            select jsonb_agg(
              jsonb_build_object(
                'id', p.id,
                'category_id',
                  p.category_id,
                'name', p.name,
                'description',
                  p.description,
                'base_price_minor',
                  p.base_price_minor,
                'image_path',
                  p.image_path,
                'is_veg',
                  p.is_veg,
                'is_available',
                  p.is_available,
                'sort_order',
                  p.sort_order,
                'preparation_minutes',
                  p.preparation_minutes,

                'tags',
                coalesce(
                  (
                    select jsonb_agg(
                      pt.name
                      order by pt.name
                    )
                    from public.product_tag_links ptl
                    join public.product_tags pt
                      on pt.id = ptl.tag_id
                     and pt.restaurant_id =
                         ptl.restaurant_id
                    where ptl.product_id = p.id
                  ),
                  '[]'::jsonb
                ),

                'modifier_groups',
                coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'id', mg.id,
                        'name', mg.name,
                        'min_select',
                          mg.min_select,
                        'max_select',
                          mg.max_select,
                        'is_required',
                          mg.is_required,
                        'sort_order',
                          pmg.sort_order,

                        'modifiers',
                        coalesce(
                          (
                            select jsonb_agg(
                              jsonb_build_object(
                                'id', m.id,
                                'name', m.name,
                                'price_delta_minor',
                                  m.price_delta_minor,
                                'sort_order',
                                  m.sort_order,
                                'is_available',
                                  m.is_available
                              )
                              order by
                                m.sort_order,
                                m.name
                            )
                            from public.modifiers m
                            where m.group_id = mg.id
                              and m.restaurant_id =
                                  mg.restaurant_id
                              and m.is_active = true
                          ),
                          '[]'::jsonb
                        )
                      )
                      order by
                        pmg.sort_order,
                        mg.sort_order,
                        mg.name
                    )
                    from public.product_modifier_groups pmg
                    join public.modifier_groups mg
                      on mg.id =
                         pmg.modifier_group_id
                     and mg.restaurant_id =
                         pmg.restaurant_id
                    where pmg.product_id = p.id
                      and mg.is_active = true
                  ),
                  '[]'::jsonb
                )
              )
              order by
                p.sort_order,
                p.name
            )
            from public.products p
            where p.category_id = c.id
              and p.branch_id = v_branch.id
              and p.restaurant_id =
                  v_restaurant.id
              and p.is_active = true
          ),
          '[]'::jsonb
        )
      ) as category_data

    from public.categories c
    where c.branch_id = v_branch.id
      and c.restaurant_id =
          v_restaurant.id
      and c.is_active = true
  ) q;

  return private.api_ok(
    jsonb_build_object(
      'restaurant',
      jsonb_build_object(
        'id', v_restaurant.id,
        'name', v_restaurant.name,
        'logo_path',
          v_restaurant.logo_path,
        'currency_code',
          v_restaurant.currency_code,
        'timezone',
          v_restaurant.timezone
      ),

      'branch',
      jsonb_build_object(
        'id', v_branch.id,
        'name', v_branch.name,
        'menu_version',
          v_branch.menu_version
      ),

      'ordering',
      jsonb_build_object(
        'allow_dine_in',
          v_allow_dine_in,
        'allow_takeaway',
          v_allow_takeaway,
        'allow_delivery',
          v_allow_delivery,
        'is_ordering_paused',
          v_ordering_paused,
        'pause_reason',
          v_pause_reason
      ),

      'categories',
        v_categories
    )
  );
end;
$$;

revoke all
on function public.get_public_menu(uuid)
from public, anon;

grant execute
on function public.get_public_menu(uuid)
to authenticated, service_role;

-- ============================================================================
-- 9. RPC: create_restaurant
-- ============================================================================

create or replace function public.create_restaurant(
  p_name text,
  p_slug text,
  p_currency_code text,
  p_timezone text,
  p_branch jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_restaurant_id uuid;
  v_branch_id uuid;

  v_branch_name text;
  v_branch_code text;
  v_branch_phone text;
  v_address_line1 text;
  v_city text;
  v_state text;
  v_postal_code text;
  v_country_code text;
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if p_name is null
     or btrim(p_name) = ''
     or p_slug is null
     or p_slug !~
        '^[a-z0-9]+(?:-[a-z0-9]+)*$'
     or p_currency_code !~
        '^[A-Z]{3}$'
     or p_timezone is null
     or p_branch is null
     or jsonb_typeof(p_branch) <> 'object' then
    return private.api_error(
      'CONFLICT',
      'Restaurant onboarding data is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_input'
      )
    );
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_timezone_names
    where name = p_timezone
  ) then
    return private.api_error(
      'CONFLICT',
      'Timezone is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_timezone'
      )
    );
  end if;

  v_branch_name :=
    nullif(
      btrim(
        p_branch ->> 'name'
      ),
      ''
    );

  if v_branch_name is null then
    return private.api_error(
      'CONFLICT',
      'Initial branch name is required.',
      jsonb_build_object(
        'reason',
        'invalid_branch'
      )
    );
  end if;

  v_branch_code :=
    nullif(
      btrim(
        p_branch ->> 'code'
      ),
      ''
    );

  v_branch_phone :=
    nullif(
      btrim(
        p_branch ->> 'phone'
      ),
      ''
    );

  v_address_line1 :=
    nullif(
      btrim(
        p_branch ->> 'address_line1'
      ),
      ''
    );

  v_city :=
    nullif(
      btrim(
        p_branch ->> 'city'
      ),
      ''
    );

  v_state :=
    nullif(
      btrim(
        p_branch ->> 'state'
      ),
      ''
    );

  v_postal_code :=
    nullif(
      btrim(
        p_branch ->> 'postal_code'
      ),
      ''
    );

  v_country_code := upper(
    coalesce(
      nullif(
        btrim(
          p_branch ->> 'country_code'
        ),
        ''
      ),
      'IN'
    )
  );

  if v_country_code !~
     '^[A-Z]{2}$' then
    return private.api_error(
      'CONFLICT',
      'Country code is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_country_code'
      )
    );
  end if;

  begin
    insert into public.restaurants (
      name,
      slug,
      currency_code,
      timezone,
      created_by
    )
    values (
      btrim(p_name),
      p_slug,
      p_currency_code,
      p_timezone,
      v_user_id
    )
    returning id
    into v_restaurant_id;

    insert into public.restaurant_settings (
      restaurant_id
    )
    values (
      v_restaurant_id
    );

    insert into public.restaurant_members (
      restaurant_id,
      user_id,
      role,
      is_active,
      invited_by
    )
    values (
      v_restaurant_id,
      v_user_id,
      'owner',
      true,
      null
    );

    insert into public.branches (
      restaurant_id,
      name,
      code,
      phone,
      address_line1,
      city,
      state,
      postal_code,
      country_code
    )
    values (
      v_restaurant_id,
      v_branch_name,
      v_branch_code,
      v_branch_phone,
      v_address_line1,
      v_city,
      v_state,
      v_postal_code,
      v_country_code
    )
    returning id
    into v_branch_id;

    insert into public.branch_settings (
      branch_id,
      restaurant_id
    )
    values (
      v_branch_id,
      v_restaurant_id
    );

    perform private.write_audit(
      v_restaurant_id,
      v_branch_id,
      'restaurant.created',
      'restaurant',
      v_restaurant_id,
      jsonb_build_object(
        'initial_branch_id',
          v_branch_id
      )
    );

  exception
    when unique_violation then
      return private.api_error(
        'CONFLICT',
        'Restaurant slug or branch code already exists.',
        jsonb_build_object(
          'reason',
          'unique_conflict'
        )
      );
  end;

  return private.api_ok(
    jsonb_build_object(
      'restaurant_id',
        v_restaurant_id,
      'branch_id',
        v_branch_id,
      'role',
        'owner'
    )
  );
end;
$$;

revoke all
on function public.create_restaurant(
  text,
  text,
  text,
  text,
  jsonb
)
from public, anon;

grant execute
on function public.create_restaurant(
  text,
  text,
  text,
  text,
  jsonb
)
to authenticated, service_role;

-- ============================================================================
-- 10. RPC: create_order
-- ============================================================================

create or replace function public.create_order(
  p_request jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_branch_id uuid;
  v_table_id uuid;
  v_order_type_text text;
  v_order_type public.order_type;
  v_idempotency_key text;

  v_customer_name text;
  v_customer_phone text;
  v_customer_note text;
  v_coupon_code text;

  v_restaurant public.restaurants%rowtype;
  v_branch public.branches%rowtype;
  v_table public.dining_tables%rowtype;
  v_rest_settings public.restaurant_settings%rowtype;
  v_branch_settings public.branch_settings%rowtype;

  v_allow_dine_in boolean;
  v_allow_takeaway boolean;
  v_allow_delivery boolean;
  v_require_payment boolean;

  v_default_tax_bp integer;
  v_service_charge_bp integer;
  v_tax_inclusive boolean;

  v_existing_order public.orders%rowtype;
  v_order_id uuid;
  v_order_status public.order_status;

  v_item jsonb;
  v_items_snapshot jsonb :=
    '[]'::jsonb;

  v_product public.products%rowtype;
  v_group record;
  v_modifier public.modifiers%rowtype;

  v_product_id uuid;
  v_quantity_text text;
  v_quantity integer;
  v_item_note text;

  v_modifier_ids_json jsonb;
  v_modifier_text text;
  v_modifier_id uuid;
  v_selected_modifier_ids uuid[];

  v_modifier_snapshots jsonb;
  v_item_modifier_total bigint;

  v_group_selected_count integer;

  v_tax_bp integer;
  v_item_gross bigint;
  v_item_tax bigint;
  v_item_subtotal bigint;
  v_line_total bigint;

  v_subtotal bigint := 0;
  v_tax bigint := 0;
  v_service_charge bigint := 0;
  v_delivery_fee bigint := 0;
  v_discount bigint := 0;
  v_total bigint := 0;

  v_coupon public.coupons%rowtype;
  v_coupon_total_uses bigint;
  v_coupon_customer_uses bigint;

  v_order_item_id uuid;
  v_item_snapshot jsonb;
  v_modifier_snapshot jsonb;

  v_now timestamptz := now();
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if p_request is null
     or jsonb_typeof(p_request)
        <> 'object' then
    return private.api_error(
      'INVALID_ORDER',
      'Order request is invalid.'
    );
  end if;

  v_branch_id := private.safe_uuid(
    p_request ->> 'branch_id'
  );

  if v_branch_id is null then
    return private.api_error(
      'INVALID_ORDER',
      'A valid branch is required.'
    );
  end if;

  v_order_type_text :=
    p_request ->> 'order_type';

  if v_order_type_text is null
     or v_order_type_text not in (
       'dine_in',
       'takeaway',
       'delivery'
     ) then
    return private.api_error(
      'INVALID_ORDER_TYPE',
      'Order type is invalid.'
    );
  end if;

  v_order_type :=
    v_order_type_text::public.order_type;

  v_idempotency_key :=
    nullif(
      btrim(
        p_request ->> 'idempotency_key'
      ),
      ''
    );

  if v_idempotency_key is null
     or char_length(v_idempotency_key)
        not between 8 and 128 then
    return private.api_error(
      'INVALID_IDEMPOTENCY_KEY',
      'A valid idempotency key is required.'
    );
  end if;

  if v_order_type = 'dine_in' then
    v_table_id := private.safe_uuid(
      p_request ->> 'table_id'
    );

    if v_table_id is null then
      return private.api_error(
        'TABLE_NOT_FOUND',
        'A table is required for dine-in orders.'
      );
    end if;
  else
    if nullif(
      p_request ->> 'table_id',
      ''
    ) is not null then
      return private.api_error(
        'INVALID_ORDER',
        'Table must be empty for this order type.'
      );
    end if;

    v_table_id := null;
  end if;

  -- Fast idempotency check.
  select *
  into v_existing_order
  from public.orders
  where customer_id = v_user_id
    and idempotency_key =
        v_idempotency_key
  limit 1;

  if found then
    if v_existing_order.branch_id <>
       v_branch_id
       or
       v_existing_order.order_type <>
       v_order_type
       or
       v_existing_order.table_id
         is distinct from v_table_id then
      return private.api_error(
        'CONFLICT',
        'This idempotency key was already used for a different order context.',
        jsonb_build_object(
          'order_id',
            v_existing_order.id
        )
      );
    end if;

    return private.api_ok(
      private.create_order_data(
        v_existing_order.id
      )
    );
  end if;

  if not (
    p_request ? 'items'
  )
  or jsonb_typeof(
    p_request -> 'items'
  ) <> 'array' then
    return private.api_error(
      'EMPTY_ORDER',
      'Order items are required.'
    );
  end if;

  if jsonb_array_length(
    p_request -> 'items'
  ) = 0 then
    return private.api_error(
      'EMPTY_ORDER',
      'Order items are required.'
    );
  end if;

  -- Keep an upper bound against abusive giant payloads.
  if jsonb_array_length(
    p_request -> 'items'
  ) > 200 then
    return private.api_error(
      'INVALID_ORDER',
      'Order contains too many line items.'
    );
  end if;

  select *
  into v_branch
  from public.branches
  where id = v_branch_id
  for share;

  if not found then
    return private.api_error(
      'BRANCH_NOT_FOUND',
      'Branch not found.'
    );
  end if;

  if not v_branch.is_active then
    return private.api_error(
      'BRANCH_INACTIVE',
      'This branch is not accepting orders.'
    );
  end if;

  select *
  into v_restaurant
  from public.restaurants
  where id = v_branch.restaurant_id
  for share;

  if not found
     or not v_restaurant.is_active then
    return private.api_error(
      'RESTAURANT_INACTIVE',
      'This restaurant is not accepting orders.'
    );
  end if;

  select *
  into v_rest_settings
  from public.restaurant_settings
  where restaurant_id = v_restaurant.id;

  select *
  into v_branch_settings
  from public.branch_settings
  where branch_id = v_branch.id;

  if coalesce(
    v_branch_settings.is_ordering_paused,
    false
  ) then
    return private.api_error(
      'ORDERING_PAUSED',
      coalesce(
        v_branch_settings.ordering_pause_reason,
        'Ordering is temporarily paused.'
      )
    );
  end if;

  if not private.is_branch_open_at(
    v_branch.id,
    v_now
  ) then
    return private.api_error(
      'RESTAURANT_CLOSED',
      'This restaurant is currently closed.'
    );
  end if;

  v_allow_dine_in := coalesce(
    v_branch_settings.allow_dine_in,
    v_rest_settings.allow_dine_in,
    true
  );

  v_allow_takeaway := coalesce(
    v_branch_settings.allow_takeaway,
    v_rest_settings.allow_takeaway,
    true
  );

  v_allow_delivery := coalesce(
    v_branch_settings.allow_delivery,
    v_rest_settings.allow_delivery,
    false
  );

  if (
    v_order_type = 'dine_in'
    and not v_allow_dine_in
  )
  or
  (
    v_order_type = 'takeaway'
    and not v_allow_takeaway
  )
  or
  (
    v_order_type = 'delivery'
    and not v_allow_delivery
  ) then
    return private.api_error(
      'ORDER_TYPE_DISABLED',
      'This order type is not currently available.'
    );
  end if;

  if v_order_type = 'dine_in' then
    select *
    into v_table
    from public.dining_tables
    where id = v_table_id
    for share;

    if not found then
      return private.api_error(
        'TABLE_NOT_FOUND',
        'Table not found.'
      );
    end if;

    if v_table.branch_id <>
       v_branch.id
       or
       v_table.restaurant_id <>
       v_restaurant.id then
      return private.api_error(
        'TABLE_BRANCH_MISMATCH',
        'This table does not belong to the selected branch.'
      );
    end if;

    if not v_table.is_active then
      return private.api_error(
        'TABLE_INACTIVE',
        'This table is currently unavailable.'
      );
    end if;
  end if;

  v_require_payment := coalesce(
    v_branch_settings.require_payment_before_kitchen,
    v_rest_settings.require_payment_before_kitchen,
    false
  );

  v_default_tax_bp := coalesce(
    v_branch_settings.default_tax_basis_points,
    v_rest_settings.default_tax_basis_points,
    0
  );

  v_service_charge_bp := coalesce(
    v_branch_settings.service_charge_basis_points,
    v_rest_settings.service_charge_basis_points,
    0
  );

  v_tax_inclusive :=
    v_restaurant.tax_inclusive;

  v_customer_name :=
    nullif(
      btrim(
        p_request ->> 'customer_name'
      ),
      ''
    );

  v_customer_phone :=
    nullif(
      btrim(
        p_request ->> 'customer_phone'
      ),
      ''
    );

  v_customer_note :=
    nullif(
      btrim(
        p_request ->> 'customer_note'
      ),
      ''
    );

  v_coupon_code :=
    nullif(
      btrim(
        p_request ->> 'coupon_code'
      ),
      ''
    );

  if v_customer_note is not null
     and char_length(
       v_customer_note
     ) > 1000 then
    return private.api_error(
      'INVALID_ORDER',
      'Order note is too long.'
    );
  end if;

  -- --------------------------------------------------------------------------
  -- Validate and price every item.
  -- --------------------------------------------------------------------------

  for v_item in
    select value
    from jsonb_array_elements(
      p_request -> 'items'
    )
  loop
    if jsonb_typeof(v_item)
       <> 'object' then
      return private.api_error(
        'INVALID_ORDER',
        'An order item is invalid.'
      );
    end if;

    v_product_id := private.safe_uuid(
      v_item ->> 'product_id'
    );

    if v_product_id is null then
      return private.api_error(
        'PRODUCT_NOT_FOUND',
        'A product is invalid.'
      );
    end if;

    v_quantity_text :=
      v_item ->> 'quantity';

    if v_quantity_text is null
       or v_quantity_text !~
          '^[0-9]+$' then
      return private.api_error(
        'INVALID_QUANTITY',
        'Item quantity is invalid.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    v_quantity :=
      v_quantity_text::integer;

    if v_quantity < 1
       or v_quantity > 999 then
      return private.api_error(
        'INVALID_QUANTITY',
        'Item quantity is invalid.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    v_item_note :=
      nullif(
        btrim(
          v_item ->> 'note'
        ),
        ''
      );

    if v_item_note is not null
       and char_length(
         v_item_note
       ) > 500 then
      return private.api_error(
        'INVALID_ORDER',
        'Item note is too long.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    select *
    into v_product
    from public.products
    where id = v_product_id
    for share;

    if not found then
      return private.api_error(
        'PRODUCT_NOT_FOUND',
        'A product no longer exists.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    if v_product.restaurant_id <>
       v_restaurant.id
       or
       v_product.branch_id <>
       v_branch.id then
      return private.api_error(
        'PRODUCT_BRANCH_MISMATCH',
        'A product does not belong to this branch.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    if not v_product.is_active then
      return private.api_error(
        'PRODUCT_INACTIVE',
        'A product is no longer available.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    if not v_product.is_available then
      return private.api_error(
        'PRODUCT_UNAVAILABLE',
        'A product is currently unavailable.',
        jsonb_build_object(
          'product_ids',
            jsonb_build_array(
              v_product_id
            )
        )
      );
    end if;

    v_selected_modifier_ids :=
      array[]::uuid[];

    v_modifier_snapshots :=
      '[]'::jsonb;

    v_item_modifier_total := 0;

    if v_item ? 'modifier_ids' then
      v_modifier_ids_json :=
        v_item -> 'modifier_ids';

      if v_modifier_ids_json is null
         or jsonb_typeof(
           v_modifier_ids_json
         ) <> 'array' then
        return private.api_error(
          'INVALID_MODIFIER',
          'Modifier selection is invalid.',
          jsonb_build_object(
            'product_id',
              v_product_id
          )
        );
      end if;
    else
      v_modifier_ids_json :=
        '[]'::jsonb;
    end if;

    if jsonb_array_length(
      v_modifier_ids_json
    ) > 100 then
      return private.api_error(
        'INVALID_MODIFIER',
        'Too many modifiers were selected.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    for v_modifier_text in
      select value
      from jsonb_array_elements_text(
        v_modifier_ids_json
      )
    loop
      v_modifier_id :=
        private.safe_uuid(
          v_modifier_text
        );

      if v_modifier_id is null then
        return private.api_error(
          'INVALID_MODIFIER',
          'A selected modifier is invalid.',
          jsonb_build_object(
            'product_id',
              v_product_id
          )
        );
      end if;

      if v_modifier_id = any(
        v_selected_modifier_ids
      ) then
        return private.api_error(
          'INVALID_MODIFIER',
          'A modifier was selected more than once.',
          jsonb_build_object(
            'modifier_id',
              v_modifier_id
          )
        );
      end if;

      select *
      into v_modifier
      from public.modifiers
      where id = v_modifier_id
        and restaurant_id =
            v_restaurant.id
      for share;

      if not found then
        return private.api_error(
          'INVALID_MODIFIER',
          'A selected modifier does not exist.',
          jsonb_build_object(
            'modifier_id',
              v_modifier_id
          )
        );
      end if;

      if not v_modifier.is_active
         or not v_modifier.is_available then
        return private.api_error(
          'MODIFIER_UNAVAILABLE',
          'A selected modifier is unavailable.',
          jsonb_build_object(
            'modifier_id',
              v_modifier_id
          )
        );
      end if;

      if not exists (
        select 1
        from public.product_modifier_groups pmg
        join public.modifier_groups mg
          on mg.id =
             pmg.modifier_group_id
         and mg.restaurant_id =
             pmg.restaurant_id
        where pmg.product_id =
              v_product.id
          and pmg.restaurant_id =
              v_restaurant.id
          and pmg.modifier_group_id =
              v_modifier.group_id
          and mg.is_active = true
      ) then
        return private.api_error(
          'MODIFIER_NOT_ALLOWED',
          'A selected modifier is not allowed for this product.',
          jsonb_build_object(
            'product_id',
              v_product_id,
            'modifier_id',
              v_modifier_id
          )
        );
      end if;

      v_selected_modifier_ids :=
        array_append(
          v_selected_modifier_ids,
          v_modifier_id
        );

      v_item_modifier_total :=
        v_item_modifier_total
        + v_modifier.price_delta_minor;

      v_modifier_snapshots :=
        v_modifier_snapshots
        || jsonb_build_array(
          jsonb_build_object(
            'modifier_id',
              v_modifier.id,
            'modifier_name',
              v_modifier.name,
            'price_delta_minor',
              v_modifier.price_delta_minor,
            'group_id',
              v_modifier.group_id
          )
        );
    end loop;

    -- Validate every active group assigned to the product.
    for v_group in
      select
        mg.id,
        mg.name,
        mg.min_select,
        mg.max_select,
        mg.is_required
      from public.product_modifier_groups pmg
      join public.modifier_groups mg
        on mg.id =
           pmg.modifier_group_id
       and mg.restaurant_id =
           pmg.restaurant_id
      where pmg.product_id =
            v_product.id
        and pmg.restaurant_id =
            v_restaurant.id
        and mg.is_active = true
      order by
        pmg.sort_order,
        mg.sort_order,
        mg.name
    loop
      select count(*)::integer
      into v_group_selected_count
      from public.modifiers m
      where m.group_id = v_group.id
        and m.id = any(
          v_selected_modifier_ids
        );

      if v_group_selected_count <
         v_group.min_select then
        if v_group.is_required
           and
           v_group_selected_count = 0 then
          return private.api_error(
            'MODIFIER_SELECTION_REQUIRED',
            'A required option was not selected.',
            jsonb_build_object(
              'product_id',
                v_product_id,
              'modifier_group_id',
                v_group.id,
              'modifier_group_name',
                v_group.name,
              'minimum',
                v_group.min_select
            )
          );
        end if;

        return private.api_error(
          'MODIFIER_SELECTION_TOO_FEW',
          'Too few options were selected.',
          jsonb_build_object(
            'product_id',
              v_product_id,
            'modifier_group_id',
              v_group.id,
            'minimum',
              v_group.min_select,
            'selected',
              v_group_selected_count
          )
        );
      end if;

      if v_group_selected_count >
         v_group.max_select then
        return private.api_error(
          'MODIFIER_SELECTION_TOO_MANY',
          'Too many options were selected.',
          jsonb_build_object(
            'product_id',
              v_product_id,
            'modifier_group_id',
              v_group.id,
            'maximum',
              v_group.max_select,
            'selected',
              v_group_selected_count
          )
        );
      end if;
    end loop;

    if (
      v_product.base_price_minor
      + v_item_modifier_total
    ) < 0 then
      return private.api_error(
        'INVALID_ORDER',
        'Configured item price is invalid.',
        jsonb_build_object(
          'product_id',
            v_product_id
        )
      );
    end if;

    v_tax_bp := coalesce(
      v_product.tax_basis_points_override,
      v_default_tax_bp,
      0
    );

    v_item_gross :=
      (
        v_product.base_price_minor
        + v_item_modifier_total
      ) * v_quantity;

    v_line_total :=
      v_item_gross;

    if v_tax_inclusive then
      if v_tax_bp = 0 then
        v_item_tax := 0;
      else
        v_item_tax := round(
          (
            v_item_gross::numeric
            * v_tax_bp::numeric
          )
          /
          (
            10000::numeric
            + v_tax_bp::numeric
          )
        )::bigint;
      end if;

      v_item_subtotal :=
        v_item_gross
        - v_item_tax;
    else
      v_item_subtotal :=
        v_item_gross;

      v_item_tax := round(
        (
          v_item_gross::numeric
          * v_tax_bp::numeric
        )
        / 10000::numeric
      )::bigint;
    end if;

    v_subtotal :=
      v_subtotal
      + v_item_subtotal;

    v_tax :=
      v_tax
      + v_item_tax;

    v_items_snapshot :=
      v_items_snapshot
      || jsonb_build_array(
        jsonb_build_object(
          'product_id',
            v_product.id,
          'product_name',
            v_product.name,
          'unit_price_minor',
            v_product.base_price_minor,
          'quantity',
            v_quantity,
          'modifiers_total_minor',
            v_item_modifier_total,
          'line_total_minor',
            v_line_total,
          'item_note',
            v_item_note,
          'modifiers',
            v_modifier_snapshots
        )
      );
  end loop;

  if v_subtotal < 0
     or v_tax < 0 then
    return private.api_error(
      'INVALID_ORDER',
      'Calculated order amount is invalid.'
    );
  end if;

  if v_branch_settings.minimum_order_minor
     is not null
     and v_subtotal <
         v_branch_settings.minimum_order_minor then
    return private.api_error(
      'INVALID_ORDER',
      'Order does not meet the minimum amount.',
      jsonb_build_object(
        'minimum_order_minor',
          v_branch_settings.minimum_order_minor,
        'subtotal_minor',
          v_subtotal
      )
    );
  end if;

  v_service_charge := round(
    (
      v_subtotal::numeric
      * v_service_charge_bp::numeric
    )
    / 10000::numeric
  )::bigint;

  -- Delivery fee remains zero in the MVP until delivery-zone pricing exists.
  v_delivery_fee := 0;

  -- --------------------------------------------------------------------------
  -- Coupon validation / discount.
  -- --------------------------------------------------------------------------

  if v_coupon_code is not null then
    select *
    into v_coupon
    from public.coupons
    where restaurant_id =
          v_restaurant.id
      and lower(code) =
          lower(v_coupon_code)
    for update;

    if not found then
      return private.api_error(
        'COUPON_INVALID',
        'Coupon code is invalid.'
      );
    end if;

    if not v_coupon.is_active then
      return private.api_error(
        'COUPON_INACTIVE',
        'This coupon is not active.'
      );
    end if;

    if v_coupon.starts_at is not null
       and v_now <
           v_coupon.starts_at then
      return private.api_error(
        'COUPON_NOT_STARTED',
        'This coupon is not active yet.'
      );
    end if;

    if v_coupon.ends_at is not null
       and v_now >=
           v_coupon.ends_at then
      return private.api_error(
        'COUPON_EXPIRED',
        'This coupon has expired.'
      );
    end if;

    if v_subtotal <
       v_coupon.minimum_order_minor then
      return private.api_error(
        'COUPON_MINIMUM_NOT_MET',
        'Order does not meet the coupon minimum.',
        jsonb_build_object(
          'minimum_order_minor',
            v_coupon.minimum_order_minor
        )
      );
    end if;

    if v_coupon.max_total_uses
       is not null then
      select count(*)
      into v_coupon_total_uses
      from public.order_discounts od
      join public.orders o
        on o.id = od.order_id
      where od.coupon_id =
            v_coupon.id
        and o.status <>
            'cancelled';

      if v_coupon_total_uses >=
         v_coupon.max_total_uses then
        return private.api_error(
          'COUPON_USAGE_LIMIT_REACHED',
          'This coupon has reached its usage limit.'
        );
      end if;
    end if;

    if v_coupon.max_uses_per_customer
       is not null then
      select count(*)
      into v_coupon_customer_uses
      from public.order_discounts od
      join public.orders o
        on o.id = od.order_id
      where od.coupon_id =
            v_coupon.id
        and o.customer_id =
            v_user_id
        and o.status <>
            'cancelled';

      if v_coupon_customer_uses >=
         v_coupon.max_uses_per_customer then
        return private.api_error(
          'COUPON_USAGE_LIMIT_REACHED',
          'You have reached the usage limit for this coupon.'
        );
      end if;
    end if;

    if v_coupon.discount_type =
       'fixed' then
      v_discount :=
        v_coupon.discount_value;
    else
      v_discount := round(
        (
          v_subtotal::numeric
          * v_coupon.discount_value::numeric
        )
        / 10000::numeric
      )::bigint;
    end if;

    if v_coupon.maximum_discount_minor
       is not null then
      v_discount := least(
        v_discount,
        v_coupon.maximum_discount_minor
      );
    end if;
  end if;

  v_discount := greatest(
    0,
    least(
      v_discount,
      v_subtotal
      + v_tax
      + v_service_charge
      + v_delivery_fee
    )
  );

  v_total :=
    v_subtotal
    + v_tax
    + v_service_charge
    + v_delivery_fee
    - v_discount;

  if v_total < 0 then
    return private.api_error(
      'INVALID_ORDER',
      'Calculated order total is invalid.'
    );
  end if;

  if v_require_payment then
    v_order_status :=
      'awaiting_payment';
  else
    v_order_status :=
      'placed';
  end if;

  -- --------------------------------------------------------------------------
  -- Atomic insert. Unique-idempotency races are recovered safely.
  -- --------------------------------------------------------------------------

  begin
    insert into public.orders (
      restaurant_id,
      branch_id,
      table_id,
      customer_id,
      order_type,
      status,
      currency_code,
      subtotal_minor,
      tax_minor,
      service_charge_minor,
      delivery_fee_minor,
      discount_minor,
      total_minor,
      customer_name_snapshot,
      customer_phone_snapshot,
      customer_note,
      idempotency_key,
      placed_at
    )
    values (
      v_restaurant.id,
      v_branch.id,
      v_table_id,
      v_user_id,
      v_order_type,
      v_order_status,
      v_restaurant.currency_code,
      v_subtotal,
      v_tax,
      v_service_charge,
      v_delivery_fee,
      v_discount,
      v_total,
      v_customer_name,
      v_customer_phone,
      v_customer_note,
      v_idempotency_key,
      case
        when v_order_status =
             'placed'
          then v_now
        else null
      end
    )
    returning id
    into v_order_id;

    for v_item_snapshot in
      select value
      from jsonb_array_elements(
        v_items_snapshot
      )
    loop
      insert into public.order_items (
        order_id,
        product_id,
        product_name,
        unit_price_minor,
        quantity,
        modifiers_total_minor,
        line_total_minor,
        item_note
      )
      values (
        v_order_id,
        (
          v_item_snapshot
          ->> 'product_id'
        )::uuid,
        v_item_snapshot
          ->> 'product_name',
        (
          v_item_snapshot
          ->> 'unit_price_minor'
        )::bigint,
        (
          v_item_snapshot
          ->> 'quantity'
        )::integer,
        (
          v_item_snapshot
          ->> 'modifiers_total_minor'
        )::bigint,
        (
          v_item_snapshot
          ->> 'line_total_minor'
        )::bigint,
        nullif(
          v_item_snapshot
          ->> 'item_note',
          ''
        )
      )
      returning id
      into v_order_item_id;

      for v_modifier_snapshot in
        select value
        from jsonb_array_elements(
          coalesce(
            v_item_snapshot
              -> 'modifiers',
            '[]'::jsonb
          )
        )
      loop
        insert into public.order_item_modifiers (
          order_item_id,
          modifier_id,
          modifier_name,
          price_delta_minor
        )
        values (
          v_order_item_id,
          (
            v_modifier_snapshot
            ->> 'modifier_id'
          )::uuid,
          v_modifier_snapshot
            ->> 'modifier_name',
          (
            v_modifier_snapshot
            ->> 'price_delta_minor'
          )::bigint
        );
      end loop;
    end loop;

    insert into public.order_status_history (
      order_id,
      old_status,
      new_status,
      changed_by,
      reason
    )
    values (
      v_order_id,
      null,
      v_order_status,
      v_user_id,
      null
    );

    if v_discount > 0
       and v_coupon.id is not null then
      insert into public.order_discounts (
        order_id,
        coupon_id,
        code_snapshot,
        discount_type,
        discount_value_snapshot,
        discount_minor
      )
      values (
        v_order_id,
        v_coupon.id,
        v_coupon.code,
        v_coupon.discount_type,
        v_coupon.discount_value,
        v_discount
      );
    end if;

  exception
    when unique_violation then
      select *
      into v_existing_order
      from public.orders
      where customer_id = v_user_id
        and idempotency_key =
            v_idempotency_key
      limit 1;

      if found then
        return private.api_ok(
          private.create_order_data(
            v_existing_order.id
          )
        );
      end if;

      raise;
  end;

  return private.api_ok(
    private.create_order_data(
      v_order_id
    )
  );
end;
$$;

revoke all
on function public.create_order(jsonb)
from public, anon;

grant execute
on function public.create_order(jsonb)
to authenticated, service_role;

-- ============================================================================
-- 11. RPC: get_order_details
-- ============================================================================

create or replace function public.get_order_details(
  p_order_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_order public.orders%rowtype;
  v_restaurant public.restaurants%rowtype;
  v_branch public.branches%rowtype;
  v_table public.dining_tables%rowtype;

  v_is_customer boolean;
  v_is_staff boolean;
  v_role public.staff_role;

  v_items jsonb;
  v_status_history jsonb;
  v_payment jsonb;
  v_customer jsonb;
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id;

  if not found then
    return private.api_error(
      'ORDER_NOT_FOUND',
      'Order not found.'
    );
  end if;

  v_is_customer :=
    v_order.customer_id = v_user_id;

  v_is_staff :=
    private.can_access_branch(
      v_order.branch_id
    );

  if not v_is_customer
     and not v_is_staff then
    -- Deliberately hide foreign-order existence.
    return private.api_error(
      'ORDER_NOT_FOUND',
      'Order not found.'
    );
  end if;

  if v_is_staff then
    v_role :=
      private.restaurant_role(
        v_order.restaurant_id
      );
  end if;

  select *
  into v_restaurant
  from public.restaurants
  where id = v_order.restaurant_id;

  select *
  into v_branch
  from public.branches
  where id = v_order.branch_id;

  if v_order.table_id is not null then
    select *
    into v_table
    from public.dining_tables
    where id = v_order.table_id;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', oi.id,
        'product_id',
          oi.product_id,
        'product_name',
          oi.product_name,
        'unit_price_minor',
          oi.unit_price_minor,
        'quantity',
          oi.quantity,
        'modifiers_total_minor',
          oi.modifiers_total_minor,
        'line_total_minor',
          oi.line_total_minor,
        'item_note',
          oi.item_note,
        'modifiers',
          coalesce(
            (
              select jsonb_agg(
                jsonb_build_object(
                  'id', oim.id,
                  'modifier_id',
                    oim.modifier_id,
                  'modifier_name',
                    oim.modifier_name,
                  'price_delta_minor',
                    oim.price_delta_minor
                )
                order by
                  oim.created_at,
                  oim.id
              )
              from public.order_item_modifiers oim
              where oim.order_item_id =
                    oi.id
            ),
            '[]'::jsonb
          )
      )
      order by
        oi.created_at,
        oi.id
    ),
    '[]'::jsonb
  )
  into v_items
  from public.order_items oi
  where oi.order_id = v_order.id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', osh.id,
        'order_id',
          osh.order_id,
        'old_status',
          case
            when osh.old_status is null
              then null
            else osh.old_status::text
          end,
        'new_status',
          osh.new_status::text,
        'changed_by',
          case
            when v_is_staff
             and v_role in (
               'owner'::public.staff_role,
               'manager'::public.staff_role
             )
              then osh.changed_by
            else null
          end,
        'reason',
          osh.reason,
        'created_at',
          osh.created_at
      )
      order by
        osh.created_at,
        osh.id
    ),
    '[]'::jsonb
  )
  into v_status_history
  from public.order_status_history osh
  where osh.order_id = v_order.id;

  select jsonb_build_object(
    'id', p.id,
    'order_id', p.order_id,
    'method', p.method::text,
    'amount_minor',
      p.amount_minor,
    'currency_code',
      p.currency_code,
    'status',
      p.status::text,
    'paid_at',
      p.paid_at,
    'refunded_at',
      p.refunded_at
  )
  into v_payment
  from public.payments p
  where p.order_id = v_order.id
  order by
    case p.status
      when 'paid' then 1
      when 'partially_refunded' then 2
      when 'refunded' then 3
      when 'authorized' then 4
      when 'pending' then 5
      when 'failed' then 6
      when 'cancelled' then 7
      else 99
    end,
    p.created_at desc
  limit 1;

  if v_is_customer
     or (
       v_is_staff
       and v_role <>
           'kitchen'
     ) then
    v_customer :=
      jsonb_build_object(
        'name',
          v_order.customer_name_snapshot,
        'phone',
          v_order.customer_phone_snapshot
      );
  else
    v_customer := null;
  end if;

  return private.api_ok(
    jsonb_build_object(
      'order',
      jsonb_build_object(
        'id', v_order.id,
        'order_number',
          v_order.order_number,
        'restaurant_id',
          v_order.restaurant_id,
        'branch_id',
          v_order.branch_id,
        'table_id',
          v_order.table_id,
        'order_type',
          v_order.order_type::text,
        'status',
          v_order.status::text,
        'currency_code',
          v_order.currency_code,
        'subtotal_minor',
          v_order.subtotal_minor,
        'tax_minor',
          v_order.tax_minor,
        'service_charge_minor',
          v_order.service_charge_minor,
        'delivery_fee_minor',
          v_order.delivery_fee_minor,
        'discount_minor',
          v_order.discount_minor,
        'total_minor',
          v_order.total_minor,
        'customer_note',
          v_order.customer_note,
        'placed_at',
          v_order.placed_at,
        'completed_at',
          v_order.completed_at,
        'cancelled_at',
          v_order.cancelled_at,
        'created_at',
          v_order.created_at,
        'updated_at',
          v_order.updated_at
      ),

      'restaurant',
      jsonb_build_object(
        'id', v_restaurant.id,
        'name', v_restaurant.name,
        'logo_path',
          v_restaurant.logo_path
      ),

      'branch',
      jsonb_build_object(
        'id', v_branch.id,
        'name', v_branch.name
      ),

      'table',
      case
        when v_order.table_id is null
          then null
        else jsonb_build_object(
          'id', v_table.id,
          'name', v_table.name,
          'capacity',
            v_table.capacity
        )
      end,

      'customer',
        v_customer,

      'items',
        v_items,

      'payment',
        v_payment,

      'status_history',
        v_status_history
    )
  );
end;
$$;

revoke all
on function public.get_order_details(uuid)
from public, anon;

grant execute
on function public.get_order_details(uuid)
to authenticated, service_role;

-- ============================================================================
-- 12. RPC: change_order_status
-- ============================================================================

create or replace function public.change_order_status(
  p_order_id uuid,
  p_new_status public.order_status,
  p_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_order public.orders%rowtype;
  v_role public.staff_role;
  v_old_status public.order_status;
  v_now timestamptz := now();
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    return private.api_error(
      'ORDER_NOT_FOUND',
      'Order not found.'
    );
  end if;

  if not private.can_access_branch(
    v_order.branch_id
  ) then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'You do not have access to this branch.'
    );
  end if;

  v_role :=
    private.restaurant_role(
      v_order.restaurant_id
    );

  if v_role is null then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to update this order.'
    );
  end if;

  if p_new_status = 'cancelled' then
    return private.api_error(
      'INVALID_STATUS_TRANSITION',
      'Use the cancellation operation to cancel an order.'
    );
  end if;

  if v_order.status = p_new_status then
    return private.api_ok(
      jsonb_build_object(
        'order_id',
          v_order.id,
        'old_status',
          v_order.status::text,
        'new_status',
          v_order.status::text,
        'updated_at',
          v_order.updated_at
      )
    );
  end if;

  if v_order.status = 'completed' then
    return private.api_error(
      'ORDER_ALREADY_COMPLETED',
      'This order is already completed.'
    );
  end if;

  if v_order.status = 'cancelled' then
    return private.api_error(
      'ORDER_ALREADY_CANCELLED',
      'This order is already cancelled.'
    );
  end if;

  if not private.is_legal_order_transition(
    v_order.status,
    p_new_status,
    v_order.order_type
  ) then
    return private.api_error(
      'INVALID_STATUS_TRANSITION',
      'This status transition is not allowed.',
      jsonb_build_object(
        'current_status',
          v_order.status::text,
        'requested_status',
          p_new_status::text
      )
    );
  end if;

  if not private.role_can_transition_order(
    v_role,
    v_order.status,
    p_new_status,
    v_order.order_type
  ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'Your role cannot perform this status transition.'
    );
  end if;

  v_old_status :=
    v_order.status;

  update public.orders
  set
    status = p_new_status,
    completed_at = case
      when p_new_status =
           'completed'
        then v_now
      else completed_at
    end
  where id = v_order.id;

  insert into public.order_status_history (
    order_id,
    old_status,
    new_status,
    changed_by,
    reason
  )
  values (
    v_order.id,
    v_old_status,
    p_new_status,
    v_user_id,
    nullif(
      btrim(p_reason),
      ''
    )
  );

  perform private.write_audit(
    v_order.restaurant_id,
    v_order.branch_id,
    'order.status_changed',
    'order',
    v_order.id,
    jsonb_build_object(
      'old_status',
        v_old_status::text,
      'new_status',
        p_new_status::text
    )
  );

  return private.api_ok(
    jsonb_build_object(
      'order_id',
        v_order.id,
      'old_status',
        v_old_status::text,
      'new_status',
        p_new_status::text,
      'updated_at',
        v_now
    )
  );
end;
$$;

revoke all
on function public.change_order_status(
  uuid,
  public.order_status,
  text
)
from public, anon;

grant execute
on function public.change_order_status(
  uuid,
  public.order_status,
  text
)
to authenticated, service_role;

-- ============================================================================
-- 13. RPC: cancel_order
-- ============================================================================

create or replace function public.cancel_order(
  p_order_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_order public.orders%rowtype;
  v_role public.staff_role;
  v_allowed boolean := false;
  v_refund_required boolean := false;
  v_now timestamptz := now();
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    return private.api_error(
      'ORDER_NOT_FOUND',
      'Order not found.'
    );
  end if;

  if not private.can_access_branch(
    v_order.branch_id
  ) then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'You do not have access to this branch.'
    );
  end if;

  v_role :=
    private.restaurant_role(
      v_order.restaurant_id
    );

  if v_role is null then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to cancel this order.'
    );
  end if;

  if v_order.status = 'cancelled' then
    select exists (
      select 1
      from public.payments p
      where p.order_id = v_order.id
        and p.status in (
          'authorized',
          'paid',
          'partially_refunded'
        )
    )
    into v_refund_required;

    return private.api_ok(
      jsonb_build_object(
        'order_id',
          v_order.id,
        'status',
          'cancelled',
        'cancelled_at',
          v_order.cancelled_at,
        'refund_required',
          v_refund_required
      )
    );
  end if;

  if v_order.status = 'completed' then
    return private.api_error(
      'ORDER_ALREADY_COMPLETED',
      'Completed orders cannot be cancelled.'
    );
  end if;

  if v_role in (
    'owner'::public.staff_role,
    'manager'::public.staff_role
  ) then
    v_allowed :=
      v_order.status in (
        'awaiting_payment',
        'placed',
        'accepted',
        'preparing',
        'ready'
      );

  elsif v_role = 'cashier' then
    v_allowed :=
      v_order.status in (
        'awaiting_payment',
        'placed',
        'accepted'
      );

  elsif v_role = 'waiter' then
    v_allowed :=
      v_order.status in (
        'placed',
        'accepted'
      );

  else
    v_allowed := false;
  end if;

  if not v_allowed then
    return private.api_error(
      'ORDER_NOT_CANCELLABLE',
      'This order cannot be cancelled by your role at its current status.'
    );
  end if;

  update public.orders
  set
    status = 'cancelled',
    cancelled_at = v_now
  where id = v_order.id;

  insert into public.order_status_history (
    order_id,
    old_status,
    new_status,
    changed_by,
    reason
  )
  values (
    v_order.id,
    v_order.status,
    'cancelled',
    v_user_id,
    nullif(
      btrim(p_reason),
      ''
    )
  );

  select exists (
    select 1
    from public.payments p
    where p.order_id = v_order.id
      and p.status in (
        'authorized',
        'paid',
        'partially_refunded'
      )
  )
  into v_refund_required;

  perform private.write_audit(
    v_order.restaurant_id,
    v_order.branch_id,
    'order.cancelled',
    'order',
    v_order.id,
    jsonb_build_object(
      'old_status',
        v_order.status::text,
      'reason',
        nullif(
          btrim(p_reason),
          ''
        ),
      'refund_required',
        v_refund_required
    )
  );

  return private.api_ok(
    jsonb_build_object(
      'order_id',
        v_order.id,
      'status',
        'cancelled',
      'cancelled_at',
        v_now,
      'refund_required',
        v_refund_required
    )
  );
end;
$$;

revoke all
on function public.cancel_order(
  uuid,
  text
)
from public, anon;

grant execute
on function public.cancel_order(
  uuid,
  text
)
to authenticated, service_role;

-- ============================================================================
-- 14. RPC: confirm_cash_payment
-- ============================================================================

create or replace function public.confirm_cash_payment(
  p_order_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_order public.orders%rowtype;
  v_role public.staff_role;
  v_payment public.payments%rowtype;
  v_old_status public.order_status;
  v_now timestamptz := now();
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    return private.api_error(
      'ORDER_NOT_FOUND',
      'Order not found.'
    );
  end if;

  if not private.can_access_branch(
    v_order.branch_id
  ) then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'You do not have access to this branch.'
    );
  end if;

  v_role :=
    private.restaurant_role(
      v_order.restaurant_id
    );

  if v_role is null
     or v_role not in (
       'owner'::public.staff_role,
       'manager'::public.staff_role,
       'cashier'::public.staff_role
     ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to confirm cash payment.'
    );
  end if;

  if v_order.status = 'cancelled' then
    return private.api_error(
      'ORDER_ALREADY_CANCELLED',
      'Cancelled orders cannot receive cash payment.'
    );
  end if;

  -- If a non-cash payment is already authoritative, prevent double collection.
  if exists (
    select 1
    from public.payments p
    where p.order_id = v_order.id
      and p.method <> 'cash'
      and p.status in (
        'paid',
        'partially_refunded',
        'refunded'
      )
  ) then
    return private.api_error(
      'PAYMENT_ALREADY_PAID',
      'This order is already paid.'
    );
  end if;

  if exists (
    select 1
    from public.payments p
    where p.order_id = v_order.id
      and p.method <> 'cash'
      and p.status in (
        'pending',
        'authorized'
      )
  ) then
    return private.api_error(
      'PAYMENT_ALREADY_IN_PROGRESS',
      'An online payment is already in progress.'
    );
  end if;

  select *
  into v_payment
  from public.payments p
  where p.order_id = v_order.id
    and p.method = 'cash'
  order by p.created_at desc
  limit 1
  for update;

  if found
     and v_payment.status in (
       'paid',
       'partially_refunded',
       'refunded'
     ) then
    return private.api_ok(
      jsonb_build_object(
        'payment',
        jsonb_build_object(
          'id',
            v_payment.id,
          'order_id',
            v_payment.order_id,
          'method',
            v_payment.method::text,
          'amount_minor',
            v_payment.amount_minor,
          'currency_code',
            v_payment.currency_code,
          'status',
            v_payment.status::text,
          'paid_at',
            v_payment.paid_at
        )
      )
    );
  end if;

  if found then
    if v_payment.amount_minor <>
       v_order.total_minor
       or
       v_payment.currency_code <>
       v_order.currency_code then
      return private.api_error(
        'PAYMENT_AMOUNT_MISMATCH',
        'Existing cash payment amount does not match the order.'
      );
    end if;

    update public.payments
    set
      status = 'paid',
      failure_code = null,
      failure_message = null,
      paid_at = v_now
    where id = v_payment.id
    returning *
    into v_payment;
  else
    insert into public.payments (
      order_id,
      method,
      provider,
      amount_minor,
      currency_code,
      status,
      paid_at
    )
    values (
      v_order.id,
      'cash',
      null,
      v_order.total_minor,
      v_order.currency_code,
      'paid',
      v_now
    )
    returning *
    into v_payment;
  end if;

  if v_order.status =
     'awaiting_payment' then
    v_old_status :=
      v_order.status;

    update public.orders
    set
      status = 'placed',
      placed_at = coalesce(
        placed_at,
        v_now
      )
    where id = v_order.id;

    insert into public.order_status_history (
      order_id,
      old_status,
      new_status,
      changed_by,
      reason
    )
    values (
      v_order.id,
      v_old_status,
      'placed',
      v_user_id,
      'Cash payment confirmed'
    );
  end if;

  perform private.write_audit(
    v_order.restaurant_id,
    v_order.branch_id,
    'payment.cash_confirmed',
    'payment',
    v_payment.id,
    jsonb_build_object(
      'order_id',
        v_order.id,
      'amount_minor',
        v_payment.amount_minor
    )
  );

  return private.api_ok(
    jsonb_build_object(
      'payment',
      jsonb_build_object(
        'id',
          v_payment.id,
        'order_id',
          v_payment.order_id,
        'method',
          v_payment.method::text,
        'amount_minor',
          v_payment.amount_minor,
        'currency_code',
          v_payment.currency_code,
        'status',
          v_payment.status::text,
        'paid_at',
          v_payment.paid_at
      )
    )
  );
end;
$$;

revoke all
on function public.confirm_cash_payment(uuid)
from public, anon;

grant execute
on function public.confirm_cash_payment(uuid)
to authenticated, service_role;

-- ============================================================================
-- 15. RPC: rotate_table_qr
-- ============================================================================

create or replace function public.rotate_table_qr(
  p_table_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_table public.dining_tables%rowtype;
  v_new_token uuid;
begin
  if (select auth.uid()) is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  select *
  into v_table
  from public.dining_tables
  where id = p_table_id
  for update;

  if not found then
    return private.api_error(
      'TABLE_NOT_FOUND',
      'Table not found.'
    );
  end if;

  if not private.can_manage_branch(
    v_table.branch_id
  ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to rotate this QR code.'
    );
  end if;

  v_new_token :=
    gen_random_uuid();

  update public.dining_tables
  set qr_token =
      v_new_token
  where id = v_table.id;

  perform private.write_audit(
    v_table.restaurant_id,
    v_table.branch_id,
    'table.qr_rotated',
    'dining_table',
    v_table.id,
    '{}'::jsonb
  );

  return private.api_ok(
    jsonb_build_object(
      'table_id',
        v_table.id,
      'qr_token',
        v_new_token,
      'qr_url',
        private.order_base_url()
        || '/q/'
        || v_new_token::text
    )
  );
end;
$$;

revoke all
on function public.rotate_table_qr(uuid)
from public, anon;

grant execute
on function public.rotate_table_qr(uuid)
to authenticated, service_role;

-- ============================================================================
-- 16. RPC: get_dashboard_summary
-- ============================================================================

create or replace function public.get_dashboard_summary(
  p_branch_id uuid,
  p_start_at timestamptz,
  p_end_at timestamptz
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch public.branches%rowtype;
  v_role public.staff_role;

  v_orders_count bigint;
  v_gross bigint;
  v_paid bigint;
  v_refunds bigint;
  v_net bigint;
  v_average bigint;
  v_active_count bigint;

  v_status_counts jsonb;
  v_payment_totals jsonb;
  v_top_products jsonb;
begin
  if (select auth.uid()) is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if p_start_at is null
     or p_end_at is null
     or p_end_at <= p_start_at then
    return private.api_error(
      'CONFLICT',
      'Report date range is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_range'
      )
    );
  end if;

  select *
  into v_branch
  from public.branches
  where id = p_branch_id;

  if not found then
    return private.api_error(
      'BRANCH_NOT_FOUND',
      'Branch not found.'
    );
  end if;

  if not private.can_access_branch(
    p_branch_id
  ) then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'You do not have access to this branch.'
    );
  end if;

  v_role :=
    private.restaurant_role(
      v_branch.restaurant_id
    );

  if v_role is null
     or v_role not in (
       'owner'::public.staff_role,
       'manager'::public.staff_role,
       'cashier'::public.staff_role
     ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to view financial dashboard data.'
    );
  end if;

  select
    count(*)::bigint,
    coalesce(
      sum(o.total_minor)
        filter (
          where o.status <>
                'cancelled'
        ),
      0
    )::bigint
  into
    v_orders_count,
    v_gross
  from public.orders o
  where o.branch_id = p_branch_id
    and o.created_at >=
        p_start_at
    and o.created_at <
        p_end_at;

  select coalesce(
    sum(p.amount_minor),
    0
  )::bigint
  into v_paid
  from public.payments p
  join public.orders o
    on o.id = p.order_id
  where o.branch_id = p_branch_id
    and p.paid_at >=
        p_start_at
    and p.paid_at <
        p_end_at
    and p.status in (
      'paid',
      'partially_refunded',
      'refunded'
    );

  select coalesce(
    sum(pr.amount_minor),
    0
  )::bigint
  into v_refunds
  from public.payment_refunds pr
  join public.payments p
    on p.id = pr.payment_id
  join public.orders o
    on o.id = p.order_id
  where o.branch_id = p_branch_id
    and pr.created_at >=
        p_start_at
    and pr.created_at <
        p_end_at
    and pr.status =
        'succeeded';

  v_net := greatest(
    0,
    v_paid - v_refunds
  );

  if v_orders_count > 0 then
    v_average := round(
      v_gross::numeric
      / v_orders_count::numeric
    )::bigint;
  else
    v_average := 0;
  end if;

  select count(*)::bigint
  into v_active_count
  from public.orders o
  where o.branch_id = p_branch_id
    and o.status in (
      'awaiting_payment',
      'placed',
      'accepted',
      'preparing',
      'ready',
      'served'
    );

  select jsonb_build_object(
    'placed',
      count(*) filter (
        where status = 'placed'
      ),
    'accepted',
      count(*) filter (
        where status = 'accepted'
      ),
    'preparing',
      count(*) filter (
        where status = 'preparing'
      ),
    'ready',
      count(*) filter (
        where status = 'ready'
      )
  )
  into v_status_counts
  from public.orders
  where branch_id = p_branch_id
    and status in (
      'placed',
      'accepted',
      'preparing',
      'ready'
    );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'method',
          payment_method,
        'amount_minor',
          amount_minor
      )
      order by payment_method
    ),
    '[]'::jsonb
  )
  into v_payment_totals
  from (
    select
      p.method::text
        as payment_method,
      sum(p.amount_minor)::bigint
        as amount_minor
    from public.payments p
    join public.orders o
      on o.id = p.order_id
    where o.branch_id = p_branch_id
      and p.paid_at >=
          p_start_at
      and p.paid_at <
          p_end_at
      and p.status in (
        'paid',
        'partially_refunded',
        'refunded'
      )
    group by p.method
  ) payment_group;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id',
          product_id,
        'product_name',
          product_name,
        'quantity',
          quantity,
        'sales_minor',
          sales_minor
      )
      order by
        quantity desc,
        sales_minor desc,
        product_name
    ),
    '[]'::jsonb
  )
  into v_top_products
  from (
    select
      oi.product_id,
      oi.product_name,
      sum(oi.quantity)::bigint
        as quantity,
      sum(oi.line_total_minor)::bigint
        as sales_minor
    from public.order_items oi
    join public.orders o
      on o.id = oi.order_id
    where o.branch_id = p_branch_id
      and o.created_at >=
          p_start_at
      and o.created_at <
          p_end_at
      and o.status <>
          'cancelled'
    group by
      oi.product_id,
      oi.product_name
    order by
      quantity desc,
      sales_minor desc
    limit 10
  ) top_product_rows;

  return private.api_ok(
    jsonb_build_object(
      'currency_code',
        (
          select r.currency_code
          from public.restaurants r
          where r.id =
                v_branch.restaurant_id
        ),
      'orders_count',
        v_orders_count,
      'gross_order_value_minor',
        v_gross,
      'paid_revenue_minor',
        v_paid,
      'refunds_minor',
        v_refunds,
      'net_revenue_minor',
        v_net,
      'average_order_value_minor',
        v_average,
      'active_orders_count',
        v_active_count,
      'status_counts',
        v_status_counts,
      'payment_method_totals',
        v_payment_totals,
      'top_products',
        v_top_products
    )
  );
end;
$$;

revoke all
on function public.get_dashboard_summary(
  uuid,
  timestamptz,
  timestamptz
)
from public, anon;

grant execute
on function public.get_dashboard_summary(
  uuid,
  timestamptz,
  timestamptz
)
to authenticated, service_role;

-- ============================================================================
-- 17. RPC: get_sales_report
-- ============================================================================

create or replace function public.get_sales_report(
  p_branch_id uuid,
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_group_by text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch public.branches%rowtype;
  v_restaurant public.restaurants%rowtype;
  v_role public.staff_role;

  v_orders_count bigint;
  v_gross bigint;
  v_paid bigint;
  v_refunds bigint;
  v_net bigint;
  v_average bigint;

  v_series jsonb;
begin
  if (select auth.uid()) is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if p_start_at is null
     or p_end_at is null
     or p_end_at <= p_start_at then
    return private.api_error(
      'CONFLICT',
      'Report date range is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_range'
      )
    );
  end if;

  if p_group_by is null
     or p_group_by not in (
       'hour',
       'day',
       'week',
       'month'
     ) then
    return private.api_error(
      'CONFLICT',
      'Report grouping is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_group_by'
      )
    );
  end if;

  select *
  into v_branch
  from public.branches
  where id = p_branch_id;

  if not found then
    return private.api_error(
      'BRANCH_NOT_FOUND',
      'Branch not found.'
    );
  end if;

  if not private.can_access_branch(
    p_branch_id
  ) then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'You do not have access to this branch.'
    );
  end if;

  v_role :=
    private.restaurant_role(
      v_branch.restaurant_id
    );

  if v_role is null
     or v_role not in (
       'owner'::public.staff_role,
       'manager'::public.staff_role
     ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to view reports.'
    );
  end if;

  select *
  into v_restaurant
  from public.restaurants
  where id = v_branch.restaurant_id;

  select
    count(*)::bigint,
    coalesce(
      sum(o.total_minor)
        filter (
          where o.status <>
                'cancelled'
        ),
      0
    )::bigint
  into
    v_orders_count,
    v_gross
  from public.orders o
  where o.branch_id = p_branch_id
    and o.created_at >=
        p_start_at
    and o.created_at <
        p_end_at;

  select coalesce(
    sum(p.amount_minor),
    0
  )::bigint
  into v_paid
  from public.payments p
  join public.orders o
    on o.id = p.order_id
  where o.branch_id = p_branch_id
    and p.paid_at >=
        p_start_at
    and p.paid_at <
        p_end_at
    and p.status in (
      'paid',
      'partially_refunded',
      'refunded'
    );

  select coalesce(
    sum(pr.amount_minor),
    0
  )::bigint
  into v_refunds
  from public.payment_refunds pr
  join public.payments p
    on p.id = pr.payment_id
  join public.orders o
    on o.id = p.order_id
  where o.branch_id = p_branch_id
    and pr.created_at >=
        p_start_at
    and pr.created_at <
        p_end_at
    and pr.status =
        'succeeded';

  v_net := greatest(
    0,
    v_paid - v_refunds
  );

  if v_orders_count > 0 then
    v_average := round(
      v_gross::numeric
      / v_orders_count::numeric
    )::bigint;
  else
    v_average := 0;
  end if;

  with order_buckets as (
    select
      case p_group_by
        when 'hour' then
          date_trunc(
            'hour',
            o.created_at
              at time zone
              v_restaurant.timezone
          )
        when 'day' then
          date_trunc(
            'day',
            o.created_at
              at time zone
              v_restaurant.timezone
          )
        when 'week' then
          date_trunc(
            'week',
            o.created_at
              at time zone
              v_restaurant.timezone
          )
        else
          date_trunc(
            'month',
            o.created_at
              at time zone
              v_restaurant.timezone
          )
      end as local_bucket,

      count(*)::bigint
        as orders_count,

      coalesce(
        sum(o.total_minor)
          filter (
            where o.status <>
                  'cancelled'
          ),
        0
      )::bigint
        as gross_minor

    from public.orders o
    where o.branch_id =
          p_branch_id
      and o.created_at >=
          p_start_at
      and o.created_at <
          p_end_at
    group by 1
  ),

  payment_buckets as (
    select
      case p_group_by
        when 'hour' then
          date_trunc(
            'hour',
            p.paid_at
              at time zone
              v_restaurant.timezone
          )
        when 'day' then
          date_trunc(
            'day',
            p.paid_at
              at time zone
              v_restaurant.timezone
          )
        when 'week' then
          date_trunc(
            'week',
            p.paid_at
              at time zone
              v_restaurant.timezone
          )
        else
          date_trunc(
            'month',
            p.paid_at
              at time zone
              v_restaurant.timezone
          )
      end as local_bucket,

      sum(p.amount_minor)::bigint
        as paid_minor

    from public.payments p
    join public.orders o
      on o.id = p.order_id
    where o.branch_id =
          p_branch_id
      and p.paid_at >=
          p_start_at
      and p.paid_at <
          p_end_at
      and p.status in (
        'paid',
        'partially_refunded',
        'refunded'
      )
    group by 1
  ),

  refund_buckets as (
    select
      case p_group_by
        when 'hour' then
          date_trunc(
            'hour',
            pr.created_at
              at time zone
              v_restaurant.timezone
          )
        when 'day' then
          date_trunc(
            'day',
            pr.created_at
              at time zone
              v_restaurant.timezone
          )
        when 'week' then
          date_trunc(
            'week',
            pr.created_at
              at time zone
              v_restaurant.timezone
          )
        else
          date_trunc(
            'month',
            pr.created_at
              at time zone
              v_restaurant.timezone
          )
      end as local_bucket,

      sum(pr.amount_minor)::bigint
        as refund_minor

    from public.payment_refunds pr
    join public.payments p
      on p.id = pr.payment_id
    join public.orders o
      on o.id = p.order_id
    where o.branch_id =
          p_branch_id
      and pr.created_at >=
          p_start_at
      and pr.created_at <
          p_end_at
      and pr.status =
          'succeeded'
    group by 1
  ),

  buckets as (
    select local_bucket
    from order_buckets

    union

    select local_bucket
    from payment_buckets

    union

    select local_bucket
    from refund_buckets
  )

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'bucket_start',
          (
            b.local_bucket
            at time zone
            v_restaurant.timezone
          ),
        'orders_count',
          coalesce(
            ob.orders_count,
            0
          ),
        'net_revenue_minor',
          greatest(
            0,
            coalesce(
              pb.paid_minor,
              0
            )
            -
            coalesce(
              rb.refund_minor,
              0
            )
          )
      )
      order by b.local_bucket
    ),
    '[]'::jsonb
  )
  into v_series
  from buckets b
  left join order_buckets ob
    on ob.local_bucket =
       b.local_bucket
  left join payment_buckets pb
    on pb.local_bucket =
       b.local_bucket
  left join refund_buckets rb
    on rb.local_bucket =
       b.local_bucket;

  return private.api_ok(
    jsonb_build_object(
      'summary',
      jsonb_build_object(
        'orders_count',
          v_orders_count,
        'gross_order_value_minor',
          v_gross,
        'paid_revenue_minor',
          v_paid,
        'refunds_minor',
          v_refunds,
        'net_revenue_minor',
          v_net,
        'average_order_value_minor',
          v_average
      ),
      'series',
        v_series
    )
  );
end;
$$;

revoke all
on function public.get_sales_report(
  uuid,
  timestamptz,
  timestamptz,
  text
)
from public, anon;

grant execute
on function public.get_sales_report(
  uuid,
  timestamptz,
  timestamptz,
  text
)
to authenticated, service_role;

-- ============================================================================
-- 18. RPC: invite_staff
-- ============================================================================

create or replace function public.invite_staff(
  p_contact jsonb,
  p_restaurant_id uuid,
  p_role public.staff_role,
  p_branch_ids uuid[] default array[]::uuid[]
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_caller_role public.staff_role;

  v_email text;
  v_phone text;

  v_invitation_id uuid;
  v_expires_at timestamptz;
  v_token text;
  v_token_hash text;

  v_branch_id uuid;
  v_distinct_branch_count integer;
  v_valid_branch_count integer;
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if not private.can_manage_staff(
    p_restaurant_id
  ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to invite staff.'
    );
  end if;

  v_caller_role :=
    private.restaurant_role(
      p_restaurant_id
    );

  if p_role is null then
    return private.api_error(
      'CONFLICT',
      'Staff role is required.',
      jsonb_build_object(
        'reason',
        'role_required'
      )
    );
  end if;

  if p_role = 'owner' then
    return private.api_error(
      'OWNER_ROLE_PROTECTED',
      'Owner access cannot be granted through a normal staff invitation.'
    );
  end if;

  if v_caller_role = 'manager'
     and p_role = 'manager' then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'Only an owner can invite another manager.'
    );
  end if;

  if p_contact is null
     or jsonb_typeof(p_contact)
        <> 'object' then
    return private.api_error(
      'CONFLICT',
      'Invitation contact is invalid.',
      jsonb_build_object(
        'reason',
        'invalid_contact'
      )
    );
  end if;

  v_email := lower(
    nullif(
      btrim(
        p_contact ->> 'email'
      ),
      ''
    )
  );

  v_phone :=
    nullif(
      btrim(
        p_contact ->> 'phone'
      ),
      ''
    );

  if v_email is null
     and v_phone is null then
    return private.api_error(
      'CONFLICT',
      'Email or phone is required.',
      jsonb_build_object(
        'reason',
        'contact_required'
      )
    );
  end if;

  if exists (
    select 1
    from public.restaurant_members rm
    join auth.users u
      on u.id = rm.user_id
    where rm.restaurant_id =
          p_restaurant_id
      and rm.is_active = true
      and (
        (
          v_email is not null
          and lower(u.email) =
              v_email
        )
        or
        (
          v_phone is not null
          and u.phone =
              v_phone
        )
      )
  ) then
    return private.api_error(
      'MEMBER_ALREADY_EXISTS',
      'This person is already a restaurant member.'
    );
  end if;

  select count(
    distinct x.branch_id
  )::integer
  into v_distinct_branch_count
  from unnest(
    coalesce(
      p_branch_ids,
      array[]::uuid[]
    )
  ) as x(branch_id);

  if p_role in (
    'cashier'::public.staff_role,
    'waiter'::public.staff_role,
    'kitchen'::public.staff_role
  )
  and v_distinct_branch_count = 0 then
    return private.api_error(
      'CONFLICT',
      'At least one branch assignment is required for this role.',
      jsonb_build_object(
        'reason',
        'branch_required'
      )
    );
  end if;

  select count(*)::integer
  into v_valid_branch_count
  from public.branches b
  where b.restaurant_id =
        p_restaurant_id
    and b.id = any(
      coalesce(
        p_branch_ids,
        array[]::uuid[]
      )
    );

  if v_valid_branch_count <>
     v_distinct_branch_count then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'One or more branch assignments are invalid.'
    );
  end if;

  if exists (
    select 1
    from public.staff_invitations si
    where si.restaurant_id =
          p_restaurant_id
      and si.accepted_at is null
      and si.revoked_at is null
      and si.expires_at > now()
      and (
        (
          v_email is not null
          and lower(si.email) =
              v_email
        )
        or
        (
          v_phone is not null
          and si.phone =
              v_phone
        )
      )
  ) then
    return private.api_error(
      'CONFLICT',
      'An active invitation already exists for this contact.',
      jsonb_build_object(
        'reason',
        'active_invitation_exists'
      )
    );
  end if;

  v_token :=
    gen_random_uuid()::text
    || replace(
      gen_random_uuid()::text,
      '-',
      ''
    );

  v_token_hash := encode(
    digest(
      v_token,
      'sha256'
    ),
    'hex'
  );

  v_expires_at :=
    now()
    + interval '7 days';

  insert into public.staff_invitations (
    restaurant_id,
    email,
    phone,
    role,
    token_hash,
    expires_at,
    invited_by
  )
  values (
    p_restaurant_id,
    v_email,
    v_phone,
    p_role,
    v_token_hash,
    v_expires_at,
    v_user_id
  )
  returning id
  into v_invitation_id;

  foreach v_branch_id in array
    coalesce(
      p_branch_ids,
      array[]::uuid[]
    )
  loop
    insert into public.staff_invitation_branches (
      invitation_id,
      restaurant_id,
      branch_id
    )
    values (
      v_invitation_id,
      p_restaurant_id,
      v_branch_id
    )
    on conflict do nothing;
  end loop;

  perform private.write_audit(
    p_restaurant_id,
    null,
    'staff.invited',
    'staff_invitation',
    v_invitation_id,
    jsonb_build_object(
      'role',
        p_role::text,
      'branch_ids',
        to_jsonb(
          coalesce(
            p_branch_ids,
            array[]::uuid[]
          )
        )
    )
  );

  return private.api_ok(
    jsonb_build_object(
      'invitation_id',
        v_invitation_id,
      'expires_at',
        v_expires_at,

      -- One-time token for MVP/manual delivery.
      -- A future invitation Edge Function should keep this server-side.
      'delivery_token',
        v_token
    )
  );
end;
$$;

revoke all
on function public.invite_staff(
  jsonb,
  uuid,
  public.staff_role,
  uuid[]
)
from public, anon;

grant execute
on function public.invite_staff(
  jsonb,
  uuid,
  public.staff_role,
  uuid[]
)
to authenticated, service_role;

-- ============================================================================
-- 19. RPC: accept_staff_invitation
-- ============================================================================

create or replace function public.accept_staff_invitation(
  p_token text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_hash text;
  v_invitation public.staff_invitations%rowtype;
  v_user_email text;
  v_user_phone text;
  v_contact_matches boolean := false;
  v_existing public.restaurant_members%rowtype;
  v_branch_ids uuid[];
begin
  v_user_id := (select auth.uid());

  if v_user_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if p_token is null
     or char_length(
       btrim(p_token)
     ) < 16 then
    return private.api_error(
      'INVITATION_NOT_FOUND',
      'Invitation not found.'
    );
  end if;

  v_hash := encode(
    digest(
      p_token,
      'sha256'
    ),
    'hex'
  );

  select *
  into v_invitation
  from public.staff_invitations
  where token_hash =
        v_hash
  for update;

  if not found then
    return private.api_error(
      'INVITATION_NOT_FOUND',
      'Invitation not found.'
    );
  end if;

  if v_invitation.revoked_at
     is not null then
    return private.api_error(
      'INVITATION_REVOKED',
      'This invitation has been revoked.'
    );
  end if;

  if v_invitation.accepted_at
     is not null then
    return private.api_error(
      'INVITATION_ALREADY_ACCEPTED',
      'This invitation has already been accepted.'
    );
  end if;

  if v_invitation.expires_at <=
     now() then
    return private.api_error(
      'INVITATION_EXPIRED',
      'This invitation has expired.'
    );
  end if;

  select
    lower(email),
    phone
  into
    v_user_email,
    v_user_phone
  from auth.users
  where id = v_user_id;

  v_contact_matches :=
    (
      v_invitation.email is not null
      and v_user_email is not null
      and lower(
        v_invitation.email
      ) = v_user_email
    )
    or
    (
      v_invitation.phone is not null
      and v_user_phone is not null
      and v_invitation.phone =
          v_user_phone
    );

  if not v_contact_matches then
    return private.api_error(
      'FORBIDDEN',
      'This invitation belongs to a different account.'
    );
  end if;

  select *
  into v_existing
  from public.restaurant_members
  where restaurant_id =
        v_invitation.restaurant_id
    and user_id =
        v_user_id
  for update;

  if found
     and v_existing.is_active then
    return private.api_error(
      'MEMBER_ALREADY_EXISTS',
      'You are already a member of this restaurant.'
    );
  end if;

  if found then
    update public.restaurant_members
    set
      role = v_invitation.role,
      is_active = true,
      invited_by =
        v_invitation.invited_by
    where restaurant_id =
          v_invitation.restaurant_id
      and user_id =
          v_user_id;
  else
    insert into public.restaurant_members (
      restaurant_id,
      user_id,
      role,
      is_active,
      invited_by
    )
    values (
      v_invitation.restaurant_id,
      v_user_id,
      v_invitation.role,
      true,
      v_invitation.invited_by
    );
  end if;

  -- Clear stale branch assignments before applying the invitation.
  delete from public.branch_members
  where restaurant_id =
        v_invitation.restaurant_id
    and user_id =
        v_user_id;

  select coalesce(
    array_agg(
      sib.branch_id
      order by sib.branch_id
    ),
    array[]::uuid[]
  )
  into v_branch_ids
  from public.staff_invitation_branches sib
  where sib.invitation_id =
        v_invitation.id;

  if v_invitation.role in (
    'cashier'::public.staff_role,
    'waiter'::public.staff_role,
    'kitchen'::public.staff_role
  ) then
    insert into public.branch_members (
      restaurant_id,
      branch_id,
      user_id,
      is_active
    )
    select
      v_invitation.restaurant_id,
      x.branch_id,
      v_user_id,
      true
    from unnest(
      v_branch_ids
    ) as x(branch_id);
  end if;

  update public.staff_invitations
  set accepted_at =
      now()
  where id =
        v_invitation.id;

  perform private.write_audit(
    v_invitation.restaurant_id,
    null,
    'staff.invitation_accepted',
    'user',
    v_user_id,
    jsonb_build_object(
      'invitation_id',
        v_invitation.id,
      'role',
        v_invitation.role::text,
      'branch_ids',
        to_jsonb(v_branch_ids)
    )
  );

  return private.api_ok(
    jsonb_build_object(
      'restaurant_id',
        v_invitation.restaurant_id,
      'role',
        v_invitation.role::text,
      'branch_ids',
        to_jsonb(v_branch_ids)
    )
  );
end;
$$;

revoke all
on function public.accept_staff_invitation(text)
from public, anon;

grant execute
on function public.accept_staff_invitation(text)
to authenticated, service_role;

-- ============================================================================
-- 20. RPC: update_staff_member
-- ============================================================================
--
-- Additive support RPC needed by ADMIN_SCREEN_SPEC staff management.
-- Add this contract to API_CONTRACTS.md when wiring the staff edit UI.
-- Owner role changes/transfers remain intentionally outside this generic RPC.
-- ============================================================================

create or replace function public.update_staff_member(
  p_restaurant_id uuid,
  p_user_id uuid,
  p_role public.staff_role,
  p_is_active boolean,
  p_branch_ids uuid[] default array[]::uuid[]
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid;
  v_actor_role public.staff_role;
  v_target public.restaurant_members%rowtype;
  v_branch_id uuid;
  v_distinct_branch_count integer;
  v_valid_branch_count integer;
begin
  v_actor_id := (select auth.uid());

  if v_actor_id is null then
    return private.api_error(
      'UNAUTHENTICATED',
      'Authentication is required.'
    );
  end if;

  if not private.can_manage_staff(
    p_restaurant_id
  ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'You do not have permission to manage staff.'
    );
  end if;

  v_actor_role :=
    private.restaurant_role(
      p_restaurant_id
    );

  if p_role is null then
    return private.api_error(
      'CONFLICT',
      'Staff role is required.',
      jsonb_build_object(
        'reason',
        'role_required'
      )
    );
  end if;

  select *
  into v_target
  from public.restaurant_members
  where restaurant_id =
        p_restaurant_id
    and user_id =
        p_user_id
  for update;

  if not found then
    return private.api_error(
      'NOT_FOUND',
      'Staff member not found.'
    );
  end if;

  if v_target.role = 'owner'
     or p_role = 'owner' then
    return private.api_error(
      'OWNER_ROLE_PROTECTED',
      'Owner role changes require the dedicated ownership-transfer flow.'
    );
  end if;

  if v_actor_role = 'manager'
     and (
       v_target.role = 'manager'
       or p_role = 'manager'
     ) then
    return private.api_error(
      'ROLE_PERMISSION_DENIED',
      'Only an owner can manage manager-level access.'
    );
  end if;

  select count(
    distinct x.branch_id
  )::integer
  into v_distinct_branch_count
  from unnest(
    coalesce(
      p_branch_ids,
      array[]::uuid[]
    )
  ) as x(branch_id);

  if p_is_active
     and p_role in (
       'cashier'::public.staff_role,
       'waiter'::public.staff_role,
       'kitchen'::public.staff_role
     )
     and v_distinct_branch_count = 0 then
    return private.api_error(
      'CONFLICT',
      'At least one branch assignment is required for this role.',
      jsonb_build_object(
        'reason',
        'branch_required'
      )
    );
  end if;

  select count(*)::integer
  into v_valid_branch_count
  from public.branches b
  where b.restaurant_id =
        p_restaurant_id
    and b.id = any(
      coalesce(
        p_branch_ids,
        array[]::uuid[]
      )
    );

  if v_valid_branch_count <>
     v_distinct_branch_count then
    return private.api_error(
      'BRANCH_ACCESS_DENIED',
      'One or more branch assignments are invalid.'
    );
  end if;

  update public.restaurant_members
  set
    role = p_role,
    is_active = p_is_active
  where restaurant_id =
        p_restaurant_id
    and user_id =
        p_user_id;

  delete from public.branch_members
  where restaurant_id =
        p_restaurant_id
    and user_id =
        p_user_id;

  if p_is_active
     and p_role in (
       'cashier'::public.staff_role,
       'waiter'::public.staff_role,
       'kitchen'::public.staff_role
     ) then
    foreach v_branch_id in array
      coalesce(
        p_branch_ids,
        array[]::uuid[]
      )
    loop
      insert into public.branch_members (
        restaurant_id,
        branch_id,
        user_id,
        is_active
      )
      values (
        p_restaurant_id,
        v_branch_id,
        p_user_id,
        true
      )
      on conflict (
        branch_id,
        user_id
      )
      do update
      set
        is_active = true,
        restaurant_id =
          excluded.restaurant_id;
    end loop;
  end if;

  perform private.write_audit(
    p_restaurant_id,
    null,
    'staff.updated',
    'user',
    p_user_id,
    jsonb_build_object(
      'old_role',
        v_target.role::text,
      'new_role',
        p_role::text,
      'is_active',
        p_is_active,
      'branch_ids',
        to_jsonb(
          coalesce(
            p_branch_ids,
            array[]::uuid[]
          )
        )
    )
  );

  return private.api_ok(
    jsonb_build_object(
      'restaurant_id',
        p_restaurant_id,
      'user_id',
        p_user_id,
      'role',
        p_role::text,
      'is_active',
        p_is_active,
      'branch_ids',
        to_jsonb(
          case
            when p_role in (
              'cashier'::public.staff_role,
              'waiter'::public.staff_role,
              'kitchen'::public.staff_role
            )
             and p_is_active
              then coalesce(
                p_branch_ids,
                array[]::uuid[]
              )
            else array[]::uuid[]
          end
        )
    )
  );
end;
$$;

revoke all
on function public.update_staff_member(
  uuid,
  uuid,
  public.staff_role,
  boolean,
  uuid[]
)
from public, anon;

grant execute
on function public.update_staff_member(
  uuid,
  uuid,
  public.staff_role,
  boolean,
  uuid[]
)
to authenticated, service_role;

-- ============================================================================
-- 21. FUNCTION OWNERSHIP / EXECUTION NOTES
-- ============================================================================
--
-- Supabase migrations normally create these functions under a privileged DB
-- owner. SECURITY DEFINER therefore bypasses table RLS inside the function.
-- That is intentional ONLY because each function validates auth.uid(),
-- membership, branch access, role and domain rules itself.
--
-- Do not grant EXECUTE on these functions to anon unless the public product
-- intentionally moves away from anonymous Supabase Auth.
--
-- ============================================================================
-- 22. IMPORTANT PAYMENT EDGE-FUNCTION BOUNDARY
-- ============================================================================
--
-- This SQL intentionally does NOT expose RPCs that let Flutter mark online
-- payment paid.
--
-- Required server flow:
--
--   create-payment Edge Function
--     -> authenticate caller
--     -> load orders.total_minor server-side
--     -> create provider payment session
--     -> insert/update public.payments using trusted server credentials
--
--   payment-webhook Edge Function
--     -> verify raw provider signature
--     -> enforce provider event idempotency
--     -> verify amount/currency/provider IDs
--     -> mark payment paid/failed
--     -> if awaiting_payment and paid:
--          update order -> placed
--          set placed_at
--          append order_status_history
--
--   refund-payment Edge Function
--     -> verify merchant permission
--     -> call provider
--     -> insert payment_refunds
--     -> update payment refund status
--     -> write audit log
--
-- ============================================================================
-- 23. REQUIRED RPC TESTS BEFORE PRODUCTION
-- ============================================================================
--
-- resolve_qr
--   [ ] valid token
--   [ ] malformed/not found
--   [ ] inactive table
--   [ ] inactive branch
--   [ ] inactive restaurant
--
-- get_public_menu
--   [ ] inactive records omitted
--   [ ] sold-out state included
--   [ ] modifiers nested correctly
--   [ ] no private/admin fields
--
-- create_order
--   [ ] dine-in
--   [ ] takeaway
--   [ ] delivery only when enabled
--   [ ] wrong table branch
--   [ ] product wrong branch
--   [ ] inactive/sold-out product
--   [ ] modifier not assigned
--   [ ] modifier unavailable
--   [ ] missing required group
--   [ ] min/max selections
--   [ ] price authoritative
--   [ ] tax inclusive
--   [ ] tax exclusive
--   [ ] service charge
--   [ ] coupon fixed
--   [ ] coupon percentage
--   [ ] coupon max discount
--   [ ] coupon usage limits
--   [ ] minimum order
--   [ ] branch pause
--   [ ] opening hours
--   [ ] temporary closure
--   [ ] duplicate idempotency retry
--   [ ] concurrent duplicate retry
--
-- get_order_details
--   [ ] customer own
--   [ ] other customer blocked
--   [ ] branch staff
--   [ ] cross-tenant blocked
--   [ ] kitchen customer PII hidden in RPC payload
--
-- change_order_status
--   [ ] every legal transition
--   [ ] every illegal reverse transition
--   [ ] role matrix
--   [ ] cross-branch denied
--   [ ] duplicate tap idempotent
--
-- cancel_order
--   [ ] role matrix
--   [ ] refund_required calculation
--   [ ] completed blocked
--
-- confirm_cash_payment
--   [ ] create cash payment
--   [ ] retry already-paid cash
--   [ ] online paid prevents double collection
--   [ ] online pending conflict
--   [ ] awaiting_payment -> placed
--
-- rotate_table_qr
--   [ ] owner/manager
--   [ ] unauthorized role denied
--   [ ] old token no longer resolves
--
-- reports
--   [ ] branch isolation
--   [ ] timezone buckets
--   [ ] refunds
--   [ ] cancelled orders
--
-- staff
--   [ ] owner invite
--   [ ] manager restrictions
--   [ ] token hash
--   [ ] contact ownership check
--   [ ] expiration
--   [ ] branch assignments
--   [ ] owner protection
--
-- ============================================================================
-- 24. FINAL TRUST RULE
-- ============================================================================
--
-- A critical business mutation must never be considered implemented if Flutter
-- can bypass the trusted RPC / Edge Function and directly write the same
-- authoritative state.
-- ============================================================================

commit;
