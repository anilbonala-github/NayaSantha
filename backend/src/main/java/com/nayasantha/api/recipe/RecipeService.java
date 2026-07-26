package com.nayasantha.api.recipe;

import com.nayasantha.api.basket.BasketDtos.BasketDto;
import com.nayasantha.api.basket.BasketService;
import com.nayasantha.api.catalogue.Product;
import com.nayasantha.api.catalogue.ProductRepository;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.recipe.RecipeDtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Recipes + drop-ingredients-into-basket. */
@Service
public class RecipeService {

    private final RecipeRepository recipes;
    private final RecipeIngredientRepository ingredients;
    private final ProductRepository products;
    private final BasketService basket;

    public RecipeService(RecipeRepository recipes, RecipeIngredientRepository ingredients,
                         ProductRepository products, BasketService basket) {
        this.recipes = recipes;
        this.ingredients = ingredients;
        this.products = products;
        this.basket = basket;
    }

    @Transactional(readOnly = true)
    public List<RecipeSummaryDto> list() {
        return recipes.findByActiveTrueOrderBySortOrderAsc().stream()
                .map(r -> new RecipeSummaryDto(r.getId(), r.getCode(), r.getTitle(), r.getEmoji(),
                        r.getCuisine(), r.getServings(), r.getPrepMinutes(),
                        ingredients.findByRecipeId(r.getId()).size()))
                .toList();
    }

    @Transactional(readOnly = true)
    public RecipeDetailDto get(UUID recipeId) {
        Recipe r = recipes.findById(recipeId).orElseThrow(() -> ApiException.notFound("Recipe"));
        List<RecipeIngredient> lines = ingredients.findByRecipeId(recipeId);
        Map<UUID, Product> byId = productMap(lines);
        List<IngredientDto> ing = lines.stream().map(l -> {
            Product p = byId.get(l.getProductId());
            return new IngredientDto(l.getProductId(),
                    p == null ? "Item" : p.getName(), p == null ? null : p.getEmoji(),
                    p == null ? null : p.getUnit(), l.getQuantity(), l.getNote());
        }).toList();
        return new RecipeDetailDto(r.getId(), r.getCode(), r.getTitle(), r.getDescription(),
                r.getEmoji(), r.getCuisine(), r.getServings(), r.getPrepMinutes(), ing);
    }

    /** Add every ingredient to the user's basket; returns the updated basket. */
    @Transactional
    public BasketDto addToBasket(UUID userId, UUID recipeId) {
        List<RecipeIngredient> lines = ingredients.findByRecipeId(recipeId);
        if (lines.isEmpty()) throw ApiException.notFound("Recipe");
        BasketDto latest = null;
        for (RecipeIngredient l : lines) {
            latest = basket.addItem(userId, l.getProductId(), l.getQuantity());
        }
        return latest;
    }

    private Map<UUID, Product> productMap(List<RecipeIngredient> lines) {
        Map<UUID, Product> byId = new HashMap<>();
        products.findAllById(lines.stream().map(RecipeIngredient::getProductId).toList())
                .forEach(p -> byId.put(p.getId(), p));
        return byId;
    }
}
