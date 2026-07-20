package com.nayasantha.api.catalogue;

import com.nayasantha.api.catalogue.CatalogueDtos.*;
import com.nayasantha.api.common.ApiException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Read-only catalogue: categories, product search and product details, each
 *  joined with its current active price (Vol2 §6.3). */
@Service
@Transactional(readOnly = true)
public class CatalogueService {

    private final CategoryRepository categories;
    private final ProductRepository products;
    private final ProductPriceRepository prices;

    public CatalogueService(CategoryRepository categories, ProductRepository products,
                            ProductPriceRepository prices) {
        this.categories = categories;
        this.products = products;
        this.prices = prices;
    }

    public List<CategoryDto> listCategories() {
        return categories.findByActiveTrueOrderBySortOrderAsc().stream()
                .map(CategoryDto::from).toList();
    }

    public PageDto<ProductDto> searchProducts(UUID categoryId, String query, int page, int size) {
        PageRequest pageable = PageRequest.of(page, Math.min(size, 60));
        String q = (query == null || query.isBlank()) ? null : query.trim();

        Page<Product> result;
        if (categoryId != null && q != null) {
            result = products.findByActiveTrueAndCategoryIdAndNameContainingIgnoreCase(categoryId, q, pageable);
        } else if (categoryId != null) {
            result = products.findByActiveTrueAndCategoryId(categoryId, pageable);
        } else if (q != null) {
            result = products.findByActiveTrueAndNameContainingIgnoreCase(q, pageable);
        } else {
            result = products.findByActiveTrue(pageable);
        }

        Map<UUID, ProductPrice> priceByProduct = loadPrices(result.getContent().stream()
                .map(Product::getId).toList());
        return PageDto.from(result, p -> ProductDto.from(p, priceByProduct.get(p.getId())));
    }

    public ProductDto getProduct(UUID id) {
        Product p = products.findById(id).orElseThrow(() -> ApiException.notFound("Product"));
        ProductPrice price = prices.findFirstByProductIdAndActiveTrueOrderByEffectiveFromDesc(id)
                .orElse(null);
        return ProductDto.from(p, price);
    }

    public List<ProductDto> suggestions(String query) {
        if (query == null || query.isBlank()) return List.of();
        List<Product> found = products.findTop8ByActiveTrueAndNameContainingIgnoreCase(query.trim());
        Map<UUID, ProductPrice> priceByProduct = loadPrices(found.stream().map(Product::getId).toList());
        return found.stream().map(p -> ProductDto.from(p, priceByProduct.get(p.getId()))).toList();
    }

    private Map<UUID, ProductPrice> loadPrices(List<UUID> productIds) {
        Map<UUID, ProductPrice> map = new HashMap<>();
        if (productIds.isEmpty()) return map;
        for (ProductPrice pp : prices.findByProductIdInAndActiveTrue(productIds)) {
            map.putIfAbsent(pp.getProductId(), pp);   // one active price per product/zone
        }
        return map;
    }
}
