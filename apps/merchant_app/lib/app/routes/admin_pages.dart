import 'package:get/get.dart';
import '../../features/auth/bindings/login_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/branch_select/bindings/branch_select_binding.dart';
import '../../features/branch_select/views/branch_select_view.dart';
import '../../features/placeholder/placeholder_view.dart';
import '../../features/restaurant_select/bindings/restaurant_select_binding.dart';
import '../../features/restaurant_select/views/restaurant_select_view.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/views/splash_view.dart';
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
      name: AdminRoutes.dashboard,
      page: () => const PlaceholderView(
        title: 'Merchant Dashboard',
        routePath: AdminRoutes.dashboard,
      ),
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
      page: () => const PlaceholderView(
        title: 'Menu Categories',
        routePath: AdminRoutes.categories,
      ),
    ),
    GetPage(
      name: AdminRoutes.categoryNew,
      page: () => const PlaceholderView(
        title: 'Create Category',
        routePath: AdminRoutes.categoryNew,
      ),
    ),
    GetPage(
      name: AdminRoutes.categoryEdit,
      page: () => const PlaceholderView(
        title: 'Edit Category',
        routePath: AdminRoutes.categoryEdit,
      ),
    ),
    GetPage(
      name: AdminRoutes.products,
      page: () => const PlaceholderView(
        title: 'Product Management',
        routePath: AdminRoutes.products,
      ),
    ),
    GetPage(
      name: AdminRoutes.productNew,
      page: () => const PlaceholderView(
        title: 'New Product',
        routePath: AdminRoutes.productNew,
      ),
    ),
    GetPage(
      name: AdminRoutes.productEdit,
      page: () => const PlaceholderView(
        title: 'Edit Product',
        routePath: AdminRoutes.productEdit,
      ),
    ),
    GetPage(
      name: AdminRoutes.modifiers,
      page: () => const PlaceholderView(
        title: 'Modifier Groups',
        routePath: AdminRoutes.modifiers,
      ),
    ),
    GetPage(
      name: AdminRoutes.modifierNew,
      page: () => const PlaceholderView(
        title: 'New Modifier Group',
        routePath: AdminRoutes.modifierNew,
      ),
    ),
    GetPage(
      name: AdminRoutes.modifierEdit,
      page: () => const PlaceholderView(
        title: 'Edit Modifier Group',
        routePath: AdminRoutes.modifierEdit,
      ),
    ),
    GetPage(
      name: AdminRoutes.tables,
      page: () => const PlaceholderView(
        title: 'Dining Tables',
        routePath: AdminRoutes.tables,
      ),
    ),
    GetPage(
      name: AdminRoutes.tableNew,
      page: () => const PlaceholderView(
        title: 'Add Table',
        routePath: AdminRoutes.tableNew,
      ),
    ),
    GetPage(
      name: AdminRoutes.tableDetail,
      page: () => const PlaceholderView(
        title: 'Table Details',
        routePath: AdminRoutes.tableDetail,
      ),
    ),
    GetPage(
      name: AdminRoutes.tableQr,
      page: () => const PlaceholderView(
        title: 'QR Code Preview',
        routePath: AdminRoutes.tableQr,
      ),
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
