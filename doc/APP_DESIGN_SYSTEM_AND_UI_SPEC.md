# APP_DESIGN_SYSTEM_AND_UI_SPEC.md
## Customer App + Admin/Merchant App
### Flutter + GetX + MVC + Supabase
### AI Implementation Specification for Codex, Cursor, Claude Code, Copilot, etc.

> This document is the **authoritative visual and UX implementation specification** for both Flutter applications in the QR Restaurant Ordering Platform.
>
> It is written so an AI coding tool can implement the apps consistently without inventing its own visual language.
>
> Use this file together with:
>
> - `CUSTOMER_APP_FLOW.md`
> - `ADMIN_APP_FLOW.md`
> - `MVP_TASK_LIST.md`
> - `Supabase_Backend_Specification_QR_Restaurant_Project.md`
>
> This document defines:
>
> - visual style
> - design tokens
> - typography
> - spacing
> - radii
> - shadows
> - component rules
> - form rules
> - navigation
> - screen hierarchy
> - responsive layouts
> - loading/empty/error states
> - customer app screen design
> - admin app screen design
> - KDS design
> - accessibility
> - animations
> - implementation constraints
> - naming conventions
> - AI coding instructions

---

# 1. Product Design Direction

The product should feel:

```text
Modern
Clean
Fast
Professional
Calm
Trustworthy
Operational
Mobile-first
Restaurant-focused
```

The customer app should feel:

```text
friendly
simple
visual
low-friction
food-first
```

The admin app should feel:

```text
efficient
information-dense
clear
operational
fast under pressure
```

Do **not** make either app look:

```text
overly playful
neon
gaming-inspired
crypto-like
banking-heavy
skeuomorphic
cluttered
gradient-heavy
glassmorphism-heavy
```

---

# 2. Visual Philosophy

Use:

```text
white / neutral surfaces
strong text hierarchy
one primary accent color
subtle borders
soft shadows
large touch targets
clear status chips
clear cards
minimal decoration
```

Avoid:

```text
heavy gradients
excessive shadows
excessive rounded pills
too many colors
tiny text
dense unreadable tables
decorative icons without meaning
```

---

# 3. Design System Architecture

Flutter design structure:

```text
lib/
├── app/
│   └── theme/
│       ├── app_colors.dart
│       ├── app_spacing.dart
│       ├── app_radius.dart
│       ├── app_text_styles.dart
│       ├── app_shadows.dart
│       ├── app_theme.dart
│       └── app_breakpoints.dart
│
├── core/
│   └── widgets/
│       ├── buttons/
│       ├── cards/
│       ├── fields/
│       ├── feedback/
│       ├── navigation/
│       ├── status/
│       └── layout/
```

AI tools must **reuse design tokens** and must not create arbitrary values repeatedly.

---

# 4. Color System

Do not hardcode colors inside feature widgets.

Create centralized color constants.

Recommended palette:

```text
Primary:
#1F7A4C

Primary Dark:
#155D39

Primary Light:
#EAF6EF

Accent:
#F59E0B

Background:
#F7F8FA

Surface:
#FFFFFF

Surface Secondary:
#F1F3F5

Border:
#E4E7EC

Text Primary:
#111827

Text Secondary:
#667085

Text Tertiary:
#98A2B3

Disabled:
#D0D5DD

Success:
#16A34A

Warning:
#D97706

Danger:
#DC2626

Info:
#2563EB
```

---

# 5. Color Usage Rules

## Primary

Use for:

```text
main CTA
selected nav
selected category
active focus
important success action
```

Do not use as large full-screen background except splash/branding where needed.

## Accent

Use sparingly for:

```text
highlight
offer
warning-like emphasis
```

## Success

Use for:

```text
paid
completed
ready
available
```

## Warning

Use for:

```text
pending
preparing
low stock later
```

## Danger

Use for:

```text
cancel
delete
refund warning
error
```

## Info

Use for:

```text
neutral operational status
links
system information
```

---

# 6. Dark Mode

MVP:

```text
Light mode only
```

Do not implement dark mode unless explicitly requested later.

Keep architecture flexible so dark mode can be added later.

---

# 7. Typography

Use system-safe modern sans serif.

Recommended:

```text
Inter
```

If font bundling is not desired:

```text
use Flutter default system font
```

Typography scale:

```text
Display:
32 / 40 / 700

H1:
28 / 36 / 700

H2:
24 / 32 / 700

H3:
20 / 28 / 600

Title:
18 / 26 / 600

Body Large:
16 / 24 / 400

Body:
14 / 22 / 400

Body Medium:
14 / 22 / 500

Caption:
12 / 18 / 400

Caption Medium:
12 / 18 / 500

Button:
14 / 20 / 600
```

---

# 8. Typography Rules

Use:

```text
H1 → page title
H2 → major section
H3 → card section
Title → product/card title
Body → normal text
Caption → metadata
```

Do not use:

```text
ALL CAPS
```

except very short KDS status labels.

---

# 9. Spacing System

Use an 8-point system.

Tokens:

```text
xs  = 4
sm  = 8
md  = 12
lg  = 16
xl  = 24
2xl = 32
3xl = 40
4xl = 48
```

Primary page padding:

```text
mobile: 16
tablet: 24
desktop: 32
```

---

# 10. Radius System

```text
Small:
8

Medium:
12

Large:
16

XL:
20

Pill:
999
```

Use:

```text
buttons → 12
cards → 16
fields → 12
bottom sheets → 20 top corners
status chips → pill
```

Do not over-round every element.

---

# 11. Border System

Default:

```text
1px
#E4E7EC
```

Focused field:

```text
1.5px
Primary
```

Error field:

```text
1.5px
Danger
```

---

# 12. Shadow System

Use subtle shadows only.

Card shadow:

```text
blur: 12
offset: 0, 4
opacity: 0.06
```

Floating CTA/cart bar:

```text
blur: 20
offset: 0, 8
opacity: 0.10
```

