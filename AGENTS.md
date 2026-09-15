# AGENTS.md
## QR Restaurant Ordering Platform
### Master AI/CLI Implementation Instructions
### Applies to Codex CLI, Cursor Agents, Gemini CLI, Claude Code, Copilot Agents, and Human Contributors

> This file is the **master implementation instruction contract** for this repository.
>
> Any AI coding agent working in this repository must read this file **before making changes**.
>
> The project contains two Flutter applications backed by Supabase:
>
> ```text
> Customer App
> Admin / Merchant App
> Shared Packages
> Supabase Backend
> ```
>
> Primary stack:
>
> ```text
> Flutter
> Dart
> GetX
> MVC + Repository layer
> Supabase Auth
> PostgreSQL
> RLS
> RPC
> Realtime
> Storage
> Edge Functions
> ```
>
> Core product flow:
>
> ```text
> Restaurant configures menu + tables
> → QR is generated
> → customer scans QR
> → browses menu
> → configures products/modifiers
> → adds to cart
> → checks out
> → backend validates and creates order
> → payment is verified server-side
> → merchant receives order in realtime
> → kitchen processes order
> → customer tracks status
> → order completes
> ```

---

# 1. Mandatory First Step

Before writing or modifying code:

1. Read this file completely.
2. Inspect the repository structure.
3. Read all authoritative project specification files listed below.
4. Identify the current implementation phase.
5. Check existing code before creating new abstractions.
6. Do not duplicate a component, model, repository, route, SQL object, or design token that already exists.
7. Run existing tests/analyzers before large changes when practical.

Do not begin by generating a large amount of code without understanding the repository.

---

# 2. Authoritative Specification Files

The following files define the product.

Read them before implementation:

```text
QR_Restaurant_Order_Project_Blueprint.md
Supabase_Backend_Specification_QR_Restaurant_Project.md
CUSTOMER_APP_FLOW.md
ADMIN_APP_FLOW.md
MVP_TASK_LIST.md
APP_DESIGN_SYSTEM_AND_UI_SPEC.md
CUSTOMER_SCREEN_SPEC.md
ADMIN_SCREEN_SPEC.md
DATABASE_SCHEMA.sql
API_CONTRACTS.md
DATA_MODELS.md
```

If these files live under `/docs`, use their `/docs/...` paths.

---

# 3. Specification Precedence

If two documents appear to conflict, use this order:

```text
1. AGENTS.md
2. DATABASE_SCHEMA.sql
3. API_CONTRACTS.md
4. DATA_MODELS.md
5. CUSTOMER_SCREEN_SPEC.md / ADMIN_SCREEN_SPEC.md
6. APP_DESIGN_SYSTEM_AND_UI_SPEC.md
7. CUSTOMER_APP_FLOW.md / ADMIN_APP_FLOW.md
8. Supabase_Backend_Specification_QR_Restaurant_Project.md
9. MVP_TASK_LIST.md
10. QR_Restaurant_Order_Project_Blueprint.md
```

However:

- Security must never be weakened merely to satisfy a UI document.
- Existing executable migrations that are already deployed may require backward-compatible changes instead of destructive replacement.
- If a material contradiction remains, document it in the implementation notes and choose the safer interpretation.

Do not silently invent a third behavior.

---

# 4. Current Specification Readiness

The repository specifications are sufficient to begin implementation of:

```text
project structure
Flutter apps
shared packages
GetX routing/bindings
design system
shared models
DTOs
repository interfaces
customer screens
admin screens
local cart
local recovery state
DATABASE_SCHEMA.sql
simple RLS-safe CRUD surfaces
tests
staging scaffolding
```

The following production-critical implementation files are still expected if they are not already present:

```text
RLS_POLICIES.sql
RPC_FUNCTIONS.sql
STORAGE_POLICIES.sql
REALTIME_SETUP.sql
EDGE_FUNCTIONS_SPEC.md or actual Edge Function code
TEST_PLAN.md
ENVIRONMENT_AND_DEPLOYMENT.md
```

If these files are absent, follow the safety rules below.

---

# 5. Missing-Spec Safety Rule

Do **not** invent final production security or payment behavior when an authoritative executable contract is missing.

If `RLS_POLICIES.sql` is absent:

```text
- keep RLS enabled
- do not add permissive "allow all authenticated" policies
- do not disable RLS to make development easier
- do not use service-role credentials in Flutter
- continue implementing non-security-blocked code
- leave clear TODO/blocker notes for security-sensitive integration
```

