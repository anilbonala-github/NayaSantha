import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/catalogue_repository.dart';
import '../domain/catalogue_models.dart';

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
    (ref) => CatalogueRepository(ref.watch(apiClientProvider)));

/// Categories for the catalogue nav (Vol2 §6.3). AsyncValue gives the UI the
/// loading / error / data states the spec requires.
final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.watch(catalogueRepositoryProvider).categories());

/// Filter for the product grid: optional category + search query.
class ProductQuery {
  const ProductQuery({this.categoryId, this.query});
  final String? categoryId;
  final String? query;

  @override
  bool operator ==(Object other) =>
      other is ProductQuery && other.categoryId == categoryId && other.query == query;
  @override
  int get hashCode => Object.hash(categoryId, query);
}

/// First page of products for a given filter.
final productsProvider =
    FutureProvider.family<ProductPage, ProductQuery>((ref, q) {
  return ref.watch(catalogueRepositoryProvider).products(
        categoryId: q.categoryId,
        query: q.query,
      );
});

/// Single product detail (Vol2 §6.3 product page).
final productProvider =
    FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(catalogueRepositoryProvider).product(id);
});
