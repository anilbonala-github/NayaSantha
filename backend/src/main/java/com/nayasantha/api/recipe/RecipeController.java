package com.nayasantha.api.recipe;

import com.nayasantha.api.basket.BasketDtos.BasketDto;
import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.recipe.RecipeDtos.*;
import com.nayasantha.api.security.CurrentUser;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Recipes + add-to-basket (Vol1/2 recipes module). */
@RestController
@RequestMapping("/api/v1/recipes")
public class RecipeController {

    private final RecipeService recipes;

    public RecipeController(RecipeService recipes) {
        this.recipes = recipes;
    }

    @GetMapping
    public ApiResponse<List<RecipeSummaryDto>> list() {
        return ApiResponse.of(recipes.list());
    }

    @GetMapping("/{id}")
    public ApiResponse<RecipeDetailDto> get(@PathVariable UUID id) {
        return ApiResponse.of(recipes.get(id));
    }

    /** Add all of a recipe's ingredients to the basket; returns the updated basket. */
    @PostMapping("/{id}/add-to-basket")
    public ApiResponse<BasketDto> addToBasket(@PathVariable UUID id) {
        return ApiResponse.of(recipes.addToBasket(CurrentUser.id(), id));
    }
}
