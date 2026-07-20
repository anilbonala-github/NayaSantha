package com.nayasantha.api.catalogue;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/**
 * Explicit finders rather than one nullable-parameter query: Postgres can't
 * infer the type of a null bind parameter in `:param IS NULL`, so the service
 * picks the method matching the supplied filters.
 */
public interface ProductRepository extends JpaRepository<Product, UUID> {

    Page<Product> findByActiveTrue(Pageable pageable);

    Page<Product> findByActiveTrueAndCategoryId(UUID categoryId, Pageable pageable);

    Page<Product> findByActiveTrueAndNameContainingIgnoreCase(String name, Pageable pageable);

    Page<Product> findByActiveTrueAndCategoryIdAndNameContainingIgnoreCase(
            UUID categoryId, String name, Pageable pageable);

    List<Product> findTop8ByActiveTrueAndNameContainingIgnoreCase(String name);

    List<Product> findByActiveTrueOrderByNameAsc();
}
