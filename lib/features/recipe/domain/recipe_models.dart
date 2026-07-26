// Recipes mirroring the backend RecipeDtos.

class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.title,
    this.emoji,
    this.cuisine,
    required this.servings,
    required this.prepMinutes,
    required this.ingredientCount,
  });

  final String id;
  final String title;
  final String? emoji;
  final String? cuisine;
  final int servings;
  final int prepMinutes;
  final int ingredientCount;

  factory RecipeSummary.fromJson(Map<String, dynamic> j) => RecipeSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        emoji: j['emoji'] as String?,
        cuisine: j['cuisine'] as String?,
        servings: (j['servings'] as num?)?.toInt() ?? 0,
        prepMinutes: (j['prepMinutes'] as num?)?.toInt() ?? 0,
        ingredientCount: (j['ingredientCount'] as num?)?.toInt() ?? 0,
      );
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.productId,
    required this.name,
    this.emoji,
    this.unit,
    required this.quantity,
    this.note,
  });

  final String productId;
  final String name;
  final String? emoji;
  final String? unit;
  final int quantity;
  final String? note;

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        productId: j['productId'] as String,
        name: j['name'] as String? ?? 'Item',
        emoji: j['emoji'] as String?,
        unit: j['unit'] as String?,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        note: j['note'] as String?,
      );
}

class RecipeDetail {
  const RecipeDetail({
    required this.id,
    required this.title,
    this.description,
    this.emoji,
    this.cuisine,
    required this.servings,
    required this.prepMinutes,
    required this.ingredients,
  });

  final String id;
  final String title;
  final String? description;
  final String? emoji;
  final String? cuisine;
  final int servings;
  final int prepMinutes;
  final List<RecipeIngredient> ingredients;

  factory RecipeDetail.fromJson(Map<String, dynamic> j) => RecipeDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        emoji: j['emoji'] as String?,
        cuisine: j['cuisine'] as String?,
        servings: (j['servings'] as num?)?.toInt() ?? 0,
        prepMinutes: (j['prepMinutes'] as num?)?.toInt() ?? 0,
        ingredients: ((j['ingredients'] as List?) ?? const [])
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
