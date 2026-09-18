import 'package:get/get.dart';
import '../../features/auth/bindings/login_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/branch_select/bindings/branch_select_binding.dart';
import '../../features/branch_select/views/branch_select_view.dart';
import '../../features/category/bindings/category_binding.dart';
import '../../features/create_restaurant/bindings/create_restaurant_binding.dart';
import '../../features/create_restaurant/views/create_restaurant_view.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/category/bindings/category_form_binding.dart';
import '../../features/category/views/category_form_page.dart';
import '../../features/category/views/category_list_page.dart';
import '../../features/modifier/bindings/modifier_binding.dart';
import '../../features/modifier/bindings/modifier_form_binding.dart';
import '../../features/modifier/views/modifier_group_form_page.dart';
import '../../features/modifier/views/modifier_group_list_page.dart';
import '../../features/placeholder/placeholder_view.dart';
import '../../features/product/bindings/product_binding.dart';
import '../../features/product/bindings/product_form_binding.dart';
import '../../features/product/views/product_form_page.dart';
import '../../features/product/views/product_list_page.dart';
import '../../features/restaurant_select/bindings/restaurant_select_binding.dart';
import '../../features/restaurant_select/views/restaurant_select_view.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/views/splash_view.dart';
import '../../features/table/bindings/qr_binding.dart';
import '../../features/table/bindings/table_binding.dart';
import '../../features/table/bindings/table_form_binding.dart';
import '../../features/table/views/qr_preview_page.dart';
import '../../features/table/views/table_form_page.dart';
import '../../features/table/views/table_list_page.dart';
import 'admin_routes.dart';

class AdminPages {
  const AdminPages._();

  static const initial = AdminRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AdminRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AdminRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AdminRoutes.selectRestaurant,
      page: () => const RestaurantSelectView(),
      binding: RestaurantSelectBinding(),
    ),
    GetPage(
      name: AdminRoutes.selectBranch,
      page: () => const BranchSelectView(),
      binding: BranchSelectBinding(),
    ),
    GetPage(
      name: AdminRoutes.createRestaurant,
      page: () => const CreateRestaurantView(),
      binding: CreateRestaurantBinding(),
    ),
    GetPage(
      name: AdminRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AdminRoutes.orders,
      page: () => const PlaceholderView(
        title: 'Live Orders',
        routePath: AdminRoutes.orders,
      ),
    ),
    GetPage(
      name: AdminRoutes.orderDetail,
      page: () => const PlaceholderView(
        title: 'Order Details',
        routePath: AdminRoutes.orderDetail,
      ),
    ),
    GetPage(
      name: AdminRoutes.kds,
      page: () => const PlaceholderView(
        title: 'Kitchen Display System',
        routePath: AdminRoutes.kds,
      ),
    ),
    GetPage(
      name: AdminRoutes.categories,
      page: () => const CategoryListPage(),
      binding: CategoryBinding(),
    ),
    GetPage(
      name: AdminRoutes.categoryNew,
      page: () => const CategoryFormPage(),
      binding: CategoryFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.categoryEdit,
      page: () => const CategoryFormPage(),
      binding: CategoryFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.products,
      page: () => const ProductListPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AdminRoutes.productNew,
      page: () => const ProductFormPage(),
      binding: ProductFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.productEdit,
      page: () => const ProductFormPage(),
      binding: ProductFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.modifiers,
      page: () => const ModifierGroupListPage(),
      binding: ModifierBinding(),
    ),
    GetPage(
      name: AdminRoutes.modifierNew,
      page: () => const ModifierGroupFormPage(),
      binding: ModifierFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.modifierEdit,
      page: () => const ModifierGroupFormPage(),
      binding: ModifierFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.tables,
      page: () => const TableListPage(),
      binding: TableBinding(),
    ),
    GetPage(
      name: AdminRoutes.tableNew,
      page: () => const TableFormPage(),
      binding: TableFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.tableDetail,
      page: () => const TableFormPage(),
      binding: TableFormBinding(),
    ),
    GetPage(
      name: AdminRoutes.tableQr,
      page: () => const QrPreviewPage(),
      binding: QrBinding(),
    ),
    GetPage(
      name: AdminRoutes.staff,
      page: () => const PlaceholderView(
        title: 'Staff Management',
        routePath: AdminRoutes.staff,
      ),
    ),
    GetPage(
      name: AdminRoutes.staffInvite,
      page: () => const PlaceholderView(
        title: 'Invite Staff',
        routePath: AdminRoutes.staffInvite,
      ),
    ),
    GetPage(
      name: AdminRoutes.payments,
      page: () => const PlaceholderView(
        title: 'Payment Transactions',
        routePath: AdminRoutes.payments,
      ),
    ),
    GetPage(
      name: AdminRoutes.paymentDetail,
      page: () => const PlaceholderView(
        title: 'Payment Details',
        routePath: AdminRoutes.paymentDetail,
      ),
    ),
    GetPage(
      name: AdminRoutes.reports,
      page: () => const PlaceholderView(
        title: 'Sales Reports',
        routePath: AdminRoutes.reports,
      ),
    ),
    GetPage(
      name: AdminRoutes.settings,
      page: () => const PlaceholderView(
        title: 'Settings',
        routePath: AdminRoutes.settings,
      ),
    ),
    GetPage(
      name: AdminRoutes.settingsRestaurant,
      page: () => const PlaceholderView(
        title: 'Restaurant Settings',
        routePath: AdminRoutes.settingsRestaurant,
      ),
    ),
    GetPage(
      name: AdminRoutes.settingsBranch,
      page: () => const PlaceholderView(
        title: 'Branch Settings',
        routePath: AdminRoutes.settingsBranch,
      ),
    ),
    GetPage(
      name: AdminRoutes.settingsOpeningHours,
      page: () => const PlaceholderView(
        title: 'Opening Hours',
        routePath: AdminRoutes.settingsOpeningHours,
      ),
    ),
    GetPage(
      name: AdminRoutes.profile,
      page: () => const PlaceholderView(
        title: 'My Profile',
        routePath: AdminRoutes.profile,
      ),
    ),
  ];
}
