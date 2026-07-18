import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'models.dart';

/// Seed data. Every repository call in `state/app_state.dart` reads from here,
/// so swapping in the real Spring Boot API means changing one layer only.
class MockData {
  MockData._();

  static const List<Category> categories = <Category>[
    Category(
        id: 'fruits_veg',
        name: 'Fruits & Veg',
        emoji: '🥬',
        tint: AppColors.leaf),
    Category(
        id: 'dairy_eggs',
        name: 'Dairy & Eggs',
        emoji: '🥛',
        tint: AppColors.info),
    Category(
        id: 'grains_pulses',
        name: 'Grains & Pulses',
        emoji: '🌾',
        tint: AppColors.turmeric),
    Category(
        id: 'snacks', name: 'Snacks', emoji: '🍪', tint: AppColors.carrot),
    Category(
        id: 'beverages',
        name: 'Beverages',
        emoji: '🧃',
        tint: AppColors.aubergine),
    Category(
        id: 'personal_care',
        name: 'Personal Care',
        emoji: '🧴',
        tint: AppColors.tomato),
    Category(
        id: 'household',
        name: 'Household',
        emoji: '🧹',
        tint: AppColors.textSecondary),
    Category(
        id: 'meat_fish', name: 'Meat & Fish', emoji: '🐟', tint: AppColors.danger),
  ];

