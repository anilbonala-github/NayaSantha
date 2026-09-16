package com.nayasantha.api.order;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/baskets/current")
public class CheckoutController {
    private final CheckoutService checkout;
    public CheckoutController(CheckoutService checkout) { this.checkout=checkout; }
    public record ConfirmRequest(@NotNull UUID basketId, @NotBlank String quoteToken) {}
    @GetMapping("/checkout-preview")
    public ApiResponse<CheckoutService.Preview> preview() { return ApiResponse.of(checkout.preview(CurrentUser.id())); }
    @PostMapping("/checkout")
    public ApiResponse<OrderDtos.OrderDto> confirm(@Valid @RequestBody ConfirmRequest request) {
        return ApiResponse.of(checkout.checkout(CurrentUser.id(), request.basketId(), request.quoteToken()));
    }
}
