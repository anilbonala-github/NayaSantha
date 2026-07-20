package com.nayasantha.api.address;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ServiceablePincodeRepository extends JpaRepository<ServiceablePincode, String> {
    boolean existsByPincodeAndActiveTrue(String pincode);
}
