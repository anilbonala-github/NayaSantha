import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../data/models.dart';

/// Single source of truth for the customer app.
///
/// Everything here reads from [MockData]. When the Spring Boot backend lands,
/// replace the bodies of the `_load*` and mutation methods with API calls —
/// the widget layer does not need to change.
class AppState extends ChangeNotifier {
  // --- Session -------------------------------------------------------------
  bool _signedIn = false;
  bool _guest = false;
  String _phone = '';
  String _name = 'Anil';
  bool _onboardingComplete = false;

  bool get signedIn => _signedIn;
  bool get isGuest => _guest;
  String get phone => _phone;
  String get name => _name;
  bool get onboardingComplete => _onboardingComplete;

  /// Mock OTP request. Real implementation: POST /api/auth/otp/request
  Future<void> requestOtp(String phone) async {
    _phone = phone;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    notifyListeners();
  }

  /// Any 6-digit code is accepted in mock mode.
  /// Real implementation: POST /api/auth/otp/verify -> JWT.
  Future<bool> verifyOtp(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (code.length != 6) return false;
    _signedIn = true;
    _guest = false;
    notifyListeners();
    return true;
  }

  void continueAsGuest() {
    _guest = true;
    _signedIn = false;
    notifyListeners();
  }

  void completeRegistration(String name) {
    _name = name.trim().isEmpty ? 'Anil' : name.trim();
    _signedIn = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    _guest = false;
    _onboardingComplete = false;
    _basket.clear();
    notifyListeners();
  }

  // --- Family & addresses --------------------------------------------------
  final List<FamilyMember> _family = List<FamilyMember>.from(MockData.family);
  final List<Address> _addresses = List<Address>.from(MockData.addresses);
  final Set<String> _cuisines = <String>{'Telugu', 'South Indian'};
  final Set<String> _staples = <String>{'Rice', 'Toor dal', 'Cooking oil', 'Salt'};
  double _weeklyBudget = 1500;

  List<FamilyMember> get family => List<FamilyMember>.unmodifiable(_family);
  List<Address> get addresses => List<Address>.unmodifiable(_addresses);
  Set<String> get cuisines => _cuisines;
  Set<String> get staples => _staples;
  double get weeklyBudget => _weeklyBudget;

  Address get defaultAddress =>
      _addresses.firstWhere((Address a) => a.isDefault,
          orElse: () => _addresses.first);

  void addFamilyMember(FamilyMember m) {
    _family.add(m);
    notifyListeners();
  }

  void updateFamilyMember(FamilyMember m) {
    final int i = _family.indexWhere((FamilyMember f) => f.id == m.id);
    if (i != -1) _family[i] = m;
    notifyListeners();
  }

  void removeFamilyMember(String id) {
    _family.removeWhere((FamilyMember f) => f.id == id);
    notifyListeners();
  }

  void addAddress(Address a) {
    if (a.isDefault) {
      for (final Address x in _addresses) {
        x.isDefault = false;
      }
    }
    _addresses.add(a);
    notifyListeners();
  }

  void setDefaultAddress(String id) {
    for (final Address a in _addresses) {
      a.isDefault = a.id == id;
    }
    notifyListeners();
  }

  void toggleCuisine(String c) {
    _cuisines.contains(c) ? _cuisines.remove(c) : _cuisines.add(c);
    notifyListeners();
  }

  void toggleStaple(String s) {
    _staples.contains(s) ? _staples.remove(s) : _staples.add(s);
    notifyListeners();
  }

  void setWeeklyBudget(double v) {
    _weeklyBudget = v;
    notifyListeners();
  }

  // --- Weekly plan ---------------------------------------------------------
  WeeklyPlan? _plan;
  bool _planLoading = false;

  WeeklyPlan? get plan => _plan;
  bool get planLoading => _planLoading;

  /// Real implementation: POST /api/ai/plan/generate
  Future<void> generatePlan() async {
    _planLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _plan = MockData.buildPlan();
    _planLoading = false;
    notifyListeners();
  }

  void updatePlanLineQuantity(String productId, int quantity) {
    final WeeklyPlan? p = _plan;
    if (p == null) return;
    final int i =
        p.lines.indexWhere((PlanLine l) => l.product.id == productId);
    if (i == -1) return;
    if (quantity <= 0) {
      p.lines.removeAt(i);
    } else {
      p.lines[i].quantity = quantity;
    }
    notifyListeners();
  }

  void addPlanToBasket() {
    final WeeklyPlan? p = _plan;
    if (p == null) return;
    for (final PlanLine l in p.lines) {
      addToBasket(l.product, quantity: l.quantity);
    }
  }

  // --- Basket --------------------------------------------------------------
  final List<BasketLine> _basket = <BasketLine>[];

  List<BasketLine> get basket => List<BasketLine>.unmodifiable(_basket);

  int get basketCount =>
      _basket.fold<int>(0, (int a, BasketLine l) => a + l.quantity);

  double get basketSubtotal =>
      _basket.fold<double>(0, (double a, BasketLine l) => a + l.total);

  double get basketSavings => _basket.fold<double>(0, (double a, BasketLine l) {
        final double? mrp = l.product.mrp;
        if (mrp == null) return a;
        return a + (mrp - l.product.price) * l.quantity;
      });

