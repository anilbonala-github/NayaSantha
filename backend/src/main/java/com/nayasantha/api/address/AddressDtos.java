package com.nayasantha.api.address;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

public final class AddressDtos {

    private AddressDtos() {}

    public record AddressDto(UUID id, String label, String line1, String line2, String apartment,
                             String city, String pincode, boolean serviceable, boolean isDefault,
                             Long version) {
        static AddressDto from(Address a) {
            return new AddressDto(a.getId(), a.getLabel(), a.getLine1(), a.getLine2(), a.getApartment(),
                    a.getCity(), a.getPincode(), a.isServiceable(), a.isDefault(), a.getVersion());
        }
    }

    public record UpsertAddressRequest(
            String label,
            @NotBlank String line1, String line2, String apartment, String city,
            @NotBlank @Pattern(regexp = "\\d{6}", message = "must be a 6-digit pincode") String pincode,
            Boolean isDefault) {}

    public record ServiceabilityResult(String pincode, boolean serviceable) {}
}
