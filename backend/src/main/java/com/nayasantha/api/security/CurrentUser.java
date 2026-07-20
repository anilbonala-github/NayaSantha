package com.nayasantha.api.security;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/** Resolves the authenticated customer's id from the security context. */
public final class CurrentUser {

    private CurrentUser() {}

    public static UUID id() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof UUID userId)) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "No authenticated user in context");
        }
        return userId;
    }
}