  static const double freeDeliveryThreshold = 699;
  double get deliveryFee =>
      basketSubtotal >= freeDeliveryThreshold || basketSubtotal == 0 ? 0 : 39;
  double get basketTotal => basketSubtotal + deliveryFee;

  int quantityOf(String productId) {
    for (final BasketLine l in _basket) {
      if (l.product.id == productId) return l.quantity;
    }
    return 0;
  }

  void addToBasket(Product p, {int quantity = 1}) {
    final int i = _basket.indexWhere((BasketLine l) => l.product.id == p.id);
    if (i == -1) {
      _basket.add(BasketLine(product: p, quantity: quantity));
    } else {
      _basket[i].quantity += quantity;
    }
    notifyListeners();
  }

  void setBasketQuantity(String productId, int quantity) {
    final int i =
        _basket.indexWhere((BasketLine l) => l.product.id == productId);
    if (i == -1) return;
    if (quantity <= 0) {
      _basket.removeAt(i);
    } else {
      _basket[i].quantity = quantity;
    }
    notifyListeners();
  }

  void clearBasket() {
    _basket.clear();
    notifyListeners();
  }

  // --- Orders --------------------------------------------------------------
  late final List<Order> _orders = <Order>[
    MockData.sampleOrder(defaultAddress),
  ];

  List<Order> get orders => List<Order>.unmodifiable(_orders);
  Order? get activeOrder {
    for (final Order o in _orders) {
      if (o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled) {
        return o;
      }
    }
    return null;
  }

  Order? orderById(String id) {
    for (final Order o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Real implementation: POST /api/orders
  Future<Order> placeOrder({required String paymentMethod}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final DateTime now = DateTime.now();
    final String id = 'NS${125688 + _orders.length}';
    final Order order = Order(
      id: id,
      placedAt: now,
      lines: List<BasketLine>.from(
        _basket.map(
          (BasketLine l) => BasketLine(product: l.product, quantity: l.quantity),
        ),
      ),
      address: defaultAddress,
      status: OrderStatus.confirmed,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
      timeline: <OrderEvent>[
        OrderEvent(status: OrderStatus.confirmed, at: now, done: true),
        OrderEvent(
            status: OrderStatus.packed,
            at: now.add(const Duration(hours: 2)),
            note: 'Expected'),
        OrderEvent(
            status: OrderStatus.outForDelivery,
            at: now.add(const Duration(hours: 5)),
            note: 'Expected'),
        OrderEvent(
            status: OrderStatus.delivered,
            at: now.add(const Duration(hours: 6)),
            note: 'Expected'),
      ],
    );
    _orders.insert(0, order);
    _basket.clear();
    notifyListeners();
    return order;
  }

  // --- Pantry --------------------------------------------------------------
  final List<PantryItem> _pantry = List<PantryItem>.from(MockData.pantry);

  List<PantryItem> get pantry => List<PantryItem>.unmodifiable(_pantry);
  List<PantryItem> get expiringSoon =>
      _pantry.where((PantryItem p) => p.isExpiringSoon).toList();

  void addPantryItem(PantryItem item) {
    _pantry.add(item);
    notifyListeners();
  }

  void removePantryItem(String productId) {
    _pantry.removeWhere((PantryItem p) => p.product.id == productId);
    notifyListeners();
  }

  // --- Wallet, subscription, referral --------------------------------------
  final List<WalletTxn> _txns = List<WalletTxn>.from(MockData.walletTxns);
  String _subscriptionId = 'sub_plus';
  final String referralCode = 'ANIL250';

  List<WalletTxn> get walletTxns => List<WalletTxn>.unmodifiable(_txns);
  double get walletBalance =>
      _txns.fold<double>(0, (double a, WalletTxn t) => a + t.amount);
  String get subscriptionId => _subscriptionId;

  void setSubscription(String id) {
    _subscriptionId = id;
    notifyListeners();
  }

  void topUpWallet(double amount) {
    _txns.insert(
      0,
      WalletTxn(
        id: 'w${_txns.length + 1}',
        title: 'Wallet top-up',
        amount: amount,
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // --- Notifications -------------------------------------------------------
  final List<AppNotification> _notifications =
      List<AppNotification>.from(MockData.notifications);

  List<AppNotification> get notifications =>
      List<AppNotification>.unmodifiable(_notifications);
  int get unreadCount =>
      _notifications.where((AppNotification n) => n.unread).length;

  void markAllRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final AppNotification n = _notifications[i];
      _notifications[i] = AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        at: n.at,
        icon: n.icon,
        unread: false,
      );
    }
    notifyListeners();
  }

  // --- Settings ------------------------------------------------------------
  bool pushEnabled = true;
  bool whatsappEnabled = true;
  bool emailEnabled = false;
  String language = 'English';

  void updateSetting(void Function() change) {
    change();
    notifyListeners();
  }

  // --- Search --------------------------------------------------------------
  List<Product> search(String query, {String? categoryId}) {
    final String q = query.trim().toLowerCase();
    return MockData.products.where((Product p) {
      final bool matchesCategory =
          categoryId == null || p.categoryId == categoryId;
      final bool matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Product> get recommended => <Product>[
        MockData.byId('p_banana'),
        MockData.byId('p_milk'),
        MockData.byId('p_spinach'),
        MockData.byId('p_rice'),
        MockData.byId('p_almonds'),
        MockData.byId('p_paneer'),
      ];
}