Avoid heavy shadows.

---

# 13. Breakpoints

Create:

```dart
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}
```

Interpretation:

```text
< 600         mobile
600–1023      tablet
1024–1439     desktop
1440+         large desktop
```

---

# 14. Responsive Layout Rules

## Customer App

Mobile first.

Tablet/web:

```text
center content
max width 900–1100
larger product grid
persistent cart summary possible
```

## Admin App

Mobile:

```text
bottom navigation
single-column screens
```

Tablet:

```text
navigation rail
two-column layouts
KDS columns
```

Desktop:

```text
sidebar
content area
optional detail panel
```

---

# 15. Safe Widths

Customer web:

```text
max content width: 1100
```

Admin desktop:

```text
max content width: 1600
```

Forms:

```text
max width: 720
```

Auth forms:

```text
max width: 420
```

---

# 16. Iconography

Use:

```text
Material Symbols / Flutter Material Icons
```

Preferred icon style:

```text
outlined
```

Use filled icons only for selected navigation states.

Do not mix icon families.

---

# 17. Button System

Create reusable:

```text
AppPrimaryButton
AppSecondaryButton
AppTextButton
AppDangerButton
AppIconButton
```

---

# 18. Primary Button

Style:

```text
height: 48
radius: 12
background: primary
text: white
font: 14/600
horizontal padding: 20
```

States:

```text
default
pressed
loading
disabled
```

Loading:

```text
spinner + preserve button width
```

---

# 19. Secondary Button

Style:

```text
height: 48
background: white
border: border
text: text primary
```

Use for:

```text
cancel
secondary navigation
alternative action
```

---

# 20. Danger Button

Use only for:

```text
cancel order
refund
delete/archive critical
remove staff
```

Style:

```text
danger background
white text
```

or outline danger for less severe actions.

---

# 21. Icon Button

Minimum touch area:

```text
44 × 44
```

Do not use 24×24 icons as the full interactive target.

---

# 22. Form Fields

Create reusable:

```text
AppTextField
AppPhoneField
AppMoneyField
AppSearchField
AppDropdownField
AppMultilineField
```

Default:

```text
height: 48
radius: 12
border
label above field
helper/error below
```

---

# 23. Field States

Support:

```text
default
focused
filled
disabled
error
loading if async
```

---

# 24. Labels

Use label above field.

Example:

```text
Product name
[ Farmhouse Pizza        ]
```

Do not rely only on placeholder as label.

---

# 25. Validation

Error appears:

```text
below field
danger color
12–13px text
```

Do not use toast only for form errors.

---

# 26. Search Field

Style:

```text
search icon
placeholder
clear icon
surface secondary background
radius 12
```

Use on:

```text
customer menu
admin product list
orders
staff
```

---

# 27. Cards

Create:

```text
AppCard
SelectableCard
MetricCard
StatusCard
```

Default card:

```text
surface white
radius 16
border optional
shadow subtle
padding 16
```

---

# 28. Status Chips

Create a reusable `StatusChip`.

Possible statuses:

```text
Placed
Accepted
Preparing
Ready
Served
Completed
Cancelled
Pending
Paid
Failed
Refunded
Sold Out
Active
Inactive
```

Each chip:

```text
background = light tinted color
text = darker semantic color
height = 28–32
horizontal padding = 10–12
```

---

# 29. Empty States

Structure:

```text
icon/illustration optional
title
short explanation
primary action if useful
```

Example:

```text
No orders yet

New customer orders will appear here.

[Refresh]
```

---

# 30. Error States

Prefer inline page/card errors.

Structure:

```text
error icon
title
short message
retry button
```

Avoid exposing:

```text
PostgrestException
SQL
stack trace
```

---

# 31. Loading States

Use:

```text
skeletons
inline spinners
button loading
```

Avoid:

```text
full-screen spinner
```

unless startup/auth absolutely requires it.

---

# 32. Snackbar Rules

Use snackbar for:

```text
saved
copied
quick confirmation
nonblocking failure
```

Do not use snackbar for:

```text
critical confirmation
payment failure
destructive action
```

---

# 33. Dialog Rules

Use dialog for:

```text
destructive confirmation
restaurant switch with cart
logout confirmation optional
refund confirmation
QR rotation
staff removal
```

---

# 34. Bottom Sheet Rules

Use bottom sheet for:

```text
filters
sort
payment method
short forms
order actions
```

Mobile only.

On desktop use dialog/side panel.

---

# 35. Navigation — Customer App

Recommended bottom navigation after MVP grows:

```text
Menu
Orders
Profile
```

For QR-first MVP, `Menu` can be default.

If no restaurant context:

```text
Scan QR
Orders
Profile
```

---

# 36. Navigation — Admin App

Owner/Manager mobile:

```text
Dashboard
Orders
Menu
More
```

Cashier:

```text
Orders
Payments
More
```

Waiter:

```text
Orders
Tables
More
```

Kitchen:

```text
KDS
```

Tablet/Desktop:

```text
NavigationRail / Sidebar
```

---

# 37. Customer App — Splash Screen

Design:

```text
centered logo
app name
subtle loader if needed
```

Background:

```text
white
```

Optional:

```text
primary color logo mark
```

Do not show long marketing copy.

---

# 38. Customer App — Scan QR Screen

Layout:

```text
App bar:
"Scan Restaurant QR"

Body:
large scanner viewport
short helper text

Bottom:
manual link option optional
```

Scanner viewport:

```text
rounded 20
dark camera area
clear corner brackets
```

Helper:

```text
Point your camera at the QR code on your table.
```

---

# 39. Customer App — Invalid QR

Use inline error card:

```text
This QR code is not valid.

Please scan the QR code provided by the restaurant.

[Scan Again]
```

---

# 40. Customer App — Menu Screen Structure

Mobile layout:

