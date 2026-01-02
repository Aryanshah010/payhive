import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/hive/hive_service.dart';
import 'package:payhive/features/auth/data/datasources/auth_datasource.dart';
import 'package:payhive/features/auth/data/models/auth_hive_model.dart';

final authLocalDatasourceProvider = Provider<IAuthDatasource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return AuthLocalDatasource(hiveService: hiveService);
});


class AuthLocalDatasource implements IAuthDatasource {
  final HiveService _hiveService;

  AuthLocalDatasource({required HiveService hiveService})
    : _hiveService = hiveService;

  @override
  Future<AuthHiveModel?> login(String phoneNumber, String password) async {
    try {
      final user = await _hiveService.loginUser(phoneNumber, password);
      return Future.value(user);
    } catch (e) {
      return Future.value(null);
    }
  }

  @override
  Future<bool> register(AuthHiveModel model) async {
    try {
      await _hiveService.registerUser(model);
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  }

  @override
  Future<bool> isPhoneNumberExists(String phoneNumber) {
    try {
      final exits = _hiveService.isPhoneNumberExists(phoneNumber);
      return Future.value(exits);
    } catch (e) {
      return Future.value(false);
    }
  }

  @override
  Future<AuthHiveModel?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final user = await _hiveService.getUserByPhoneNumber(phoneNumber);
      return Future.value(user);
    } catch (e) {
      return Future.value(null);
    }
  }
}