  static const List<Product> products = <Product>[
    Product(
      id: 'p_tomato',
      name: 'Tomato',
      categoryId: 'fruits_veg',
      unit: '1 kg',
      price: 40,
      mrp: 52,
      emoji: '🍅',
      farmer: 'Ramanna Farms',
      description:
          'Vine-ripened local tomatoes, harvested within 24 hours of dispatch.',
      nutritionPer100g: <String, String>{
        'Energy': '18 kcal',
        'Carbs': '3.9 g',
        'Protein': '0.9 g',
        'Vitamin C': '14 mg',
      },
      rating: 4.6,
      ratingCount: 1248,
      badges: <String>['Farm Fresh', 'No Chemicals'],
    ),
    Product(
      id: 'p_potato',
      name: 'Potato',
      categoryId: 'fruits_veg',
      unit: '1 kg',
      price: 32,
      mrp: 38,
      emoji: '🥔',
      farmer: 'Ramanna Farms',
      description: 'Firm table potatoes, good for curries and roasting.',
      nutritionPer100g: <String, String>{
        'Energy': '77 kcal',
        'Carbs': '17 g',
        'Protein': '2 g',
        'Potassium': '425 mg',
      },
      rating: 4.3,
      ratingCount: 874,
      badges: <String>['Farm Fresh'],
    ),
    Product(
      id: 'p_spinach',
      name: 'Spinach (Palak)',
      categoryId: 'fruits_veg',
      unit: '250 g',
      price: 20,
      emoji: '🥬',
      farmer: 'Ramanna Farms',
      description: 'Tender leaves, washed and bundled the morning of delivery.',
      nutritionPer100g: <String, String>{
        'Energy': '23 kcal',
        'Iron': '2.7 mg',
        'Protein': '2.9 g',
        'Folate': '194 µg',
      },
      rating: 4.4,
      ratingCount: 512,
      badges: <String>['Farm Fresh'],
    ),
    Product(
      id: 'p_brinjal',
      name: 'Brinjal',
      categoryId: 'fruits_veg',
      unit: '500 g',
      price: 28,
      emoji: '🍆',
      farmer: 'Ramanna Farms',
    ),
    Product(
      id: 'p_coriander',
      name: 'Coriander',
      categoryId: 'fruits_veg',
      unit: '100 g',
      price: 12,
      emoji: '🌿',
      farmer: 'Ramanna Farms',
    ),
    Product(
      id: 'p_banana',
      name: 'Banana',
      categoryId: 'fruits_veg',
      unit: '1 kg',
      price: 40,
      mrp: 48,
      emoji: '🍌',
      description: 'Robusta bananas — a reliable lunchbox and post-workout pick.',
      nutritionPer100g: <String, String>{
        'Energy': '89 kcal',
        'Carbs': '23 g',
        'Potassium': '358 mg',
        'Fibre': '2.6 g',
      },
      rating: 4.5,
      ratingCount: 1902,
    ),
    Product(
      id: 'p_apple',
      name: 'Apple (Shimla)',
      categoryId: 'fruits_veg',
      unit: '1 kg',
      price: 165,
      mrp: 190,
      emoji: '🍎',
      origin: 'Himachal Pradesh',
    ),
    Product(
      id: 'p_capsicum',
      name: 'Capsicum',
      categoryId: 'fruits_veg',
      unit: '500 g',
      price: 45,
      emoji: '🫑',
    ),
    Product(
      id: 'p_milk',
      name: 'Amul Milk',
      categoryId: 'dairy_eggs',
      unit: '1 L',
      price: 56,
      emoji: '🥛',
      description: 'Toned milk, delivered chilled.',
      nutritionPer100g: <String, String>{
        'Energy': '58 kcal',
        'Protein': '3.2 g',
        'Fat': '3 g',
        'Calcium': '120 mg',
      },
      rating: 4.8,
      ratingCount: 3106,
      badges: <String>['Chilled Chain'],
    ),
    Product(
      id: 'p_curd',
      name: 'Curd',
      categoryId: 'dairy_eggs',
      unit: '400 g',
      price: 45,
      emoji: '🍶',
    ),
    Product(
      id: 'p_paneer',
      name: 'Paneer',
      categoryId: 'dairy_eggs',
      unit: '200 g',
      price: 92,
      mrp: 105,
      emoji: '🧀',
      rating: 4.6,
      ratingCount: 1130,
    ),
    Product(
      id: 'p_eggs',
      name: 'Farm Eggs',
      categoryId: 'dairy_eggs',
      unit: '6 pcs',
      price: 48,
      emoji: '🥚',
    ),
    Product(
      id: 'p_rice',
      name: 'Brown Rice',
      categoryId: 'grains_pulses',
      unit: '1 kg',
      price: 85,
      mrp: 99,
      emoji: '🍚',
      description: 'Unpolished, higher fibre than white rice.',
      nutritionPer100g: <String, String>{
        'Energy': '111 kcal',
        'Carbs': '23 g',
        'Fibre': '1.8 g',
        'Protein': '2.6 g',
      },
      rating: 4.7,
      ratingCount: 640,
      badges: <String>['Unpolished'],
    ),
    Product(
      id: 'p_basmati',
      name: 'Basmati Rice',
      categoryId: 'grains_pulses',
      unit: '1 kg',
      price: 110,
      emoji: '🍚',
    ),
    Product(
      id: 'p_toor_dal',
      name: 'Toor Dal',
      categoryId: 'grains_pulses',
      unit: '1 kg',
      price: 120,
      mrp: 140,
      emoji: '🫘',
      rating: 4.5,
      ratingCount: 980,
    ),
    Product(
      id: 'p_atta',
      name: 'Whole Wheat Atta',
      categoryId: 'grains_pulses',
      unit: '5 kg',
      price: 245,
      emoji: '🌾',
    ),
    Product(
      id: 'p_almonds',
      name: 'Almonds',
      categoryId: 'snacks',
      unit: '250 g',
      price: 180,
      mrp: 210,
      emoji: '🌰',
    ),
    Product(
      id: 'p_biscuits',
      name: 'Digestive Biscuits',
      categoryId: 'snacks',
      unit: '250 g',
      price: 60,
      emoji: '🍪',
    ),
    Product(
      id: 'p_tea',
      name: 'Assam Tea',
      categoryId: 'beverages',
      unit: '500 g',
      price: 240,
      emoji: '🍵',
    ),
    Product(
      id: 'p_coffee',
      name: 'Filter Coffee',
      categoryId: 'beverages',
      unit: '250 g',
      price: 195,
      emoji: '☕',
    ),
    Product(
      id: 'p_soap',
      name: 'Handwash Refill',
      categoryId: 'personal_care',
      unit: '750 ml',
      price: 149,
      emoji: '🧴',
    ),
    Product(
      id: 'p_detergent',
      name: 'Detergent Powder',
      categoryId: 'household',
      unit: '2 kg',
      price: 320,
      emoji: '🧼',
    ),
  ];