```text
┌────────────────────────────┐
│ Restaurant Header          │
│ Table / Order Type         │
├────────────────────────────┤
│ Search                     │
├────────────────────────────┤
│ Category Chips/Tabs        │
├────────────────────────────┤
│ Product Section            │
│ Product Card               │
│ Product Card               │
│ Product Card               │
└────────────────────────────┘

Floating Cart Bar
```

---

# 41. Customer Restaurant Header

Show:

```text
logo
restaurant name
branch name
table
open/closed state
```

Example:

```text
[Logo] Pizza House
       Patna Main

Table 12
```

Keep compact.

---

# 42. Customer Category Navigation

Use horizontally scrolling category chips or tabs.

Selected:

```text
primary background
white text
```

Unselected:

```text
surface secondary
text primary
```

Height:

```text
36
```

---

# 43. Customer Product Card — Mobile

Recommended:

```text
┌────────────────────────────┐
│ Name              [Image]  │
│ Description       [     ]  │
│ ₹399              [     ]  │
│                 [ Add ]    │
└────────────────────────────┘
```

Image:

```text
96 × 96
radius 12
```

Text area should dominate.

---

# 44. Customer Product Card — Tablet/Web

Use grid:

```text
2–3 columns
```

Card:

```text
image top
name
description
price
add button
```

---

# 45. Product Sold Out Design

Do not hide unless restaurant preference says so.

Show:

```text
Sold Out
```

chip.

Disable Add button.

Reduce image opacity slightly.

---

# 46. Product Detail — Mobile

Use:

```text
image hero
product name
description
price
modifier groups
quantity
note
sticky add button
```

Sticky bottom:

```text
Add to Cart • ₹440
```

---

# 47. Modifier Group Design

Header:

```text
Choose size
Required
```

Options:

```text
radio / checkbox
label
price delta right aligned
```

Use cards/list rows.

Do not use dropdown for primary food modifiers.

---

# 48. Quantity Selector

Reusable:

```text
[-]  1  [+]
```

Button size:

```text
36–40
```

No tiny plus/minus icons.

---

# 49. Customer Cart Bar

Floating/persistent:

```text
3 items                ₹947
[View Cart]
```

Style:

```text
primary background
white text
radius 16
margin 16
height 56–64
shadow
```

---

# 50. Cart Screen

Layout:

```text
Title
Restaurant/table context

Cart Item
Cart Item

Order note

Price preview
Subtotal

Proceed button
```

Each item:

```text
product
modifiers
note
quantity controls
line total
remove
```

---

# 51. Checkout Screen

Sections:

```text
Order Type
Table / Pickup
Customer Details
Payment Method
Order Summary
Price Summary
Place Order
```

Use section cards.

Do not put all fields in one undifferentiated column.

---

# 52. Checkout Order Type

Segmented control:

```text
Dine-in
Takeaway
Delivery
```

Only show enabled types.

Selected:

```text
primary
```

---

# 53. Checkout Price Summary

Use aligned rows:

```text
Subtotal             ₹850.00
Tax                   ₹42.50
Service charge         ₹0.00
Discount             -₹50.00
----------------------------
Total                 ₹842.50
```

Total:

```text
18–20 / 700
```

---

# 54. Payment Method Selector

Use card rows:

```text
( ) Cash
( ) UPI / Online
( ) Card
```

Show provider branding only if necessary.

---

# 55. Payment Pending Screen

Design:

```text
center icon/spinner
Confirming payment
short explanation
order number
```

Do not use alarming red unless failure confirmed.

---

# 56. Payment Failure Screen

Show:

```text
Payment failed

Your order has not been sent to the kitchen yet.

[Try Again]
[Choose Another Method]
```

---

# 57. Order Tracking Screen

Header:

```text
Order #1042
Table 12
₹892.50
```

Status timeline:

```text
✓ Order received
✓ Accepted
● Preparing
○ Ready
○ Served
```

Use vertical stepper.

---

# 58. Tracking Status Colors

```text
completed step → success
current step → primary
future step → disabled gray
cancelled → danger
```

---

# 59. Active Order Banner

On menu:

```text
Order #1042 • Preparing
[Track]
```

Style:

```text
primary light background
primary text
radius 12
```

---

# 60. Customer Order History

Card:

```text
Pizza House
Order #1042
12 Sep • ₹892.50
Completed
```

Use simple list.

---

# 61. Customer Profile Screen

Sections:

```text
Profile
Orders
Notifications
Help
Logout
```

If guest:

```text
Guest
Verify your phone to keep history across devices.
[Verify Phone]
```

---

# 62. Customer Phone OTP Screen

Minimal:

```text
phone field
continue button
```

OTP screen:

```text
6-digit input
resend timer
verify
```

---

# 63. Customer Offline Banner

Top banner:

```text
You're offline. Ordering is unavailable.
```

Use warning style.

Do not block browsing cached menu.

---

# 64. Customer Empty Menu

```text
Menu unavailable

This restaurant has no items available right now.

[Refresh]
```

---

# 65. Customer Accessibility

Must support:

```text
large text
screen readers
tap areas >= 44
semantic labels
contrast AA target
status not color-only
```

---

# 66. Admin App — Login Screen

Desktop/tablet:

```text
left brand panel optional
right login card
```

Mobile:

```text
logo
title
email
password
login
forgot password
```

Keep professional.

---

# 67. Admin App — Login Card

Width:

```text
max 420
```

Title:

```text
Welcome back
```

Subtitle:

```text
Sign in to manage your restaurant.
```

---

# 68. Restaurant Selection Screen

Cards:

```text
Restaurant name
Role
Branch count
```

Example:

```text
Pizza House
Owner
3 branches

[Open]
```

---

# 69. Branch Selection Screen

Grid/list:

```text
Patna Main
Boring Road
Kankarbagh
```

Show:

```text
active/inactive
address short
```

---

# 70. Admin App Shell — Mobile

Bottom nav.

Top app bar:

```text
restaurant name
branch name
notification icon
profile/menu
```

