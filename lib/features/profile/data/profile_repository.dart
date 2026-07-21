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
}
