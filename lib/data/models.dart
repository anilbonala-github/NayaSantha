import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Catalogue
/// ---------------------------------------------------------------------------

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tint,
  });

  final String id;
  final String name;
  final String emoji;
  final Color tint;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unit,
    required this.price,
    required this.emoji,
    this.mrp,
    this.origin = 'Telangana',
    this.farmer,
    this.inStock = true,
    this.nutritionPer100g = const <String, String>{},
    this.description = '',
    this.rating,
    this.ratingCount = 0,
    this.badges = const <String>[],
  });

  final String id;
  final String name;
  final String categoryId;

  /// Display unit, e.g. "1 kg", "500 g", "1 L".
  final String unit;
  final double price;
  final double? mrp;
  final String emoji;
  final String origin;
  final String? farmer;
  final bool inStock;
  final Map<String, String> nutritionPer100g;
  final String description;

  /// Average customer rating out of 5. Null until a product has reviews.
  final double? rating;
  final int ratingCount;

  /// Trust markers shown on the product page, e.g. "Farm Fresh".
  final List<String> badges;

  double get discountPercent {
    final double? m = mrp;
    if (m == null || m <= price) return 0;
    return ((m - price) / m) * 100;
  }
}

/// ---------------------------------------------------------------------------
/// Family & preferences
/// ---------------------------------------------------------------------------

enum AgeGroup { infant, child, teen, adult, senior }

extension AgeGroupLabel on AgeGroup {
  String get label => switch (this) {
        AgeGroup.infant => 'Infant (0-2)',
        AgeGroup.child => 'Child (3-12)',
        AgeGroup.teen => 'Teen (13-18)',
        AgeGroup.adult => 'Adult (19-59)',
        AgeGroup.senior => 'Senior (60+)',
      };
}

enum DietType { vegetarian, eggetarian, nonVegetarian, vegan, jain }

extension DietTypeLabel on DietType {
  String get label => switch (this) {
        DietType.vegetarian => 'Vegetarian',
        DietType.eggetarian => 'Eggetarian',
        DietType.nonVegetarian => 'Non-vegetarian',
        DietType.vegan => 'Vegan',
        DietType.jain => 'Jain',
      };
}

class FamilyMember {
  FamilyMember({
    required this.id,
    required this.name,
    required this.ageGroup,
    this.diet = DietType.vegetarian,
    this.allergies = const <String>[],
    this.healthGoals = const <String>[],
  });

  final String id;
  String name;
  AgeGroup ageGroup;
  DietType diet;
  List<String> allergies;
  List<String> healthGoals;
}

class Address {
  Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  final String id;
  String label;
  String line1;
  String line2;
  String city;
  String pincode;
  bool isDefault;

  String get oneLine => '$line1, $line2, $city - $pincode';
}

/// ---------------------------------------------------------------------------
/// Weekly plan & basket
/// ---------------------------------------------------------------------------

class Meal {
  const Meal({
    required this.day,
    required this.slot,
    required this.name,
    required this.calories,
    this.productIds = const <String>[],
  });

  final String day;

  /// Breakfast / Lunch / Dinner.
  final String slot;
  final String name;
  final int calories;
  final List<String> productIds;
}

class PlanLine {
  PlanLine({
    required this.product,
    required this.quantity,
    required this.reason,
  });

  final Product product;
  int quantity;

  /// Why the planner added this line — surfaced in the UI for transparency.
  final String reason;

  double get total => product.price * quantity;
}

class WeeklyPlan {
  WeeklyPlan({
    required this.weekStart,
    required this.lines,
    required this.meals,
    required this.estimatedCost,
    required this.savings,
    required this.headline,
    required this.rationale,
  });

  final DateTime weekStart;
  final List<PlanLine> lines;
  final List<Meal> meals;
  final double estimatedCost;
  final double savings;
  final String headline;
  final List<String> rationale;

  int get itemCount => lines.fold<int>(0, (int a, PlanLine l) => a + l.quantity);

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));
}

class BasketLine {
  BasketLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get total => product.price * quantity;
}

/// ---------------------------------------------------------------------------
/// Orders & delivery
/// ---------------------------------------------------------------------------

enum OrderStatus { confirmed, packed, outForDelivery, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.confirmed => 'Order confirmed',
        OrderStatus.packed => 'Packed',
        OrderStatus.outForDelivery => 'Out for delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}

class OrderEvent {
  const OrderEvent({
    required this.status,
    required this.at,
    this.note = '',
    this.done = false,
  });

  final OrderStatus status;
  final DateTime at;
  final String note;
  final bool done;
}

class Order {
  Order({
    required this.id,
    required this.placedAt,
    required this.lines,
    required this.address,
    required this.status,
    required this.timeline,
    required this.paymentMethod,
    this.deliveryFee = 0,
    this.riderName = 'Ramesh',
    this.riderPhone = '+91 90000 00000',
  });

  final String id;
  final DateTime placedAt;
  final List<BasketLine> lines;
  final Address address;
  OrderStatus status;
  final List<OrderEvent> timeline;
  final String paymentMethod;
  final double deliveryFee;
  final String riderName;
  final String riderPhone;

  double get subtotal =>
      lines.fold<double>(0, (double a, BasketLine l) => a + l.total);
  double get total => subtotal + deliveryFee;
  int get itemCount =>
      lines.fold<int>(0, (int a, BasketLine l) => a + l.quantity);
}

/// ---------------------------------------------------------------------------
/// Pantry, recipes, wallet, notifications
/// ---------------------------------------------------------------------------

enum StockLevel { good, low, out }

extension StockLevelLabel on StockLevel {
  String get label => switch (this) {
        StockLevel.good => 'In stock',
        StockLevel.low => 'Low stock',
        StockLevel.out => 'Ran out',
      };
}

class PantryItem {
  PantryItem({
    required this.product,
    required this.quantityLabel,
    required this.expiresOn,
    this.stock = StockLevel.good,
  });

  final Product product;
  String quantityLabel;
  DateTime expiresOn;
  StockLevel stock;

  int get daysLeft => expiresOn.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysLeft <= 3;

  /// Either running out or about to spoil — both mean "act on this".
  bool get needsAttention => isExpiringSoon || stock != StockLevel.good;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.minutes,
    required this.servings,
    required this.calories,
    required this.tags,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String emoji;
  final int minutes;
  final int servings;
  final int calories;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;
}

class WalletTxn {
  const WalletTxn({
    required this.id,
    required this.title,
    required this.amount,
    required this.at,
  });

  final String id;
  final String title;

  /// Positive = credit, negative = debit.
  final double amount;
  final DateTime at;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.icon,
    this.unread = true,
  });

  final String id;
  final String title;
  final String body;
  final DateTime at;
  final IconData icon;
  final bool unread;
}

/// An action the assistant can offer alongside a reply, e.g. adding the
/// ingredients it just suggested straight to the basket.
class ChatAction {
  const ChatAction({
    required this.label,
    required this.icon,
    this.productIds = const <String>[],
    this.route,
  });

  final String label;
  final IconData icon;
  final List<String> productIds;
  final String? route;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.at,
    this.bullets = const <String>[],
    this.action,
  });

  final String text;
  final bool fromUser;
  final DateTime at;

  /// Rendered as a numbered list under the message body.
  final List<String> bullets;
  final ChatAction? action;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.perks,
    this.badge,
  });

  final String id;
  final String name;
  final double pricePerMonth;
  final List<String> perks;
  final String? badge;
}