---

# 71. Admin App Shell — Tablet

Use NavigationRail.

Example destinations:

```text
Dashboard
Orders
KDS
Menu
Payments
More
```

---

# 72. Admin App Shell — Desktop

Sidebar width:

```text
240–280
```

Content:

```text
responsive max-width
```

Header:

```text
page title
branch selector
actions
```

---

# 73. Admin Dashboard Layout — Mobile

Stack:

```text
Date filter
Metric cards 2-column
Active orders card
Top products
Payment summary
```

---

# 74. Admin Dashboard — Desktop

Grid:

```text
4 metric cards

Sales chart / Order status

Top products / Payment split

Recent orders
```

Charts are optional for MVP.

---

# 75. Metric Card

Example:

```text
Today's Sales
₹24,820
+8.2% optional
```

Style:

```text
white
radius 16
padding 16
subtle border
```

---

# 76. Admin Live Orders — Mobile

Tabs:

```text
New
Preparing
Ready
All
```

Cards vertically.

---

# 77. Admin Live Order Card

Show:

```text
#1042
Table 12
2 min ago

2 × Farmhouse Pizza
1 × Coke

₹892.50

[Accept]
```

Status chip top-right.

---

# 78. Admin Live Orders — Tablet/Desktop

Use:

```text
master list left
order detail right
```

or columns by status.

---

# 79. Order Detail Layout

Desktop:

```text
Left:
Items
Notes
Status history

Right:
Order metadata
Payment
Actions
```

Mobile:

```text
single column
sticky action bar
```

---

# 80. Admin Order Action Bar

Show only legal actions.

Examples:

```text
Accept
Start Preparing
Mark Ready
Mark Served
Complete
```

Destructive:

```text
Cancel
```

separate.

---

# 81. KDS Design Philosophy

KDS must be:

```text
large
high contrast
fast
minimal
touch-friendly
readable from distance
```

Do not use normal admin card density.

---

# 82. KDS Layout

Tablet landscape:

```text
NEW | PREPARING | READY
```

Each column independently scrolls.

Desktop can use 3–4 columns.

---

# 83. KDS Card

Minimum:

```text
order number
table/order type
elapsed time
items
modifier detail
notes
primary next action
```

Avoid showing:

```text
customer profile
full payment detail
analytics
```

---

# 84. KDS Urgency

Card border/header may change:

```text
normal
warning
late
```

But always include elapsed time text.

---

# 85. KDS Button

Large:

```text
height 48–56
full width
```

Examples:

```text
START PREPARING
MARK READY
```

---

# 86. Menu Management — Desktop

Recommended:

```text
left category sidebar
middle product list
right detail/editor panel
```

For MVP simpler:

```text
category list page
product list page
product form page
```

---

# 87. Menu Management — Mobile

Tabs/pages:

```text
Categories
Products
Modifiers
```

Use FAB:

```text
+ Add Product
```

---

# 88. Admin Product List Card

Show:

```text
thumbnail
name
category
price
availability toggle
more menu
```

---

# 89. Product Availability Toggle

Label:

```text
Available
Sold out
```

Do not use toggle without text.

---

# 90. Product Form Layout

Sections:

```text
Basic Info
Pricing
Image
Availability
Modifiers
```

Use section headers.

Desktop can show two columns.

---

# 91. Product Image Picker

Show:

```text
square preview
Upload / Replace
Remove
```

Recommended preview:

```text
160–200px
```

---

# 92. Modifier Management UI

Group card:

```text
Size
Required • Select 1

Small
Medium +₹50
Large +₹100
```

Actions:

```text
Edit Group
Add Option
```

---

# 93. Table Management Screen

Grid cards:

```text
Table 1
Active
4 seats
[QR]
```

Tablet/web:

```text
3–5 columns
```

Mobile:

```text
list
```

---

# 94. QR Preview Screen

Show:

```text
restaurant logo
table name
QR
"Scan to order"
```

Actions:

```text
Share
Save
Rotate QR
```

Rotate is danger/secondary action.

---

# 95. Staff Management

List row:

```text
avatar/initial
name
role chip
branch
status
more menu
```

---

# 96. Invite Staff Form

Fields:

```text
email or phone
role
branches
```

CTA:

```text
Send Invite
```

---

# 97. Role Chip Colors

Use neutral semantic distinction.

Example:

```text
Owner → primary
Manager → info
Cashier → neutral
Waiter → neutral
Kitchen → warning/light
```

Avoid too many saturated colors.

---

# 98. Payments Screen

Filters:

```text
All
Paid
Pending
Failed
Refunded
```

Rows:

```text
Order #1042
₹892.50
Online
Paid
6:31 PM
```

---

# 99. Payment Detail

Sections:

```text
Payment Summary
Order
Provider Reference
Refunds
```

Provider IDs can be copyable.

---

# 100. Refund Dialog

Show:

```text
Refund amount
Reason
Warning
```

Primary destructive CTA:

```text
Confirm Refund
```

Require confirmation.

---

# 101. Reports Screen

Use:

```text
date filter
metric summary
tables
simple charts
```

Do not make reports chart-heavy.

MVP should prioritize numbers and lists.

---

# 102. Settings Screen

Grouped list:

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

---

# 103. Settings Detail Forms

Use normal form max-width:

```text
720
```

Do not stretch form inputs across entire desktop width.

---

# 104. Responsive Component Rules

If width < 600:

```text
single column
bottom nav
full-width buttons
bottom sheets
```

600–1023:

```text
2-column where helpful
navigation rail
```

1024+:

```text
sidebar
multi-column
detail panels
```

---

# 105. Desktop Table Rules

For admin data tables:

```text
row height 48–56
sticky header optional
zebra striping not required
hover state
clear pagination
```

Do not show 15+ columns.

Prioritize:

```text
name
status
amount
date
action
```

---

# 106. Mobile Table Alternative

Never force horizontal table scrolling for core workflows.

