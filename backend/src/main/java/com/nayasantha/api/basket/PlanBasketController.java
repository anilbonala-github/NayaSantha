package com.nayasantha.api.basket;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
public class PlanBasketController {
    private final PlanBasketService service;
    public PlanBasketController(PlanBasketService service) { this.service=service; }
    @PostMapping("/api/v1/weekly-plans/{id}/add-to-basket")
    public ApiResponse<BasketDtos.BasketDto> add(@PathVariable UUID id) {
        return ApiResponse.of(service.add(CurrentUser.id(), id));
    }
}
