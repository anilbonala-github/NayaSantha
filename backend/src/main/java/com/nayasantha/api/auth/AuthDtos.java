package com.nayasantha.api.auth;

import com.nayasantha.api.user.User;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

/** Request/response DTOs for the auth module (JSON is camelCase, Vol2 §5). */
public final class AuthDtos {

    private AuthDtos() {}

    public record OtpRequest(
            @NotBlank @Pattern(regexp = "\\d{10}", message = "must be a 10-digit mobile number")
            String mobile) {}

    public record OtpRequestResult(String mobile, boolean devMode, String devHint) {}

    public record OtpVerifyRequest(
            @NotBlank @Pattern(regexp = "\\d{10}") String mobile,
            @NotBlank String code) {}

    public record RefreshRequest(@NotBlank String refreshToken) {}

    public record LogoutRequest(@NotBlank String refreshToken) {}

    public record AuthUserDto(UUID id, String mobile, String name,
                              String profileCompletionStatus, String role) {
        static AuthUserDto from(User u) {
            return new AuthUserDto(u.getId(), u.getMobile(), u.getName(),
                    u.getProfileCompletionStatus().name(), u.getRole().name());
        }
    }

    public record TokenResponse(String accessToken, String refreshToken,
                                long expiresInSeconds, AuthUserDto user) {}
}