If `RPC_FUNCTIONS.sql` is absent:

```text
- implement repository interfaces and typed request/response models
- do not replace critical RPCs with unsafe direct table writes
- do not directly update order/payment authority fields from Flutter
- safe stubs/fakes may be used only in tests or explicit development mock layers
- never silently ship a mock as production logic
```

If payment Edge Functions are absent:

```text
- implement payment interfaces and UI states
- never mark payment as paid from Flutter
- never place provider secret keys in Flutter
- keep server payment integration behind repository/service boundaries
```

The agent should continue with all non-blocked implementation work rather than stopping the entire project.

---

# 6. Repository Target Structure

Preferred monorepo:

```text
restaurant_system/
├── AGENTS.md
├── GEMINI.md
├── CLAUDE.md
│
├── docs/
│   ├── QR_Restaurant_Order_Project_Blueprint.md
│   ├── Supabase_Backend_Specification_QR_Restaurant_Project.md
│   ├── CUSTOMER_APP_FLOW.md
│   ├── ADMIN_APP_FLOW.md
│   ├── MVP_TASK_LIST.md
│   ├── APP_DESIGN_SYSTEM_AND_UI_SPEC.md
│   ├── CUSTOMER_SCREEN_SPEC.md
│   ├── ADMIN_SCREEN_SPEC.md
│   ├── API_CONTRACTS.md
│   └── DATA_MODELS.md
│
├── apps/
│   ├── customer_app/
│   └── merchant_app/
│
├── packages/
│   ├── app_core/
│   ├── app_models/
│   └── app_widgets/
│
└── supabase/
    ├── migrations/
    ├── functions/
    └── seed.sql
```

If the repository already uses a different sensible structure, adapt rather than performing a destructive restructure without need.

---

# 7. Architecture Contract

