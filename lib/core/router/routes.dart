/// Every route path in the customer app. Web URLs mirror these exactly.
class Routes {
  Routes._();

  // Onboarding / auth (Volume 2, screens 01-09)
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String familyProfile = '/onboarding/family';
  static const String address = '/onboarding/address';
  static const String dietary = '/onboarding/dietary';
  static const String kitchen = '/onboarding/kitchen';

  // Core app (screens 10-29)
  static const String home = '/home';
  static const String weeklyPlan = '/plan';
  static const String basket = '/basket';
  static const String product = '/product'; // /product/:id
  static const String search = '/search';
  static const String categories = '/categories';
  static const String checkout = '/checkout';
  static const String payment = '/payment';
  static const String orderSuccess = '/order-success'; // /order-success/:id
  static const String orderBill = '/order'; // /order/:id — final bill + settlement
  static const String orders = '/orders';
  static const String tracking = '/track'; // /track/:id
  static const String assistant = '/assistant';
  static const String pantry = '/pantry';
  static const String recipes = '/recipes';
  static const String budget = '/budget';
  static const String subscription = '/subscription';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String referral = '/referral';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String offers = '/offers';

  static String productPath(String id) => '$product/$id';
  static String orderBillPath(String id) => '$orderBill/$id';
  static String orderSuccessPath(String id) => '$orderSuccess/$id';
  static String trackingPath(String id) => '$tracking/$id';
}
