/// Authenticated customer, mirroring the backend `AuthUserDto` (Vol2 §6.1).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.mobile,
    this.name,
    required this.profileCompletionStatus,
  });

  final String id;
  final String mobile;
  final String? name;
  final String profileCompletionStatus; // NEW | ONBOARDING | COMPLETE

  bool get needsOnboarding => profileCompletionStatus != 'COMPLETE';

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String,
        mobile: j['mobile'] as String,
        name: j['name'] as String?,
        profileCompletionStatus: j['profileCompletionStatus'] as String,
      );
}

/// Result of a successful OTP verification / refresh.
class AuthSession {
  const AuthSession({required this.user, required this.accessToken});
  final AuthUser user;
  final String accessToken;
}