  static Product byId(String id) =>
      products.firstWhere((Product p) => p.id == id);

  static final List<FamilyMember> family = <FamilyMember>[
    FamilyMember(
      id: 'fm_1',
      name: 'Anil',
      ageGroup: AgeGroup.adult,
      healthGoals: <String>['Lower sodium'],
    ),
    FamilyMember(id: 'fm_2', name: 'Priya', ageGroup: AgeGroup.adult),
    FamilyMember(
      id: 'fm_3',
      name: 'Aarav',
      ageGroup: AgeGroup.child,
      allergies: <String>['Peanut'],
    ),
    FamilyMember(id: 'fm_4', name: 'Lakshmi', ageGroup: AgeGroup.senior),
  ];

  static final List<Address> addresses = <Address>[
    Address(
      id: 'ad_1',
      label: 'Home',
      line1: 'Flat 1204, Block A',
      line2: 'Prestige Green Gables, Kondapur',
      city: 'Hyderabad',
      pincode: '500084',
      isDefault: true,
    ),
    Address(
      id: 'ad_2',
      label: 'Parents',
      line1: 'H.No 8-2-120',
      line2: 'Nagavaram',
      city: 'Hyderabad',
      pincode: '500043',
    ),
  ];

  static const List<String> allergyOptions = <String>[
    'Peanut',
    'Tree nuts',
    'Dairy',
    'Gluten',
    'Egg',
    'Soy',
    'Shellfish',
    'Sesame',
  ];

  static const List<String> healthGoalOptions = <String>[
    'Weight loss',
    'Muscle gain',
    'Diabetes-friendly',
    'Lower sodium',
    'Heart health',
    'High protein',
    'Kid nutrition',
    'Iron rich',
  ];

  static const List<String> cuisineOptions = <String>[
    'Telugu',
    'North Indian',
    'South Indian',
    'Continental',
    'Chinese',
    'Bengali',
  ];

  static const List<String> kitchenStaples = <String>[
    'Rice',
    'Wheat atta',
    'Toor dal',
    'Cooking oil',
    'Salt',
    'Turmeric',
    'Chilli powder',
    'Mustard seeds',
  ];

  static WeeklyPlan buildPlan() {
    final DateTime start = _mondayOf(DateTime.now());
    final List<PlanLine> lines = <PlanLine>[
      PlanLine(
        product: byId('p_tomato'),
        quantity: 2,
        reason: 'Used in 6 meals this week',
      ),
      PlanLine(
        product: byId('p_potato'),
        quantity: 2,
        reason: 'Staple for 4 members across 5 dinners',
      ),
      PlanLine(
        product: byId('p_spinach'),
        quantity: 3,
        reason: 'Iron target for Lakshmi and Aarav',
      ),
      PlanLine(
        product: byId('p_milk'),
        quantity: 7,
        reason: '1 L a day for a family of 4',
      ),
      PlanLine(
        product: byId('p_toor_dal'),
        quantity: 1,
        reason: 'Protein base for 4 lunches',
      ),
      PlanLine(
        product: byId('p_rice'),
        quantity: 2,
        reason: 'Swapped from white rice for your lower-GI goal',
      ),
      PlanLine(
        product: byId('p_banana'),
        quantity: 1,
        reason: 'Lunchbox fruit for Aarav',
      ),
      PlanLine(
        product: byId('p_curd'),
        quantity: 3,
        reason: 'Daily serving, matches last 4 weeks',
      ),
      PlanLine(
        product: byId('p_paneer'),
        quantity: 2,
        reason: 'Protein for two vegetarian dinners',
      ),
      PlanLine(
        product: byId('p_atta'),
        quantity: 1,
        reason: 'Pantry stock runs out on Thursday',
      ),
      PlanLine(
        product: byId('p_coriander'),
        quantity: 2,
        reason: 'Garnish across most Telugu dishes',
      ),
      PlanLine(
        product: byId('p_eggs'),
        quantity: 2,
        reason: 'Breakfast protein, twice this week',
      ),
    ];

    final double cost =
        lines.fold<double>(0, (double a, PlanLine l) => a + l.total);

    return WeeklyPlan(
      weekStart: start,
      lines: lines,
      meals: _meals,
      estimatedCost: cost,
      savings: 312,
      headline: 'Your AI weekly plan is ready',
      rationale: <String>[
        'Balanced nutrition across all 4 members',
        'Fits your ₹1,500 weekly budget',
        'Avoids peanut — flagged for Aarav',
        'Reuses 3 items already in your pantry',
      ],
    );
  }

