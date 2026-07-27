// Budget insights mirroring the backend InsightsDtos.

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class SpendPoint {
  const SpendPoint({required this.label, required this.amount});
  final String label;
  final double amount;
  factory SpendPoint.fromJson(Map<String, dynamic> j) =>
      SpendPoint(label: j['label'] as String? ?? '', amount: _d(j['amount']));
}

class CategorySpend {
  const CategorySpend({required this.category, required this.amount});
  final String category;
  final double amount;
  factory CategorySpend.fromJson(Map<String, dynamic> j) =>
      CategorySpend(category: j['category'] as String? ?? 'Other', amount: _d(j['amount']));
}

class BudgetInsights {
  const BudgetInsights({
    required this.weeklyBudget,
    required this.ordersSettled,
    required this.avgWeeklySpend,
    required this.lastSpend,
    required this.totalSaved,
    required this.withinBudgetRate,
    required this.recentSpend,
    required this.categorySpend,
  });

  final double weeklyBudget;
  final int ordersSettled;
  final double avgWeeklySpend;
  final double lastSpend;
  final double totalSaved;
  final double withinBudgetRate;
  final List<SpendPoint> recentSpend;
  final List<CategorySpend> categorySpend;

  bool get hasData => ordersSettled > 0;

  factory BudgetInsights.fromJson(Map<String, dynamic> j) => BudgetInsights(
        weeklyBudget: _d(j['weeklyBudget']),
        ordersSettled: (j['ordersSettled'] as num?)?.toInt() ?? 0,
        avgWeeklySpend: _d(j['avgWeeklySpend']),
        lastSpend: _d(j['lastSpend']),
        totalSaved: _d(j['totalSaved']),
        withinBudgetRate: _d(j['withinBudgetRate']),
        recentSpend: ((j['recentSpend'] as List?) ?? const [])
            .map((e) => SpendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        categorySpend: ((j['categorySpend'] as List?) ?? const [])
            .map((e) => CategorySpend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
