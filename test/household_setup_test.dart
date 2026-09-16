import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naya_santha/core/api/api_client.dart';
import 'package:naya_santha/core/api/api_failure.dart';
import 'package:naya_santha/core/api/token_store.dart';
import 'package:naya_santha/core/theme/app_theme.dart';
import 'package:naya_santha/features/address/data/address_repository.dart';
import 'package:naya_santha/features/address/domain/address_models.dart';
import 'package:naya_santha/features/address/presentation/address_providers.dart';
import 'package:naya_santha/features/address/presentation/address_screen.dart';
import 'package:naya_santha/features/onboarding/presentation/onboarding_screens.dart';
import 'package:naya_santha/features/pantry/data/pantry_repository.dart';
import 'package:naya_santha/features/pantry/domain/pantry_models.dart';
import 'package:naya_santha/features/pantry/presentation/pantry_providers.dart';
import 'package:naya_santha/features/profile/data/profile_repository.dart';
import 'package:naya_santha/features/profile/domain/profile_models.dart';
import 'package:naya_santha/features/profile/presentation/profile_providers.dart';

ApiClient client() => ApiClient(tokenStore: TokenStore());

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository() : super(client());
  List<HouseholdMember> members = [];
  double budget = 1500;
  int additions = 0, completions = 0;
  bool failSave = false;
  @override
  Future<Household> getHousehold() async => Household(
      weeklyBudget: budget,
      defaultPriceConsent: 'ASK',
      members: List.of(members),
      version: 1);
  @override
  Future<HouseholdMember> addMember(
      {String? name,
      int? age,
      required String dietaryType,
      String? allergies}) async {
    if (failSave) {
      throw const ApiFailure(
          errorCode: 'OFFLINE', userMessage: 'Cannot save right now');
    }
    final member = HouseholdMember(
        id: 'member-${++additions}',
        name: name,
        age: age,
        dietaryType: dietaryType,
        allergies: allergies,
        version: 1);
    members.add(member);
    return member;
  }

  @override
  Future<HouseholdMember> updateMember(
      {required String id,
      required String name,
      int? age,
      required String dietaryType,
      required String allergies,
      int? version}) async {
    final member = HouseholdMember(
        id: id,
        name: name,
        age: age,
        dietaryType: dietaryType,
        allergies: allergies,
        version: 2);
    members[members.indexWhere((m) => m.id == id)] = member;
    return member;
  }

  @override
  Future<void> removeMember(String id) async =>
      members.removeWhere((m) => m.id == id);
  @override
  Future<Household> updateHousehold(
      {double? weeklyBudget,
      String? defaultPriceConsent,
      String? language,
      int? version}) async {
    budget = weeklyBudget ?? budget;
    return getHousehold();
  }

  @override
  Future<Profile> getProfile() async => const Profile(
      id: 'test-user',
      mobile: '9000000000',
      name: 'Test household',
      profileCompletionStatus: 'ONBOARDING');
  @override
  Future<Profile> completeOnboarding() async {
    completions++;
    return const Profile(
        id: 'test-user',
        mobile: '9000000000',
        name: 'Test household',
        profileCompletionStatus: 'COMPLETE');
  }
}

class FakeAddressRepository extends AddressRepository {
  FakeAddressRepository() : super(client());
  final List<Address> addresses = [];
  bool available = true;
  int saves = 0;
  @override
  Future<List<Address>> list() async => List.of(addresses);
  @override
  Future<bool> checkServiceability(String pincode) async => available;
  @override
  Future<Address> create(
      {String? label,
      required String line1,
      String? apartment,
      required String pincode,
      bool isDefault = false}) async {
    saves++;
    final address = Address(
        id: 'address-$saves',
        line1: line1,
        apartment: apartment,
        city: 'Hyderabad',
        pincode: pincode,
        serviceable: available,
        isDefault: isDefault);
    addresses.add(address);
    return address;
  }
}

class FakePantryRepository extends PantryRepository {
  FakePantryRepository() : super(client());
  int additions = 0;
  @override
  Future<List<PantryItem>> list() async => [];
  @override
  Future<PantryItem> add(
      {required String name,
      required double quantity,
      String? unit,
      String? productId,
      double lowStockThreshold = 1,
      String? expiryDate}) async {
    additions++;
    throw StateError('Onboarding must not invent pantry quantities');
  }
}

