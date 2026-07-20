package com.nayasantha.api.basket;

import com.nayasantha.api.basket.BasketDtos.*;
import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/** Basket endpoints (Vol2 §6.3 add, §6.6 review). Estimate + max come from the server. */
@RestController
@RequestMapping("/api/v1/baskets/current")
public class BasketController {

    private final BasketService basketService;

    public BasketController(BasketService basketService) {
        this.basketService = basketService;
    }

    @GetMapping
    public ApiResponse<BasketDto> current() {
        return ApiResponse.of(basketService.getCurrent(CurrentUser.id()));
    }

    @PostMapping("/items")
    public ApiResponse<BasketDto> addItem(@Valid @RequestBody AddItemRequest body) {
        return ApiResponse.of(basketService.addItem(CurrentUser.id(), body.productId(), body.quantity()));
    }

    @PatchMapping("/items/{id}")
    public ApiResponse<BasketDto> updateItem(@PathVariable UUID id,
                                             @Valid @RequestBody UpdateItemRequest body) {
        return ApiResponse.of(basketService.updateItem(CurrentUser.id(), id, body.quantity(), body.version()));
    }

    @DeleteMapping("/items/{id}")
    public ApiResponse<BasketDto> removeItem(@PathVariable UUID id) {
        return ApiResponse.of(basketService.removeItem(CurrentUser.id(), id));
    }
}
