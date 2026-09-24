package com.nayasantha.api.auth;
import com.nayasantha.api.common.*;
import com.nayasantha.api.config.AppProperties;
import com.nayasantha.api.user.*;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/v1/auth/admin")
public class AdminAuthController {
 private final AuthService auth; private final AppProperties props; private final UserRepository users;
 public AdminAuthController(AuthService auth,AppProperties props,UserRepository users) {this.auth=auth;this.props=props;this.users=users;}
 private void check(String mobile) {
  if(props.getOtp().isDevMode()) throw ApiException.userError("Staff sign-in requires real OTP delivery. Contact the owner to finish SMS setup.");
  boolean allowed=mobile.equals(props.getOwnerMobile()) || users.findByMobile(mobile).map(u->u.getRole()!=User.Role.CUSTOMER && u.getStatus()==User.Status.ACTIVE).orElse(false);
  if(!allowed) throw ApiException.forbidden("This account does not have staff access");
 }
 @PostMapping("/otp/request") public ApiResponse<AuthDtos.OtpRequestResult> request(@Valid @RequestBody AuthDtos.OtpRequest r) {check(r.mobile());return ApiResponse.of(auth.requestOtp(r.mobile()));}
 @PostMapping("/otp/verify") public ApiResponse<AuthDtos.TokenResponse> verify(@Valid @RequestBody AuthDtos.OtpVerifyRequest r,HttpServletRequest req) {check(r.mobile());return ApiResponse.of(auth.verifyOtp(r.mobile(),r.code(),req.getHeader("User-Agent")));}
}