  static const List<Meal> _meals = <Meal>[
    Meal(
        day: 'Mon',
        slot: 'Breakfast',
        name: 'Idli with tomato chutney',
        calories: 320,
        productIds: <String>['p_tomato']),
    Meal(
        day: 'Mon',
        slot: 'Lunch',
        name: 'Toor dal, brown rice, palak',
        calories: 540,
        productIds: <String>['p_toor_dal', 'p_rice', 'p_spinach']),
    Meal(
        day: 'Mon',
        slot: 'Dinner',
        name: 'Chapati with aloo curry',
        calories: 470,
        productIds: <String>['p_atta', 'p_potato']),
    Meal(
        day: 'Tue',
        slot: 'Breakfast',
        name: 'Upma with curd',
        calories: 300,
        productIds: <String>['p_curd']),
    Meal(
        day: 'Tue',
        slot: 'Lunch',
        name: 'Sambar rice with brinjal',
        calories: 520,
        productIds: <String>['p_brinjal', 'p_rice']),
    Meal(
        day: 'Tue',
        slot: 'Dinner',
        name: 'Palak paneer with chapati',
        calories: 560,
        productIds: <String>['p_paneer', 'p_spinach']),
    Meal(
        day: 'Wed',
        slot: 'Breakfast',
        name: 'Egg bhurji with toast',
        calories: 380,
        productIds: <String>['p_eggs']),
    Meal(
        day: 'Wed',
        slot: 'Lunch',
        name: 'Curd rice with pickle',
        calories: 430,
        productIds: <String>['p_curd', 'p_rice']),
    Meal(
        day: 'Wed',
        slot: 'Dinner',
        name: 'Capsicum masala, chapati',
        calories: 490,
        productIds: <String>['p_capsicum']),
    Meal(
        day: 'Thu',
        slot: 'Breakfast',
        name: 'Banana smoothie, poha',
        calories: 340,
        productIds: <String>['p_banana', 'p_milk']),
    Meal(
        day: 'Thu',
        slot: 'Lunch',
        name: 'Rajma with brown rice',
        calories: 550,
        productIds: <String>['p_rice']),
    Meal(
        day: 'Thu',
        slot: 'Dinner',
        name: 'Tomato rasam, rice',
        calories: 420,
        productIds: <String>['p_tomato']),
    Meal(
        day: 'Fri',
        slot: 'Breakfast',
        name: 'Dosa with chutney',
        calories: 350,
        productIds: <String>['p_coriander']),
    Meal(
        day: 'Fri',
        slot: 'Lunch',
        name: 'Veg pulao with raita',
        calories: 510,
        productIds: <String>['p_basmati', 'p_curd']),
    Meal(
        day: 'Fri',
        slot: 'Dinner',
        name: 'Paneer tikka wrap',
        calories: 530,
        productIds: <String>['p_paneer']),
    Meal(
        day: 'Sat',
        slot: 'Breakfast',
        name: 'Masala oats',
        calories: 310,
        productIds: <String>['p_milk']),
    Meal(
        day: 'Sat',
        slot: 'Lunch',
        name: 'Bagara rice, mirchi salan',
        calories: 570,
        productIds: <String>['p_basmati']),
    Meal(
        day: 'Sat',
        slot: 'Dinner',
        name: 'Khichdi with papad',
        calories: 450,
        productIds: <String>['p_toor_dal']),
    Meal(
        day: 'Sun',
        slot: 'Breakfast',
        name: 'Poori with aloo',
        calories: 480,
        productIds: <String>['p_potato']),
    Meal(
        day: 'Sun',
        slot: 'Lunch',
        name: 'Family thali',
        calories: 620,
        productIds: <String>['p_rice', 'p_spinach', 'p_curd']),
    Meal(
        day: 'Sun',
        slot: 'Dinner',
        name: 'Light vegetable soup',
        calories: 260,
        productIds: <String>['p_capsicum', 'p_tomato']),
  ];