Convert to:

```text
cards
stacked rows
```

---

# 107. Filter UI

Mobile:

```text
Filter button
→ bottom sheet
```

Desktop:

```text
inline filter bar
```

---

# 108. Sort UI

Mobile:

```text
bottom sheet
```

Desktop:

```text
dropdown
```

---

# 109. Confirmation Patterns

For non-destructive save:

```text
save directly
show snackbar
```

For destructive:

```text
dialog
explicit confirmation
```

---

# 110. Animation Rules

Use subtle motion only.

Recommended:

```text
150–250ms
```

For:

```text
page transitions
card expansion
status update
button press
bottom sheet
```

Avoid:

```text
bounce-heavy
long animations
decorative loaders
```

---

# 111. Page Transitions

Use default/native-feeling transitions.

Do not create custom transitions per screen.

---

# 112. Skeleton Loading

Use skeleton for:

```text
menu product list
dashboard metrics
orders list
```

Approximate real layout.

---

# 113. Shimmer

If shimmer is used:

```text
subtle
not high-contrast
```

---

# 114. Empty State Iconography

Use simple outline icon.

Example:

```text
shopping_bag_outlined
receipt_long_outlined
restaurant_menu_outlined
```

---

# 115. Error Iconography

Use:

```text
error_outline
wifi_off
lock_outline
```

depending on cause.

---

# 116. Permission Denied Design

Show:

```text
You don't have access to this section.

Contact your restaurant owner or manager if you need access.
```

No technical details.

---

# 117. Session Expired Design

```text
Your session has expired.

Please sign in again.

[Sign In]
```

---

# 118. Offline Admin Design

Top persistent banner:

```text
Offline — changes cannot be saved.
```

Disable critical actions.

---

# 119. Status Semantic Mapping

Create centralized mapping:

```text
OrderStatus → label
OrderStatus → foreground color
OrderStatus → background color
OrderStatus → icon
```

Do not implement mapping in multiple screens.

---

# 120. Payment Semantic Mapping

Same centralized system:

```text
Pending
Authorized
Paid
Failed
Refunded
```

---

# 121. Availability Mapping

Product:

```text
Available
Sold Out
Archived
```

---

# 122. Reusable Customer Components

Implement:

```text
RestaurantHeader
CategoryTabBar
ProductCard
ProductGridCard
ModifierOptionTile
QuantitySelector
CartSummaryBar
CartItemCard
CheckoutSection
PriceSummary
PaymentMethodTile
OrderStatusTimeline
ActiveOrderBanner
OrderHistoryCard
```

---

# 123. Reusable Admin Components

Implement:

```text
AdminPageHeader
MetricCard
OrderCard
KdsOrderCard
StatusChip
BranchSelector
RestaurantSelector
ProductListTile
AvailabilityToggle
CategoryListTile
StaffListTile
PaymentListTile
ReportSummaryCard
SettingsSection
DangerZoneCard
```

---

# 124. Reusable Global Components

Implement:

```text
AppPrimaryButton
AppSecondaryButton
AppDangerButton
AppIconButton
AppTextField
AppSearchField
AppDropdownField
AppEmptyState
AppErrorState
AppLoadingSkeleton
AppSectionHeader
AppConfirmationDialog
AppBottomSheet
```

---

# 125. Flutter Theme Requirements

Use `ThemeData`.

Configure centrally:

```text
colorScheme
scaffoldBackgroundColor
appBarTheme
textTheme
inputDecorationTheme
elevatedButtonTheme
outlinedButtonTheme
cardTheme
dividerTheme
bottomNavigationBarTheme
navigationRailTheme
```

Do not style every widget individually if theme can handle it.

---

# 126. Example AppColors

```dart
abstract final class AppColors {
  static const primary =
      Color(0xFF1F7A4C);

  static const primaryDark =
      Color(0xFF155D39);

  static const primaryLight =
      Color(0xFFEAF6EF);

  static const background =
      Color(0xFFF7F8FA);

  static const surface =
      Color(0xFFFFFFFF);

  static const surfaceSecondary =
      Color(0xFFF1F3F5);

  static const border =
      Color(0xFFE4E7EC);

  static const textPrimary =
      Color(0xFF111827);

  static const textSecondary =
      Color(0xFF667085);

  static const success =
      Color(0xFF16A34A);

  static const warning =
      Color(0xFFD97706);

  static const danger =
      Color(0xFFDC2626);

  static const info =
      Color(0xFF2563EB);
}
```

---

# 127. Example Spacing Tokens

```dart
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}
```

---

# 128. Example Radius Tokens

```dart
abstract final class AppRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xl = 20.0;
}
```

---

# 129. Responsive Helper

Create:

```dart
class Responsive {
  static bool isMobile(
    BuildContext context,
  ) =>
      MediaQuery.sizeOf(context).width <
      600;

  static bool isTablet(
    BuildContext context,
  ) {
    final width =
        MediaQuery.sizeOf(context).width;

    return width >= 600 &&
        width < 1024;
  }

  static bool isDesktop(
    BuildContext context,
  ) =>
      MediaQuery.sizeOf(context).width >=
      1024;
}
```

Or use a layout abstraction.

---

# 130. AI Implementation Rule — No Arbitrary Styling

AI coding tools must not generate:

```dart
padding: EdgeInsets.all(13)
borderRadius: 17
fontSize: 15.5
```

unless specifically required.

Use tokens.

---

# 131. AI Implementation Rule — No Inline Colors

Avoid:

```dart
Color(0xFF...)
```

inside feature code.

Use:

```text
AppColors
```

---

# 132. AI Implementation Rule — Reuse Components

Before creating a new widget, check whether one of the reusable components fits.

Do not generate five slightly different primary buttons.

---

# 133. AI Implementation Rule — State

UI state from GetX controllers.

Do not create local business state in deeply nested widgets if controller owns it.

Local ephemeral widget state is allowed for:

