import 'package:get/get.dart';
import '../../features/menu/bindings/menu_binding.dart';
import '../../features/menu/views/menu_view.dart';
import '../../features/placeholder/placeholder_view.dart';
import '../../features/product_detail/bindings/product_detail_binding.dart';
import '../../features/product_detail/views/product_detail_view.dart';
import '../../features/qr_scanner/bindings/qr_scanner_binding.dart';
import '../../features/qr_scanner/views/qr_scanner_view.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  const AppPages._();

  static const initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.scan,
      page: () => const QrScannerView(),
      binding: QrScannerBinding(),
    ),
    GetPage(
      name: AppRoutes.menu,
      page: () => const MenuView(),
      binding: MenuBinding(),
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () => const ProductDetailView(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () =>
          const PlaceholderView(title: 'Your Cart', routePath: AppRoutes.cart),
    ),
    GetPage(
      name: AppRoutes.checkout,
      page: () => const PlaceholderView(
        title: 'Checkout',
        routePath: AppRoutes.checkout,
      ),
    ),
    GetPage(
      name: AppRoutes.paymentPending,
      page: () => const PlaceholderView(
        title: 'Payment Processing',
        routePath: AppRoutes.paymentPending,
      ),
    ),
    GetPage(
      name: AppRoutes.paymentFailure,
      page: () => const PlaceholderView(
        title: 'Payment Failed',
        routePath: AppRoutes.paymentFailure,
      ),
    ),
    GetPage(
      name: AppRoutes.orderTracking,
      page: () => const PlaceholderView(
        title: 'Order Status',
        routePath: AppRoutes.orderTracking,
      ),
    ),
    GetPage(
      name: AppRoutes.orderHistory,
      page: () => const PlaceholderView(
        title: 'Order History',
        routePath: AppRoutes.orderHistory,
      ),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () =>
          const PlaceholderView(title: 'Profile', routePath: AppRoutes.profile),
    ),
    GetPage(
      name: AppRoutes.authPhone,
      page: () => const PlaceholderView(
        title: 'Phone Login',
        routePath: AppRoutes.authPhone,
      ),
    ),
    GetPage(
      name: AppRoutes.authOtp,
      page: () => const PlaceholderView(
        title: 'Verify OTP',
        routePath: AppRoutes.authOtp,
      ),
    ),
  ];
}
