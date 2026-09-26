import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:go_router/go_router.dart';
import 'package:naya_santha/features/auth_screens.dart';
import 'package:naya_santha/features/auth/presentation/auth_controller.dart';
import 'package:naya_santha/features/auth/data/auth_repository.dart';
import 'package:naya_santha/features/auth/domain/auth_models.dart';
import 'package:naya_santha/core/api/api_client.dart';
import 'package:naya_santha/core/api/token_store.dart';
import 'package:naya_santha/state/app_state.dart';
class FakeAuth extends AuthController {
 FakeAuth():super(AuthRepository(client:ApiClient(tokenStore:TokenStore()),tokens:TokenStore()));
 @override Future<void> requestOtp(String mobile) async {state=AuthOtpSent(mobile);}
 @override Future<void> verifyOtp(String mobile,String code) async {
 state=AuthAuthenticated(AuthUser(id:'owner',mobile:mobile,profileCompletionStatus:'NEW',role:'OWNER'));
 }
}
void main() {
 testWidgets('OTP stays inline and verified owner goes to staff area', (tester) async {
  final router=GoRouter(initialLocation:'/login',routes:[
   GoRoute(path:'/login',builder:(_,__)=>const LoginScreen()),
   GoRoute(path:'/admin',builder:(_,__)=>const Scaffold(body:Text('Owner workspace'))),
  ]);
  await tester.pumpWidget(ProviderScope(overrides:[authControllerProvider.overrideWith((ref)=>FakeAuth())],
   child:legacy.ChangeNotifierProvider(create:(_)=>AppState(),child:MaterialApp.router(routerConfig:router))));
  await tester.enterText(find.byType(TextField).first,'9121304215');
  await tester.tap(find.text('Send code')); await tester.pump();
  expect(find.byType(LoginScreen),findsOneWidget);
  expect(find.text('SMS verification code'),findsOneWidget);
  await tester.enterText(find.byType(TextField).last,'123456');
  await tester.ensureVisible(find.text('Verify and sign in'));
  await tester.tap(find.text('Verify and sign in'));await tester.pumpAndSettle();
  expect(find.text('Owner workspace'),findsOneWidget);
  router.dispose();
 });
}
