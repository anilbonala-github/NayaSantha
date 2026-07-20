package com.nayasantha.api.address;

import com.nayasantha.api.address.AddressDtos.*;
import com.nayasantha.api.common.ApiException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Address CRUD + pincode serviceability for the Hyderabad pilot (Vol2 §6, §7). */
@Service
public class AddressService {

    private final AddressRepository addresses;
    private final ServiceablePincodeRepository pincodes;

    public AddressService(AddressRepository addresses, ServiceablePincodeRepository pincodes) {
        this.addresses = addresses;
        this.pincodes = pincodes;
    }

    @Transactional(readOnly = true)
    public List<AddressDto> list(UUID userId) {
        return addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId)
                .stream().map(AddressDto::from).toList();
    }

    @Transactional(readOnly = true)
    public ServiceabilityResult checkServiceability(String pincode) {
        return new ServiceabilityResult(pincode, pincodes.existsByPincodeAndActiveTrue(pincode));
    }

    @Transactional
    public AddressDto create(UUID userId, UpsertAddressRequest req) {
        Address a = new Address();
        a.setUserId(userId);
        apply(a, req);
        // First address becomes default automatically.
        boolean first = addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId).isEmpty();
        if (first || Boolean.TRUE.equals(req.isDefault())) {
            clearDefault(userId);
            a.setDefault(true);
        }
        return AddressDto.from(addresses.save(a));
    }

    @Transactional
    public AddressDto update(UUID userId, UUID id, UpsertAddressRequest req) {
        Address a = owned(userId, id);
        apply(a, req);
        if (Boolean.TRUE.equals(req.isDefault())) {
            clearDefault(userId);
            a.setDefault(true);
        }
        return AddressDto.from(addresses.save(a));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        addresses.delete(owned(userId, id));
    }

    // --- helpers -----------------------------------------------------------
    private Address owned(UUID userId, UUID id) {
        Address a = addresses.findById(id).orElseThrow(() -> ApiException.notFound("Address"));
        if (!a.getUserId().equals(userId)) {
            throw ApiException.forbidden("Address does not belong to the current user");
        }
        return a;
    }

    private void apply(Address a, UpsertAddressRequest req) {
        a.setLabel(req.label());
        a.setLine1(req.line1());
        a.setLine2(req.line2());
        a.setApartment(req.apartment());
        if (req.city() != null) a.setCity(req.city());
        a.setPincode(req.pincode());
        a.setServiceable(pincodes.existsByPincodeAndActiveTrue(req.pincode()));
    }

    private void clearDefault(UUID userId) {
        addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId).forEach(existing -> {
            if (existing.isDefault()) {
                existing.setDefault(false);
                addresses.save(existing);
            }
        });
    }
}
