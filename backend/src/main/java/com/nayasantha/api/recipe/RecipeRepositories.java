package com.nayasantha.api.recipe;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface RecipeRepository extends JpaRepository<Recipe, UUID> {
    List<Recipe> findByActiveTrueOrderBySortOrderAsc();
}

interface RecipeIngredientRepository extends JpaRepository<RecipeIngredient, UUID> {
    List<RecipeIngredient> findByRecipeId(UUID recipeId);
}