Mandatory application flow:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Supabase / Backend
```

Long-lived application services:

```text
GetxService
```

Feature/screen state:

```text
GetxController
```

Do not:

```text
call Supabase directly from Views
put SQL in Flutter
put payment secrets in Flutter
create one giant global controller
put business authorization in UI only
```

---

# 8. Flutter Application Boundaries

## Customer App

Owns:

```text
anonymous/customer auth UX
QR/deep links
restaurant/table context
menu browsing
product configuration
cart
checkout
payment UI
order tracking
history/profile
```

## Merchant App

Owns:

```text
merchant auth
restaurant/branch context
dashboard
live orders
KDS
menu CRUD
tables/QR
staff
payments
reports
settings
```

## Shared Packages

Use only when behavior/model is genuinely shared.

Do not over-generalize prematurely.

---

# 9. Shared Model Rules

Follow `DATA_MODELS.md`.

Mandatory:

```text
backend JSON = snake_case
Dart fields = camelCase
money = int minor units
timestamps = DateTime
UUID = String
collections = non-null List where practical
enums = explicit mapping
```

Never use:

```dart
double price;
double total;
```

Use:

```dart
int priceMinor;
int totalMinor;
```

---

# 10. API Rules

Follow `API_CONTRACTS.md`.

Do not invent:

```text
RPC names
RPC parameter names
JSON field names
enum values
error codes
payment authority rules
idempotency behavior
```

If an API is not defined, create a repository abstraction and mark the backend integration as blocked rather than inventing a conflicting contract.

---

# 11. Backend Trust Boundary

Flutter is untrusted.

Server must be authoritative for:

```text
tenant access
branch access
role permission
product price
modifier price
tax
service charge
discount
delivery fee
order total
order state
payment state
refund state
coupon validity
```

A modified Flutter client must not be able to bypass these rules.

---

# 12. Supabase Client Key Rule

Flutter may contain only client-safe configuration such as:

```text
Supabase URL
Supabase publishable/client key
public payment key when provider SDK requires it
```

Never include:

```text
Supabase service-role / secret key
gateway secret key
webhook secret
FCM server credential
private signing key
```

---

# 13. Row Level Security Rule

RLS is mandatory on exposed business tables.

Never:

```text
disable RLS for convenience
add broad USING (true) merchant policies
trust restaurant_id passed by the client without membership validation
```

Cross-tenant access is a release blocker.

---

# 14. Critical RPC Rule

The following operations must remain trusted backend operations:

```text
resolve_qr
get_public_menu
create_order
change_order_status
cancel_order
confirm_cash_payment
rotate_table_qr
create_restaurant
dashboard/report aggregation
```

When corresponding SQL exists, call it exactly according to `API_CONTRACTS.md`.

Do not replace these with direct client writes.

---

# 15. Order Creation Rule

Client sends intent:

```text
product IDs
modifier IDs
quantities
notes
branch/table context
idempotency key
```

Server determines:

```text
price
tax
service charge
discount
total
initial order state
```

Never trust cart preview values.

---

# 16. Payment Rule

Correct architecture:

```text
Flutter
→ create-payment Edge Function
→ provider checkout
→ provider webhook
→ server verifies
→ payment state changes
→ order state changes
→ Realtime updates apps
```

Flutter payment callback is not payment truth.

---

# 17. Realtime Rule

Realtime is synchronization, not durable truth.

On reconnect:

```text
refetch
then resubscribe/reconcile
```

Do not assume missed events will magically rebuild state.

---

# 18. Customer App Design Rule

Follow:

```text
APP_DESIGN_SYSTEM_AND_UI_SPEC.md
CUSTOMER_SCREEN_SPEC.md
```

Customer experience:

```text
Scan
→ Choose
→ Order
→ Track
```

Keep it:

```text
food-first
simple
low-friction
mobile-first
```

---

# 19. Merchant App Design Rule

Follow:

```text
APP_DESIGN_SYSTEM_AND_UI_SPEC.md
ADMIN_SCREEN_SPEC.md
```

Merchant experience:

```text
See
→ Act
→ Confirm
→ Track
```

KDS must prioritize:

```text
speed
large touch targets
distance readability
clear order age
clear modifiers/notes
```

---

# 20. Design Token Rule

Do not invent arbitrary styling.

No repeated arbitrary values like:

```dart
EdgeInsets.all(13)
BorderRadius.circular(17)
Color(0xFF123456)
```

unless required by a documented exception.

Use centralized:

```text
AppColors
AppSpacing
AppRadius
AppTextStyles
AppBreakpoints
```

---

# 21. Reusable UI Rule

Before creating a component, check existing shared/feature components.

Do not create multiple nearly identical:

```text
primary buttons
status chips
money rows
empty states
search fields
metric cards
```

---

# 22. Responsive Rule

Every merchant screen must work on:

```text
mobile
tablet
desktop/web
```

Customer screens must be mobile-first and not break on wider layouts.

Breakpoints follow the design specification.

---

# 23. Accessibility Rule

Interactive controls:

```text
minimum ~44×44 touch target
semantic labels
tooltips for icon-only web/desktop controls
text status + color
```

Do not communicate critical state with color alone.

---

# 24. Screen State Rule

Async screens must implement applicable:

```text
initial
loading
success
empty
error
offline/reconnecting
submitting
```

Do not implement only the happy path.

---

# 25. Error Boundary Rule

Views must not show raw:

```text
PostgrestException
AuthException
FunctionException
SQL error
stack trace
```

Repositories map transport/backend errors to typed application/domain errors.

Controllers decide user-facing behavior.

---

# 26. Local State Rule

Local storage may contain:

```text
cart
safe restaurant context
merchant context
pending checkout recovery
pending payment recovery
preferences
```

Do not manually store:

```text
Supabase access token
service-role key
gateway secret
card information
OTP
```

---

# 27. Cart Rule

Cart is local until checkout.

Cart preview pricing is not authoritative.

When restaurant/branch changes:

```text
validate
warn
clear incompatible cart when confirmed
```

---

# 28. Historical Order Rule

Historical order display must use order snapshots:

```text
order_items
order_item_modifiers
```

Do not reconstruct historical receipts from current menu prices/names.

---

# 29. Admin Context Rule

`MerchantContextService` is UI state only.

Never use it as proof of authorization.

The backend/RLS must validate every tenant-sensitive action.

---

# 30. Role Rule

MVP roles:

```text
owner
manager
cashier
waiter
kitchen
```

UI may hide unavailable features.

Backend remains authority.

---

# 31. Naming Rule

Use clear names:

```text
ProductCard
OrderStatusTimeline
PaymentRepository
MerchantContextService
```

Avoid:

```text
Utils2
HelperThing
DataManager
CustomWidget1
```

---

# 32. File Size Rule

If a generated implementation file grows beyond roughly:

```text
300–500 lines
```

consider extracting meaningful widgets/helpers.

Do not split into dozens of meaningless micro-files.

---

# 33. Comment Rule

Comments should explain:

```text
why
security assumption
non-obvious business rule
workaround
```

Do not narrate obvious code.

---

# 34. Dependency Rule

Before adding a Flutter/Dart dependency:

1. verify it is necessary
2. prefer existing dependency if capable
3. avoid overlapping packages
4. keep shared model package Flutter-independent where possible
5. document why dependency was added

Do not add a package only to save a few lines of simple code.

---

# 35. Generated Code Rule

If using:

```text
freezed
json_serializable
build_runner
```

use consistently.

If project is already manual serialization, do not partially switch without an intentional decision.

---

# 36. Implementation Phase Order

Follow this order unless repository state proves a later phase is already complete.

## Phase 0 — Repository Audit

```text
- inspect tree
- identify existing Flutter apps
- identify existing Supabase files
- inventory docs
- run baseline analyzer/tests
- note blockers
```

## Phase 1 — Monorepo / Project Foundation

```text
- customer app scaffold
- merchant app scaffold
- shared package scaffold
- environment configuration
- GetX routing
- initial bindings
- base error architecture
```

## Phase 2 — Shared Design System

```text
- colors
- spacing
- radius
- text styles
- breakpoints
- shared buttons
- fields
- cards
- states
- semantic status chips
```

## Phase 3 — Shared Models

Implement `DATA_MODELS.md`.

```text
- enums
- DTOs
- request/response objects
- local models
- tests
```

## Phase 4 — Supabase Baseline Schema

```text
- convert DATABASE_SCHEMA.sql into migration
- ensure local reset works
- keep fail-closed RLS
```

Do not open client access without RLS policy source of truth.

## Phase 5 — Auth + Context Shells

Customer:

```text
- anonymous session
- startup
- restaurant context
```

Merchant:

```text
- login
- membership context
- restaurant select
- branch select
```

## Phase 6 — Merchant Menu + Tables

```text
- categories
- products
- modifiers
- image flow
- tables
- QR display
```

Only use direct CRUD where RLS/security implementation is present and safe.

## Phase 7 — Customer QR + Menu

```text
- scan
- deep link
- resolve repository
- menu UI
- product detail
```

If RPC not yet implemented, keep integration explicitly blocked behind repository contract.

## Phase 8 — Cart + Checkout UI

```text
- local cart
- persistence
- checkout form
- idempotency state
```

Do not replace missing `create_order` RPC with unsafe direct inserts.

## Phase 9 — Orders + Realtime + KDS

```text
- admin live orders
- customer tracking
- KDS
- reconnect/refetch
```

Order status mutation requires trusted RPC.

## Phase 10 — Payments

```text
- payment UI
- payment repository
- pending/recovery states
- Edge Function integration
- webhook-verified truth
```

## Phase 11 — Staff + Reports + Settings

```text
- staff
- payments view
- dashboard
- reports
- settings
```

## Phase 12 — Hardening

```text
- RLS tests
- cross-tenant tests
- integration tests
- low-network tests
- crash/error handling
- staging
```

---

# 37. P0 Customer Build Order

Follow `CUSTOMER_SCREEN_SPEC.md`:

```text
1. SplashPage
2. QrScannerPage
3. MenuPage
4. ProductDetailPage
5. CartPage
6. CheckoutPage
7. OrderTrackingPage
```

Then P1 customer screens.

---

# 38. P0 Admin Build Order

Follow `ADMIN_SCREEN_SPEC.md`:

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

---

# 39. Verification Commands

Use repository-specific commands if scripts already exist.

Common Flutter:

```bash
flutter pub get
flutter analyze
flutter test
```

For each app, run from its directory or via workspace tooling.

Format:

```bash
dart format .
```

If code generation is configured:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Supabase local:

```bash
supabase start
supabase db reset
```

Do not claim verification passed unless the command actually ran successfully.

---

# 40. Test Expectations

At minimum for new business features:

```text
controller/unit tests
model serialization tests
widget tests for critical states
```

Critical flows additionally require integration/security tests:

```text
QR
create order
order status
payment
RLS tenant isolation
Realtime
```

---

# 41. Definition of Done for a Feature

A feature is not complete because its UI renders.

It is complete only when applicable:

```text
[ ] architecture follows repository boundary
[ ] typed models exist
[ ] loading state works
[ ] empty state works
[ ] error state works
[ ] offline/reconnect behavior works
[ ] responsive UI works
[ ] backend validation exists
[ ] RLS protects data
[ ] tests pass
[ ] analyzer passes
```

---

# 42. No-Fake-Completion Rule

Do not:

```text
replace a backend call with hardcoded success
mark TODO code as complete
silently swallow exceptions
return fake payment success
disable security to pass tests
```

Mocks/fakes are allowed only in test/dev abstractions and must be clearly identified.

---

# 43. No-Destructive-Migration Rule

If database already contains migrations or production state:

```text
do not replace everything with DATABASE_SCHEMA.sql
```

Instead:

```text
diff current schema
create forward migration
preserve data
```

For a new empty project, baseline migration may be created from `DATABASE_SCHEMA.sql`.

---

# 44. Database Naming Rule

Keep SQL:

```text
snake_case
```

Keep Dart:

```text
camelCase
```

Do not rename schema fields merely for stylistic preference.

---

# 45. Migration Rule

All database changes must be represented by migrations.

Do not depend on manually clicking dashboard schema changes without migration representation.

---

# 46. Seed Rule

Seed data must be clearly non-production/demo data.

Never seed:

```text
real customer data
real payment credentials
real secrets
```

---

# 47. Storage Rule

Follow documented bucket/path rules.

When replacing image:

```text
upload new
→ save DB path
→ delete old
```

Avoid delete-first.

---

# 48. Deep Link Rule

Canonical QR:

```text
https://order.example.com/q/<uuid-token>
```

Do not trust URL query parameters for price/branch/table authority.

---

# 49. Idempotency Rule

Operations requiring stable idempotency:

```text
create order
create payment
refund
webhooks
```

After timeout:

```text
reuse the same key
```

Never generate a new key until outcome is known.

---

# 50. Timeout Rule

Timeout does not mean a critical write failed.

Recover:

```text
create order → retry same idempotency key
payment → query server state
refund → query existing idempotent refund
```

---

# 51. Concurrency Rule

Assume multiple merchant devices.

Order transitions must be atomically validated server-side.

If conflict occurs:

```text
show conflict
refetch
reconcile UI
```

---

# 52. Git / Change Discipline

Prefer small coherent changes.

Before finishing a phase:

```text
format
analyze
test
review changed files
```

Do not rewrite unrelated files without need.

---

# 53. Existing Code Preservation Rule

Before replacing existing code:

1. understand its purpose
2. check whether it already implements the spec
3. preserve useful behavior/tests
4. refactor incrementally where possible

Do not regenerate the entire app from scratch when a working implementation exists.

---

# 54. Documentation Update Rule

When a deliberate contract change is required:

```text
update specification first
then implementation
then tests
```

Do not let implementation silently drift from docs.

---

# 55. MVP Checklist Rule

Use `MVP_TASK_LIST.md` as progress tracker.

Only mark an item complete if it is actually implemented and verified.

If the agent edits the checklist, preserve history/meaning and do not mark blocked security tasks complete.

---

# 56. Agent Progress Reporting

During long implementation tasks, report:

```text
phase completed
files changed
tests run
known blockers
next safe phase
```

Do not report vague "everything is done" statements.

---

# 57. Blocker Handling

If a critical missing spec blocks only part of the project:

```text
- document blocker
- implement interfaces/models/UI/tests around it
- continue unrelated work
```

Do not stall all progress.

If proceeding would require weakening security, stop that subtask.

---

# 58. Production Readiness Blockers

Do not declare production-ready until these exist and pass:

```text
RLS policies
cross-tenant security tests
trusted order RPCs
trusted payment flow
webhook verification
payment recovery
Realtime reconnect
staging validation
backups/monitoring plan
```

---

# 59. Recommended Missing Files to Create Next

Highest priority after this master agent file:

```text
1. RLS_POLICIES.sql
2. RPC_FUNCTIONS.sql
3. STORAGE_POLICIES.sql
4. REALTIME_SETUP.sql
5. EDGE_FUNCTIONS_SPEC.md
6. TEST_PLAN.md
7. ENVIRONMENT_AND_DEPLOYMENT.md
8. IMPLEMENTATION_ORDER.md
```

`IMPLEMENTATION_ORDER.md` is optional if this file's phase order remains authoritative.

---

# 60. Final Agent Instruction

The project should be implemented as a production-oriented multi-tenant system.

Optimize for:

```text
correctness
security
maintainability
clear architecture
predictable UX
testability
```

not merely:

```text
maximum code generation speed
```

The fundamental rules are:

```text
Flutter expresses user intent.
Repositories isolate backend access.
Supabase authorizes tenant access.
Trusted backend logic calculates business truth.
Realtime synchronizes state.
Payment webhooks determine payment truth.
```

When uncertain, choose the implementation that preserves those boundaries.