```text
focus
animation
temporary expansion
```

---

# 134. AI Implementation Rule — Data

No Supabase calls in Views.

Correct:

```text
View → Controller → Repository
```

---

# 135. AI Implementation Rule — Responsive

Every new screen must work on:

```text
mobile
tablet
desktop/web if admin
```

Customer native-only screens may remain mobile-first but should not break on wider screens.

---

# 136. AI Implementation Rule — Loading

Every async screen must include:

```text
loading
success
empty
error
```

unless empty state is impossible.

---

# 137. AI Implementation Rule — Forms

Every form must include:

```text
label
validation
loading submit
disabled submit where appropriate
error state
success confirmation
```

---

# 138. AI Implementation Rule — Accessibility

Every interactive icon-only control must have semantic label/tooltip.

Touch targets:

```text
>= 44×44
```

---

# 139. AI Implementation Rule — Copy

Use concise UI copy.

Good:

```text
Mark Ready
Save Product
Scan QR
Try Again
```

Avoid:

```text
Proceed to mark this order as being ready
```

---

# 140. AI Implementation Rule — Status Actions

Do not derive legal actions only from UI logic.

UI may hide unavailable action, but backend RPC remains authority.

---

# 141. AI Implementation Rule — Destructive Actions

Always require confirmation for:

```text
refund
cancel order
remove staff
archive product
rotate QR
deactivate branch
```

---

# 142. AI Implementation Rule — Money

Use:

```text
int minor units
```

No doubles for business state.

---

# 143. AI Implementation Rule — Dates

Use typed timestamps.

Format at UI layer.

---

# 144. AI Implementation Rule — Images

Always include:

```text
placeholder
error fallback
cache
```

---

# 145. AI Implementation Rule — Lists

Use builder/lazy lists.

Avoid rendering hundreds of widgets eagerly.

---

# 146. AI Implementation Rule — Navigation

Use named GetX routes consistently.

Do not mix:

```text
Navigator
Get.to
raw MaterialPageRoute
```

without reason.

---

# 147. AI Implementation Rule — Route Bindings

Each major feature should have a binding.

Example:

```text
MenuBinding
CheckoutBinding
LiveOrdersBinding
KdsBinding
```

---

# 148. AI Implementation Rule — Component Naming

Use descriptive names.

Good:

```text
ProductCard
OrderStatusTimeline
PriceSummary
StaffListTile
```

Bad:

```text
CustomWidget1
Box2
TileThing
```

---

# 149. Customer Screen Checklist — Visual

Every customer screen should answer:

```text
Where am I?
What can I do?
What is the next action?
What state is my order/cart in?
```

---

# 150. Admin Screen Checklist — Visual

Every admin screen should answer:

```text
Which restaurant?
Which branch?
What requires attention?
What actions are allowed?
```

---

# 151. Customer Navigation Priority

Primary:

```text
Menu
Cart
Track Order
```

Secondary:

```text
History
Profile
```

---

# 152. Admin Navigation Priority

Primary:

```text
Orders
KDS
Menu
```

Secondary:

```text
Payments
Staff
Reports
Settings
```

---

# 153. Customer UI Density

Low-to-medium density.

Food photos and whitespace are valuable.

---

# 154. Admin UI Density

Medium density.

Operational screens may show more information but must remain scannable.

---

# 155. KDS UI Density

High information density with large text.

Avoid decorative whitespace.

---

# 156. Customer Mobile Page Padding

```text
16px
```

Product detail image may go edge-to-edge if desired.

---

# 157. Admin Mobile Padding

```text
16px
```

---

# 158. Tablet Padding

```text
24px
```

---

# 159. Desktop Padding

```text
24–32px
```

---

# 160. Page Header Rules

Customer:

```text
simple app bar
```

Admin:

```text
title
subtitle optional
actions right
branch context visible
```

---

# 161. Admin Page Header Example

```text
Products                         [+ Add Product]
Manage menu items for Patna Main
```

---

# 162. Customer Page Header Example

```text
Pizza House
Patna Main • Table 12
```

---

# 163. Customer Search Empty State

```text
No dishes found for “pasta”.

Try another search.
```

---

# 164. Admin Search Empty State

```text
No products found.

Try changing your search or filters.
```

---

# 165. Customer Success Feedback

Examples:

```text
Added to cart
Order placed
Payment confirmed
```

Use snackbar/toast sparingly.

---

# 166. Admin Success Feedback

Examples:

```text
Product saved
Table created
Staff invited
Order marked ready
```

---

# 167. Customer Error Copy

Use plain language.

Example:

```text
This item is no longer available.
```

Not:

```text
PRODUCT_UNAVAILABLE
```

---

# 168. Admin Error Copy

Example:

```text
This order was updated on another device. Refreshing now.
```

---

# 169. Customer Cart Empty Illustration

Optional simple outline illustration.

Do not require custom art for MVP.

---

# 170. Admin Dashboard Charts

If charts included:

```text
simple bar/line/donut
```

No 3D.

No more than:

```text
2 charts per screen
```

MVP can use cards/lists only.

---

# 171. Admin Table Responsiveness

Desktop data table.

Mobile transforms to card list.

---

# 172. Customer Menu Responsive Grid

Mobile:

```text
1-column list
```

Tablet:

```text
2-column
```

Desktop/web:

```text
2–3-column
```

---

# 173. Customer Product Image Aspect Ratio

Recommended:

```text
1:1
```

or:

```text
4:3
```

Use one consistent ratio.

---

# 174. Restaurant Logo

Use:

```text
40–48px
```

menu header.

---

# 175. Avatar

Admin profile/staff:

```text
40px list
64–80px profile
```

Fallback initials.

---

# 176. Skeleton Dimensions

Mirror real content.

Menu:

```text
image + 3 text lines
```

Dashboard:

```text
metric cards
```

Orders:

```text
card blocks
```

---

# 177. Scroll Behavior