  static final List<PantryItem> pantry = <PantryItem>[
    PantryItem(
      product: byId('p_atta'),
      quantityLabel: '1.2 kg left',
      expiresOn: DateTime.now().add(const Duration(days: 26)),
      stock: StockLevel.low,
    ),
    PantryItem(
      product: byId('p_milk'),
      quantityLabel: '1 L',
      expiresOn: DateTime.now().add(const Duration(days: 2)),
    ),
    PantryItem(
      product: byId('p_tomato'),
      quantityLabel: '400 g left',
      expiresOn: DateTime.now().add(const Duration(days: 3)),
      stock: StockLevel.low,
    ),
    PantryItem(
      product: byId('p_toor_dal'),
      quantityLabel: '600 g',
      expiresOn: DateTime.now().add(const Duration(days: 90)),
    ),
    PantryItem(
      product: byId('p_tea'),
      quantityLabel: '300 g left',
      expiresOn: DateTime.now().add(const Duration(days: 140)),
    ),
  ];

  static const List<Recipe> recipes = <Recipe>[
    Recipe(
      id: 'r_palak_paneer',
      name: 'Palak Paneer',
      emoji: '🥬',
      minutes: 30,
      servings: 4,
      calories: 280,
      tags: <String>['High protein', 'Vegetarian', 'Iron rich'],
      ingredients: <String>[
        '250 g spinach, blanched',
        '200 g paneer, cubed',
        '2 tomatoes, pureed',
        '1 onion, finely chopped',
        '1 tsp garam masala',
      ],
      steps: <String>[
        'Blanch the spinach for two minutes, then shock it in cold water and blend to a coarse puree.',
        'Fry the onion until golden, add the tomato puree and cook until the oil separates.',
        'Stir in the spinach puree and garam masala, simmer for five minutes.',
        'Fold in the paneer, cook two more minutes and serve hot.',
      ],
    ),
    Recipe(
      id: 'r_tomato_rasam',
      name: 'Tomato Rasam',
      emoji: '🍅',
      minutes: 20,
      servings: 4,
      calories: 120,
      tags: <String>['Low calorie', 'Vegan', 'Comfort food'],
      ingredients: <String>[
        '4 ripe tomatoes',
        '2 tbsp toor dal, cooked',
        '1 tsp rasam powder',
        'Tamarind, lemon sized',
        'Coriander to finish',
      ],
      steps: <String>[
        'Simmer the tamarind extract with rasam powder and salt for five minutes.',
        'Add the crushed tomatoes and cook until they soften.',
        'Whisk in the cooked dal with a cup of water and bring to a gentle froth — do not boil hard.',
        'Temper with mustard seeds and curry leaves, finish with coriander.',
      ],
    ),
    Recipe(
      id: 'r_veg_pulao',
      name: 'Vegetable Pulao',
      emoji: '🍚',
      minutes: 35,
      servings: 4,
      calories: 340,
      tags: <String>['One pot', 'Kid friendly'],
      ingredients: <String>[
        '2 cups basmati rice, soaked',
        '1 cup mixed vegetables',
        '1 onion, sliced',
        'Whole spices',
        '3 cups water',
      ],
      steps: <String>[
        'Fry the whole spices and sliced onion in ghee until fragrant.',
        'Add the vegetables and saute for three minutes.',
        'Stir in the drained rice, add water and salt, then cook covered on low heat.',
        'Rest for ten minutes before fluffing with a fork.',
      ],
    ),
    Recipe(
      id: 'r_masala_oats',
      name: 'Masala Oats',
      emoji: '🥣',
      minutes: 12,
      servings: 2,
      calories: 210,
      tags: <String>['Quick', 'High fibre', 'Breakfast'],
      ingredients: <String>[
        '1 cup rolled oats',
        '1 tomato, chopped',
        '1 carrot, grated',
        '1 tsp cumin',
        '2 cups water',
      ],
      steps: <String>[
        'Temper cumin, add the vegetables and cook until just soft.',
        'Add water and bring to a boil.',
        'Stir in the oats and cook for four minutes until thick.',
        'Season and serve immediately.',
      ],
    ),
  ];

