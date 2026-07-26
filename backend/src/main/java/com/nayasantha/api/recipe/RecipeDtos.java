package com.nayasantha.api.recipe;

import java.util.List;
import java.util.UUID;

public final class RecipeDtos {

    private RecipeDtos() {}

    public record RecipeSummaryDto(UUID id, String code, String title, String emoji,
                                   String cuisine, int servings, int prepMinutes, int ingredientCount) {}

    public record IngredientDto(UUID productId, String name, String emoji, String unit,
                                int quantity, String note) {}

    public record RecipeDetailDto(UUID id, String code, String title, String description,
                                  String emoji, String cuisine, int servings, int prepMinutes,
                                  List<IngredientDto> ingredients) {}
}
