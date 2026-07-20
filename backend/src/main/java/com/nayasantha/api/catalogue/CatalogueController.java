package com.nayasantha.api.catalogue;

import com.nayasantha.api.catalogue.CatalogueDtos.*;
import com.nayasantha.api.common.ApiResponse;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Catalogue reads (Vol2 §6.3, §7). These endpoints require a signed-in customer. */
@RestController
@RequestMapping("/api/v1")
public class CatalogueController {

    private final CatalogueService catalogue;

    public CatalogueController(CatalogueService catalogue) {
        this.catalogue = catalogue;
    }

    @GetMapping("/categories")
    public ApiResponse<List<CategoryDto>> categories() {
        return ApiResponse.of(catalogue.listCategories());
    }

    @GetMapping("/products")
    public ApiResponse<PageDto<ProductDto>> products(
            @RequestParam(required = false) UUID category,
            @RequestParam(required = false) String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.of(catalogue.searchProducts(category, query, page, size));
    }

    @GetMapping("/products/{id}")
    public ApiResponse<ProductDto> product(@PathVariable UUID id) {
        return ApiResponse.of(catalogue.getProduct(id));
    }

    @GetMapping("/search/suggestions")
    public ApiResponse<List<ProductDto>> suggestions(@RequestParam String query) {
        return ApiResponse.of(catalogue.suggestions(query));
    }
}