Avoid nested vertical scrolling.

Use one primary vertical scroll per screen when possible.

---

# 178. Sticky Elements

Good:

```text
customer cart bar
checkout CTA
KDS action button
admin filter header on desktop
```

Avoid too many sticky regions.

---

# 179. Safe Area

Always handle mobile safe areas.

Especially:

```text
bottom cart bar
checkout CTA
KDS fullscreen
```

---

# 180. Keyboard Handling

Forms must:

```text
scroll focused field into view
avoid hidden CTA
```

---

# 181. Numeric Keyboard

Use numeric input for:

```text
price
capacity
quantity
phone
```

---

# 182. Money Field UX

Display:

```text
₹
```

prefix.

Store integer minor units.

---

# 183. Product Form Save UX

Sticky bottom save on mobile.

Top-right save on desktop.

---

# 184. Admin Filters

Persist within session when navigating to detail and back.

---

# 185. Customer Cart Persistence UX

If app restarts:

```text
restore cart silently
```

Show nothing unless menu context changed.

---

# 186. Customer Restaurant Switch UX

Must explicitly warn cart will clear.

---

# 187. Customer Order Tracking Reconnect

Show subtle:

```text
Reconnecting…
```

not full-screen failure.

---

# 188. Admin Realtime Reconnect

Banner:

```text
Live updates disconnected. Reconnecting…
```

Refetch once connected.

---

# 189. KDS Connection Status

Small indicator:

```text
Live
Reconnecting
Offline
```

---

# 190. Admin Branch Selector

Header dropdown.

Show:

```text
Patna Main
```

Switch only if user has access.

---

# 191. Admin Restaurant Selector

In profile/sidebar.

Do not make accidental switch too easy during operations.

---

# 192. Customer Restaurant Context

Always visible on:

```text
menu
cart
checkout
```

---

# 193. Order Number Hierarchy

Admin:

```text
Order #1042
```

prominent.

Customer:

```text
Order #1042
```

prominent after checkout.

---

# 194. Table Number Hierarchy

KDS:

```text
TABLE 12
```

prominent.

Customer:

```text
Table 12
```

secondary but clear.

---

# 195. Product Price Hierarchy

Customer:

```text
14–16 / 600
```

Admin product list:

```text
14 / 500
```

---

# 196. Total Price Hierarchy

Checkout/payment:

```text
18–20 / 700
```

---

# 197. Restaurant Closed State

Menu header:

```text
Closed
```

chip.

CTA disabled:

```text
Ordering unavailable
```

---

# 198. Pause Ordering Admin State

Show persistent warning:

```text
Orders are paused for this branch.
```

Action:

```text
Resume Orders
```

---

# 199. Branch Inactive State

Admin:

```text
Inactive branch
```

with limited actions.

---

# 200. Product Archived State

Admin only.

Customer should not see archived product.

---

# 201. Customer Sold Out State

Visible but disabled.

---

# 202. Payment Paid Status

Use success chip.

---

# 203. Payment Pending Status

Use warning chip.

---

# 204. Payment Failed Status

Use danger chip.

---

# 205. Refund Status

Use:

```text
Refund Pending
Refunded
Refund Failed
```

semantic chips.

---

# 206. Admin Danger Zone

Settings bottom:

```text
Danger Zone
Pause Branch
Deactivate Branch
```

Use distinct card with light danger background.

---

# 207. Customer Destructive Actions

Mainly:

```text
remove cart item
cancel order
logout
```

Use confirm only where consequences significant.

---

# 208. Icons for Core Customer Actions

Recommended:

```text
scan → qr_code_scanner
menu → restaurant_menu
cart → shopping_bag
orders → receipt_long
profile → person_outline
search → search
```

---

# 209. Icons for Core Admin Actions

Recommended:

```text
dashboard → dashboard_outlined
orders → receipt_long
kds → kitchen_outlined
menu → restaurant_menu
tables → table_restaurant
staff → group_outlined
payments → payments_outlined
reports → analytics_outlined
settings → settings_outlined
```

---

# 210. Code Organization — Customer Components

```text
features/menu/widgets/
features/product/widgets/
features/cart/widgets/
features/checkout/widgets/
features/order_tracking/widgets/
```

Shared UI only goes into:

```text
core/widgets
```

when reusable across features.

---

# 211. Code Organization — Admin Components

Feature-specific widgets remain with feature.

Example:

```text
features/kds/widgets/kds_order_card.dart
```

Do not put everything in a single `widgets.dart`.

---

# 212. File Naming

Use:

```text
snake_case.dart
```

Examples:

```text
product_card.dart
order_status_timeline.dart
metric_card.dart
kds_order_card.dart
```

---

# 213. Class Naming

Use PascalCase:

```text
ProductCard
MenuController
OrderRepository
MerchantContextService
```

---

# 214. Theme Extension Future

If needed:

```text
ThemeExtension
```

for semantic status colors.

MVP can use static semantic mappings.

---

# 215. Customer App Visual QA Checklist

- [ ] consistent spacing
- [ ] consistent button height
- [ ] consistent card radius
- [ ] category tabs readable
- [ ] product images uniform
- [ ] cart CTA always visible
- [ ] checkout sections clear
- [ ] order status readable
- [ ] no overflow on small screen
- [ ] large text supported
- [ ] error states readable
- [ ] offline state clear

---

# 216. Admin App Visual QA Checklist

- [ ] current branch visible
- [ ] current restaurant visible
- [ ] role-aware nav
- [ ] dashboard metrics aligned
- [ ] live order cards scannable
- [ ] KDS usable from distance
- [ ] forms not too wide
- [ ] product availability obvious
- [ ] destructive actions visually distinct
- [ ] tables/cards responsive
- [ ] no overflow on tablet
- [ ] sidebar/nav consistent

---

# 217. KDS Visual QA Checklist

