package com.nayasantha.api.auth;

import com.nayasantha.api.common.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/** Authentication endpoints (Vol2 §6.1, §7 catalogue). Base path /api/v1/auth. */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/otp/request")
    public ApiResponse<AuthDtos.OtpRequestResult> requestOtp(@Valid @RequestBody AuthDtos.OtpRequest body) {
        return ApiResponse.of(authService.requestOtp(body.mobile()));
    }

    @PostMapping("/otp/verify")
    public ApiResponse<AuthDtos.TokenResponse> verifyOtp(@Valid @RequestBody AuthDtos.OtpVerifyRequest body,
                                                         HttpServletRequest req) {
        return ApiResponse.of(authService.verifyOtp(body.mobile(), body.code(), req.getHeader("User-Agent")));
    }

    @PostMapping("/refresh")
    public ApiResponse<AuthDtos.TokenResponse> refresh(@Valid @RequestBody AuthDtos.RefreshRequest body,
                                                       HttpServletRequest req) {
        return ApiResponse.of(authService.refresh(body.refreshToken(), req.getHeader("User-Agent")));
    }

    @PostMapping("/logout")
    public ApiResponse<String> logout(@Valid @RequestBody AuthDtos.LogoutRequest body) {
        authService.logout(body.refreshToken());
        return ApiResponse.of("ok");
    }
}
