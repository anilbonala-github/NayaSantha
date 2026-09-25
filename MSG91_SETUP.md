# MSG91 web login pilot

## Implemented

- The backend exposes only the restricted widget token and Widget ID through `/api/v1/auth/msg91/config`; the private Auth Key stays server-side.
- Customer and staff web login can launch MSG91's standard verification widget. Using the provider's widget in this first pilot retains its CAPTCHA and OTP resend controls. A custom OTP form is not implemented in this phase.
- `/api/v1/auth/msg91/verify` verifies the proof with MSG91 and compares the provider-verified Indian mobile number with the intended login number before issuing a session.
- Migration V24 retains only SHA-256 proof hashes to prevent repeat session creation. Staff roles come from the database; the configured owner is bootstrapped only after real verification.
- Legacy dummy-code verification fails when OTP_DEV_MODE is false, including challenges created before switching modes.

## Required Render settings

```
MSG91_AUTH_KEY=<private server Auth Key>
MSG91_WIDGET_ID=<web Widget ID>
MSG91_WIDGET_TOKEN=<restricted client widget token, NOT Auth Key>
MSG91_ENABLED=false
OWNER_MOBILE=<designated owner's 10-digit mobile>
```

Do not put secrets in git. The widget token is intentionally public client configuration; restrict it in MSG91 to the intended website and OTP use. Keep CAPTCHA enabled. Confirm MSG91's Auth Key IP allowlist permits Render outbound addresses.

## Activation checks still required

1. Back up the database, deploy V24/backend, then deploy the matching web release with the feature disabled.
2. Confirm the success response of MSG91 `verifyAccessToken` contains `type: success` and `data.identifier` with the verified +91/91 number. The parser deliberately fails closed for any other schema. Current tests use local fixtures, not evidence of MSG91's live response contract.
3. Perform a supervised real-SMS pilot, setting MSG91_ENABLED=true and OTP_DEV_MODE=false only for the planned cutover. Verify CAPTCHA, successful OTP, incorrect/expired OTP, cancellation, resend and delivery errors; validate owner/customer separation and replay rejection.
4. Confirm the Widget success callback supplies its JWT as a string or `message`. This also needs a live provider check.

## Mobile limitation

This patch supports web only. When the real provider is enabled, this version of the mobile client reports that SMS sign-in requires the website. Older TestFlight builds use the legacy OTP endpoints and cannot sign in after dummy OTP is disabled. Do not perform a general production cutover until the mobile widget is integrated and the updated iOS build is available, or until the owner explicitly chooses a web-only pilot.

## Provider references

- https://msg91.com/help/sendotp/how-to-integrate-the-new-login-with-otp-widget
- https://docs.msg91.com/otp-widget