Future<GoRouter> pumpSetup(
  WidgetTester tester, {
  required FakeProfileRepository profile,
  FakeAddressRepository? addresses,
  FakePantryRepository? pantry,
  String route = '/onboarding/family',
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: route, routes: [
    GoRoute(
        path: '/onboarding/family',
        builder: (_, s) => FamilyProfileScreen(
            editing: s.uri.queryParameters['edit'] == 'true')),
    GoRoute(
        path: '/onboarding/address',
        builder: (_, s) =>
            AddressScreen(editing: s.uri.queryParameters['edit'] == 'true')),
    GoRoute(
        path: '/onboarding/dietary',
        builder: (_, s) =>
            DietaryScreen(editing: s.uri.queryParameters['edit'] == 'true')),
    GoRoute(
        path: '/onboarding/kitchen',
        builder: (_, __) => const KitchenSetupScreen()),
    GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('Account destination'))),
    GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Home destination'))),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profile),
      addressRepositoryProvider
          .overrideWithValue(addresses ?? FakeAddressRepository()),
      pantryRepositoryProvider
          .overrideWithValue(pantry ?? FakePantryRepository()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
    ),
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final width in [360.0, 390.0, 1280.0]) {
    testWidgets('family controls remain visible at $width px', (tester) async {
      final repo = FakeProfileRepository();
      await pumpSetup(tester, profile: repo, width: width);
      expect(find.text('Add yourself').hitTestable(), findsOneWidget);
      expect(find.text('Continue to delivery address').hitTestable(),
          findsOneWidget);
      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continue to delivery address'));
      expect(button.onPressed, isNull);
      expect(repo.members, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text and keyboard do not hide member inputs',
      (tester) async {
    await pumpSetup(tester,
        profile: FakeProfileRepository(), width: 360, scale: 1.5);
    await tester.ensureVisible(find.text('Add yourself'));
    await tester.tap(find.text('Add yourself'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(TextFormField, 'Name (optional)'));
    expect(find.widgetWithText(TextFormField, 'Name (optional)').hitTestable(),
        findsOneWidget);
    await tester.ensureVisible(find.text('Other allergies'));
    expect(find.text('Save member').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps inputs and successful retry saves one member',
      (tester) async {
    final repo = FakeProfileRepository()..failSave = true;
    final router = await pumpSetup(tester, profile: repo);
    await tester.tap(find.text('Add yourself'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name (optional)'), 'Me');
    await tester.tap(find.text('Save member'));
    await tester.pumpAndSettle();
    expect(find.text('Cannot save right now'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(repo.additions, 0);
    repo.failSave = false;
    await tester.tap(find.text('Save member'));
    await tester.pumpAndSettle();
    expect(repo.additions, 1);
    await tester.tap(find.text('Continue to delivery address'));
    await tester.pumpAndSettle();
    router.go('/onboarding/family');
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsOneWidget);
    expect(repo.additions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a saved member updates rather than appends',
      (tester) async {
    final repo = FakeProfileRepository()
      ..members = [
        const HouseholdMember(
            id: 'one',
            name: 'Me',
            age: 30,
            dietaryType: 'VEG',
            allergies: 'Peanut',
            version: 1),
      ];
    await pumpSetup(tester,
        profile: repo, route: '/onboarding/family?edit=true');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name (optional)'), 'Updated');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Age (optional)'), '');
    await tester.tap(find.text('Peanut'));
    await tester.tap(find.text('Save member'));
    await tester.pumpAndSettle();
    expect(repo.members.single.id, 'one');
    expect(repo.members.single.name, 'Updated');
    expect(repo.members.single.age, isNull);
    expect(repo.members.single.allergies, '');
    expect(repo.additions, 0);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Account destination'), findsOneWidget);
  });

  testWidgets(
      'budget form is visible, validates input and preserves exact amount',
      (tester) async {
    final repo = FakeProfileRepository()..budget = 1750.50;
    await pumpSetup(tester,
        profile: repo, route: '/onboarding/dietary?edit=true', width: 360);
    final input = find.widgetWithText(TextFormField, 'Weekly grocery budget');
    expect(input.hitTestable(), findsOneWidget);
    expect(find.text('1750.50'), findsOneWidget);
    await tester.enterText(input, '0');
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(repo.budget, 1750.50);
    await tester.enterText(input, '2250');
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(repo.budget, 2250);
    expect(find.text('Account destination'), findsOneWidget);
  });

  testWidgets('address requires valid saved serviceability before continuing',
      (tester) async {
    final addresses = FakeAddressRepository()..available = false;
    await pumpSetup(tester,
        profile: FakeProfileRepository(),
        addresses: addresses,
        route: '/onboarding/address');
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Use saved address'))
            .onPressed,
        isNull);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Flat / house and street'),
        'Flat 101, Test Street');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Pincode'), '500001');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save address and continue'));
    await tester.pumpAndSettle();
    expect(addresses.saves, 0);
    expect(find.textContaining('Choose a serviceable address'), findsOneWidget);
    addresses.available = true;
    await tester.tap(find.text('Save address and continue'));
    await tester.pumpAndSettle();
    expect(addresses.saves, 1);
    expect(find.text('Your weekly budget'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kitchen is optional and never seeds made-up quantities',
      (tester) async {
    final repo = FakeProfileRepository();
    final pantry = FakePantryRepository();
    await pumpSetup(tester,
        profile: repo,
        pantry: pantry,
        route: '/onboarding/kitchen',
        width: 360);
    expect(find.text('Avoid buying what you already have').hitTestable(),
        findsOneWidget);
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();
    expect(repo.completions, 1);
    expect(pantry.additions, 0);
    expect(find.text('Home destination'), findsOneWidget);
  });
}