  static final List<WalletTxn> walletTxns = <WalletTxn>[
    WalletTxn(
      id: 'w1',
      title: 'Referral bonus — Priya joined',
      amount: 100,
      at: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WalletTxn(
      id: 'w2',
      title: 'Order #NS125687',
      amount: -1214,
      at: DateTime.now().subtract(const Duration(days: 3)),
    ),
    WalletTxn(
      id: 'w3',
      title: 'Wallet top-up',
      amount: 2000,
      at: DateTime.now().subtract(const Duration(days: 6)),
    ),
    WalletTxn(
      id: 'w4',
      title: 'Refund — Tomato quality claim',
      amount: 40,
      at: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];

  static final List<AppNotification> notifications = <AppNotification>[
    AppNotification(
      id: 'n1',
      title: 'Your weekly plan is ready',
      body: '32 items planned for the week of 20 July. Review before Sunday 9 PM.',
      at: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.auto_awesome,
    ),
    AppNotification(
      id: 'n2',
      title: 'Out for delivery',
      body: 'Order #NS125687 is 25 minutes away. Ramesh is on the way.',
      at: DateTime.now().subtract(const Duration(hours: 5)),
      icon: Icons.local_shipping_outlined,
    ),
    AppNotification(
      id: 'n3',
      title: 'Milk expires in 2 days',
      body: 'Use it in the Thursday smoothie or move it to the freezer.',
      at: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.kitchen_outlined,
      unread: false,
    ),
    AppNotification(
      id: 'n4',
      title: 'Tomato prices dropped 18%',
      body: 'We adjusted your plan and saved you ₹46 this week.',
      at: DateTime.now().subtract(const Duration(days: 2)),
      icon: Icons.trending_down,
      unread: false,
    ),
  ];

  static const List<SubscriptionPlan> subscriptionPlans = <SubscriptionPlan>[
    SubscriptionPlan(
      id: 'sub_basic',
      name: 'Basic',
      pricePerMonth: 0,
      perks: <String>[
        'Weekly AI plan',
        'Standard delivery slots',
        'Delivery fee on orders under ₹699',
      ],
    ),
    SubscriptionPlan(
      id: 'sub_plus',
      name: 'Santha Plus',
      pricePerMonth: 199,
      badge: 'Most popular',
      perks: <String>[
        'Free delivery on every order',
        'Priority morning slots',
        'Nutrition insights for each member',
        '2% back to wallet',
      ],
    ),
    SubscriptionPlan(
      id: 'sub_family',
      name: 'Family Pro',
      pricePerMonth: 349,
      perks: <String>[
        'Everything in Santha Plus',
        'Dedicated meal planner chat',
        'Farmer-direct produce box weekly',
        '5% back to wallet',
      ],
    ),
  ];

  static Order sampleOrder(Address address) {
    final DateTime now = DateTime.now();
    return Order(
      id: 'NS125687',
      placedAt: now.subtract(const Duration(hours: 6)),
      address: address,
      status: OrderStatus.outForDelivery,
      paymentMethod: 'UPI · Google Pay',
      lines: <BasketLine>[
        BasketLine(product: byId('p_tomato'), quantity: 2),
        BasketLine(product: byId('p_potato'), quantity: 2),
        BasketLine(product: byId('p_milk'), quantity: 7),
        BasketLine(product: byId('p_toor_dal'), quantity: 1),
        BasketLine(product: byId('p_basmati'), quantity: 1),
      ],
      timeline: <OrderEvent>[
        OrderEvent(
            status: OrderStatus.confirmed,
            at: now.subtract(const Duration(hours: 6)),
            done: true),
        OrderEvent(
            status: OrderStatus.packed,
            at: now.subtract(const Duration(hours: 3)),
            done: true),
        OrderEvent(
            status: OrderStatus.outForDelivery,
            at: now.subtract(const Duration(minutes: 25)),
            done: true),
        OrderEvent(
            status: OrderStatus.delivered,
            at: now.add(const Duration(minutes: 25)),
            note: 'Expected'),
      ],
    );
  }

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
}
