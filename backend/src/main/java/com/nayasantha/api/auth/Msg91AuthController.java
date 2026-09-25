package com.nayasantha.api.auth;

import com.nayasantha.api.common.*;
import com.nayasantha.api.config.AppProperties;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth/msg91")
public class Msg91AuthController {
    private final Msg91Verifier verifier;
    private final AuthService auth;
    private final JdbcTemplate jdbc;
    private final AppProperties props;
    private final boolean enabled;
    private final String widgetId, widgetToken;
    private final String authKey;

    public Msg91AuthController(Msg91Verifier verifier, AuthService auth, JdbcTemplate jdbc, AppProperties props,
            @Value("${MSG91_ENABLED:false}") boolean enabled,
            @Value("${MSG91_WIDGET_ID:}") String widgetId,
            @Value("${MSG91_WIDGET_TOKEN:}") String widgetToken,
            @Value("${MSG91_AUTH_KEY:}") String authKey) {
        this.verifier=verifier; this.auth=auth; this.jdbc=jdbc; this.props=props;
        this.enabled=enabled; this.widgetId=widgetId; this.widgetToken=widgetToken;
        this.authKey=authKey;
    }

    @GetMapping("/config")
    public ApiResponse<?> config() {
        boolean ready=enabled && !props.getOtp().isDevMode() && !widgetId.isBlank()
                && !widgetToken.isBlank() && !authKey.isBlank() && !widgetToken.equals(authKey);
        // Only the restricted public widget token is exposed, never MSG91_AUTH_KEY.
        return ApiResponse.of(ready ? Map.of("enabled",true,"widgetId",widgetId,"widgetToken",widgetToken)
                : Map.of("enabled",false));
    }

    public record Proof(@NotBlank @Size(max=8192) String accessToken,
                        @NotBlank @Pattern(regexp="[6-9]\\d{9}") String mobile, boolean staff) {}

    @PostMapping("/verify")
    @Transactional
    public ApiResponse<AuthDtos.TokenResponse> verify(@Valid @RequestBody Proof proof, HttpServletRequest request) {
        if (!enabled || props.getOtp().isDevMode()) throw ApiException.userError("SMS sign-in is not enabled yet.");
        String mobile=verifier.verify(proof.accessToken());
        if (!mobile.equals(proof.mobile())) throw new ApiException(ErrorCode.OTP_INVALID,"Verified mobile does not match login");
        int inserted=jdbc.update("insert into used_login_proofs (token_hash) values (?) on conflict do nothing",Hashing.sha256(proof.accessToken()));
        if (inserted!=1) throw new ApiException(ErrorCode.OTP_INVALID,"Verification proof already used");
        return ApiResponse.of(auth.signInVerifiedMobile(mobile,proof.staff(),request.getHeader("User-Agent")));
    }
}
