import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/profile_models.dart';

/// Profile + household reads/writes for the signed-in customer (Vol2 §6.12).
class ProfileRepository {
  ProfileRepository(this._client);
  final ApiClient _client;

  Future<Profile> getProfile() async {
    try {
      return Profile.fromJson(await _client.get('/profile') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Profile> updateProfile({String? name, String? email}) async {
    try {
      return Profile.fromJson(await _client.patch('/profile', body: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      }) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Household> getHousehold() async {
    try {
      return Household.fromJson(
          await _client.get('/households/current') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Household> updateHousehold({
    double? weeklyBudget,
    String? defaultPriceConsent,
    String? language,
  }) async {
    try {
      return Household.fromJson(await _client.patch('/households/current', body: {
        if (weeklyBudget != null) 'weeklyBudget': weeklyBudget,
        if (defaultPriceConsent != null) 'defaultPriceConsent': defaultPriceConsent,
        if (language != null) 'language': language,
      }) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Adds one household member; allergies feed hard exclusions in the planner.
  Future<void> addMember({
    String? name,
    int? age,
    required String dietaryType,
    String? allergies,
  }) async {
    try {
      await _client.post('/household-members', body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (age != null) 'age': age,
        'dietaryType': dietaryType,
        if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
      });
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Profile> completeOnboarding() async {
    try {
      return Profile.fromJson(
          await _client.post('/profile/complete') as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