- [ ] order number prominent
- [ ] table prominent
- [ ] elapsed time visible
- [ ] items readable
- [ ] modifiers indented
- [ ] note stands out
- [ ] primary action large
- [ ] status obvious without color
- [ ] offline status visible
- [ ] cards do not become too narrow

---

# 218. AI Tool Prompt Contract

When an AI coding tool implements a screen, provide this file and instruct:

```text
Follow APP_DESIGN_SYSTEM_AND_UI_SPEC.md exactly.
Do not invent new design tokens.
Use existing reusable components.
Use GetX + MVC + repository architecture.
Do not call Supabase directly from Views.
Support all documented screen states.
Keep business security server-side.
```

---

# 219. AI Tool Screen Implementation Template

Every new screen should include:

```text
1. Route
2. Binding
3. Controller
4. View
5. Feature widgets
6. Repository dependency
7. Loading state
8. Empty state
9. Error state
10. Responsive behavior
11. Accessibility labels
12. Tests
```

---

# 220. AI Tool Component Implementation Template

For a reusable component specify:

```text
Name
Purpose
Inputs
Visual tokens
States
Responsive behavior
Accessibility
Example usage
```

---

# 221. AI Tool Do Not Do List

Do not:

```text
invent random colors
invent random spacing
use raw Supabase in UI
create giant controllers
create giant pages with 1000+ lines
duplicate components
hardcode order status colors repeatedly
hardcode currency formatting
use double for money
hide critical status behind color only
skip loading/error states
use service role key
use payment secret
mark payment paid from client callback
```

---

# 222. AI Tool Refactoring Rule

If generated file exceeds roughly:

```text
300–500 lines
```

consider extracting:

```text
widgets
sections
helpers
```

Do not split excessively into tiny meaningless files.

---

# 223. AI Tool Test Rule

For every feature implementation:

```text
controller test
widget test for key state
```

Critical flows additionally need integration test.

---

# 224. AI Tool Accessibility Rule

Every screen generated must support:

```text
text scaling
semantic buttons
tooltips for icon buttons
keyboard navigation on web where practical
```

---

# 225. Customer App Acceptance Design

A customer should be able to complete:

```text
Scan → Add Item → Checkout
```

without needing instructions.

---

# 226. Admin App Acceptance Design

A new restaurant staff member should understand:

```text
New Order → Accept → Preparing → Ready
```

after minimal training.

---

# 227. KDS Acceptance Design

Kitchen staff should identify:

```text
what to prepare
for which table
how long it has waited
what button to press next
```

within seconds.

---

# 228. Customer MVP Screen Inventory

```text
SplashPage
QrScannerPage
MenuPage
ProductDetailPage
CartPage
CheckoutPage
PaymentPendingPage
PaymentFailurePage
OrderTrackingPage
OrderHistoryPage
OrderDetailPage
ProfilePage
PhoneEntryPage
OtpPage
```

---

# 229. Admin MVP Screen Inventory

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
CategoryFormPage
ProductListPage
ProductFormPage
ModifierGroupListPage
ModifierGroupFormPage
TableListPage
TableFormPage
QrPreviewPage
StaffListPage
StaffInvitePage
PaymentListPage
PaymentDetailPage
ReportsPage
RestaurantSettingsPage
BranchSettingsPage
OpeningHoursPage
ProfilePage
```

---

# 230. Customer App Core Design Tokens Summary

```text
Page padding: 16 mobile
Card radius: 16
Button radius: 12
Field radius: 12
Primary CTA height: 48
Floating cart height: 56–64
Body text: 14–16
Main title: 24–28
Product image: 96×96 list
```

---

# 231. Admin App Core Design Tokens Summary

```text
Page padding: 16 / 24 / 32
Card radius: 16
Button height: 44–48
Table row: 48–56
Sidebar: 240–280
Form max width: 720
Auth max width: 420
KDS action: 48–56
```

---

# 232. Final Customer Design Goal

The customer should experience:

```text
Scan
 ↓
Understand
 ↓
Choose
 ↓
Order
 ↓
Track
```

The design should disappear behind the task.

---

# 233. Final Admin Design Goal

Restaurant staff should experience:

```text
See what matters
 ↓
Act quickly
 ↓
Avoid mistakes
 ↓
Keep service moving
```

---

# 234. Final AI Implementation Rules

1. **Use centralized design tokens.**
2. **Do not invent new visual styles per screen.**
3. **Customer app stays simple and food-first.**
4. **Admin app stays operational and scannable.**
5. **KDS prioritizes speed and readability.**
6. **Use responsive layouts from the beginning.**
7. **Every screen supports loading/error/empty states.**
8. **Use one icon family.**
9. **Use semantic colors consistently.**
10. **Use GetX bindings and controllers by feature.**
11. **No direct Supabase calls from Views.**
12. **Reuse common components.**
13. **Use integer money values.**
14. **Never place secrets in Flutter.**
15. **Respect backend security boundaries.**
16. **Add accessibility labels and adequate touch targets.**
17. **Use concise action-oriented copy.**
18. **Confirm destructive actions.**
19. **Keep mobile primary; expand intelligently for tablet/desktop.**
20. **Test generated UI on real screen sizes.**

---

# 235. Definition of Design Implementation Complete

Customer app design implementation is complete when:

```text
[ ] all customer MVP screens use the design system
[ ] visual tokens are centralized
[ ] responsive layouts work
[ ] product/menu/cart flow is consistent
[ ] order tracking is clear
[ ] loading/error/empty states exist
[ ] accessibility basics pass
```

Admin app design implementation is complete when:

```text
[ ] all admin MVP screens use the design system
[ ] mobile/tablet/desktop layouts are consistent
[ ] KDS is readable and fast
[ ] role-aware navigation works
[ ] operational statuses are consistent
[ ] forms are standardized
[ ] destructive actions are safe
[ ] loading/error/empty states exist
```

The design system is complete when an AI tool can implement a new screen **without inventing new colors, spacing, typography, component behavior, or interaction patterns**.
