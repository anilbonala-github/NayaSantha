package com.nayasantha.api.pantry;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.pantry.PantryDtos.*;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Pantry endpoints (Vol2 §6.4, §7). */
@RestController
@RequestMapping("/api/v1/pantry")
public class PantryController {

    private final PantryService pantryService;

    public PantryController(PantryService pantryService) {
        this.pantryService = pantryService;
    }

    @GetMapping
    public ApiResponse<List<PantryItemDto>> list() {
        return ApiResponse.of(pantryService.list(CurrentUser.id()));
    }

    @PostMapping("/items")
    public ApiResponse<PantryItemDto> add(@Valid @RequestBody UpsertPantryItemRequest body) {
        return ApiResponse.of(pantryService.add(CurrentUser.id(), body));
    }

    @PatchMapping("/items/{id}")
    public ApiResponse<PantryItemDto> update(@PathVariable UUID id,
                                             @Valid @RequestBody UpsertPantryItemRequest body) {
        return ApiResponse.of(pantryService.update(CurrentUser.id(), id, body));
    }

    @DeleteMapping("/items/{id}")
    public ApiResponse<String> delete(@PathVariable UUID id) {
        pantryService.delete(CurrentUser.id(), id);
        return ApiResponse.of("ok");
    }
}
