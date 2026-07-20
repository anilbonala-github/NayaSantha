/// Catalogue domain models mirroring the backend DTOs (Vol2 §6.3). Prices and
/// products are never hard-coded in Flutter — they arrive from the API.

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.emoji,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? emoji;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
        emoji: j['emoji'] as String?,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unit,
    this.emoji,
    this.description,
    this.origin,
    this.farmer,
    this.rating,
    this.ratingCount = 0,
    this.badges = const <String>[],
    this.inStock = true,
    this.mrp,
    this.sellingPrice,
    this.maxPrice,
    this.priceVersion,
  });

  final String id;
  final String name;
  final String categoryId;
  final String unit;
  final String? emoji;
  final String? description;
  final String? origin;
  final String? farmer;
  final double? rating;
  final int ratingCount;
  final List<String> badges;
  final bool inStock;

  /// Estimate rate shown to the customer; [maxPrice] is the guaranteed ceiling.
  final double? sellingPrice;
  final double? mrp;
  final double? maxPrice;
  final int? priceVersion;

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        categoryId: j['categoryId'] as String,
        unit: j['unit'] as String,
        emoji: j['emoji'] as String?,
        description: j['description'] as String?,
        origin: j['origin'] as String?,
        farmer: j['farmer'] as String?,
        rating: _d(j['rating']),
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        badges: (j['badges'] as List?)?.cast<String>() ?? const <String>[],
        inStock: j['inStock'] as bool? ?? true,
        mrp: _d(j['mrp']),
        sellingPrice: _d(j['sellingPrice']),
        maxPrice: _d(j['maxPrice']),
        priceVersion: (j['priceVersion'] as num?)?.toInt(),
      );
}

/// One page of products (Vol2 §5 pagination).
class ProductPage {
  const ProductPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final List<Product> items;
  final int page;
  final int totalPages;
  final int totalElements;

  bool get hasMore => page + 1 < totalPages;

  factory ProductPage.fromJson(Map<String, dynamic> j) => ProductPage(
        items: (j['items'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (j['page'] as num).toInt(),
        totalPages: (j['totalPages'] as num).toInt(),
        totalElements: (j['totalElements'] as num).toInt(),
      );
}
