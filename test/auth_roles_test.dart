import 'package:flutter_test/flutter_test.dart';
import 'package:naya_santha/features/auth/domain/auth_models.dart';
void main() {
  test('backend roles decide staff routing, including owner', () {
    for (final role in ['OWNER', 'ADMIN', 'CATALOGUE_MANAGER', 'ORDER_MANAGER']) {
      expect(AuthUser(id:'id',mobile:'9121304215',profileCompletionStatus:'NEW',role:role).isAdmin, isTrue);
    }
    for (final role in ['CUSTOMER', 'UNKNOWN', '']) {
      expect(AuthUser(id:'id',mobile:'9121304215',profileCompletionStatus:'COMPLETE',role:role).isAdmin, isFalse);
    }
  });
}
