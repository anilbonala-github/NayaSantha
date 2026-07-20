package com.nayasantha.api.address;

import com.nayasantha.api.address.AddressDtos.*;
import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Address CRUD + serviceability (Vol2 §7 Address module). */
@RestController
@RequestMapping("/api/v1")
public class AddressController {

    private final AddressService addressService;

    public AddressController(AddressService addressService) {
        this.addressService = addressService;
    }

    @GetMapping("/addresses")
    public ApiResponse<List<AddressDto>> list() {
        return ApiResponse.of(addressService.list(CurrentUser.id()));
    }

    @PostMapping("/addresses")
    public ApiResponse<AddressDto> create(@Valid @RequestBody UpsertAddressRequest body) {
        return ApiResponse.of(addressService.create(CurrentUser.id(), body));
    }

    @PatchMapping("/addresses/{id}")
    public ApiResponse<AddressDto> update(@PathVariable UUID id,
                                          @Valid @RequestBody UpsertAddressRequest body) {
        return ApiResponse.of(addressService.update(CurrentUser.id(), id, body));
    }

    @DeleteMapping("/addresses/{id}")
    public ApiResponse<String> delete(@PathVariable UUID id) {
        addressService.delete(CurrentUser.id(), id);
        return ApiResponse.of("ok");
    }

    @GetMapping("/serviceability")
    public ApiResponse<ServiceabilityResult> serviceability(@RequestParam String pincode) {
        return ApiResponse.of(addressService.checkServiceability(pincode));
    }
}
