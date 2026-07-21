import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/address_models.dart';

/// Address CRUD + pincode serviceability (Vol2 §7).
class AddressRepository {
  AddressRepository(this._client);
  final ApiClient _client;

  Future<List<Address>> list() async {
    try {
      final data = await _client.get('/addresses') as List;
      return data.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Returns whether the Hyderabad pilot serves this pincode.
  Future<bool> checkServiceability(String pincode) async {
    try {
      final data = await _client.get('/serviceability', query: {'pincode': pincode});
      return (data as Map<String, dynamic>)['serviceable'] as bool? ?? false;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Address> create({
    String? label,
    required String line1,
    String? apartment,
    required String pincode,
    bool isDefault = false,
  }) async {
    try {
      final data = await _client.post('/addresses', body: {
        if (label != null) 'label': label,
        'line1': line1,
        if (apartment != null) 'apartment': apartment,
        'pincode': pincode,
        'isDefault': isDefault,
      });
      return Address.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> remove(String id) => _client.delete('/addresses/$id');
}
