import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/hive/hive_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/auth/data/datasources/auth_datasource.dart';
import 'package:payhive/features/auth/data/models/auth_hive_model.dart';

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return AuthLocalDatasource(
    hiveService: hiveService,
    userSessionService: userSessionService,
  );
});

class AuthLocalDatasource implements IAuthLocalDatasource {
  final HiveService _hiveService;
  final UserSessionService _userSessionService;

  AuthLocalDatasource({
    required HiveService hiveService,
    required UserSessionService userSessionService,
  }) : _hiveService = hiveService,
       _userSessionService = userSessionService;

  @override
  Future<AuthHiveModel?> login(String phoneNumber, String password) async {
    try {
      final user = await _hiveService.login(phoneNumber, password);
      //save user's details in shared prefs
      if (user != null && user.authId != null) {
        await _userSessionService.saveUserSession(
          userId: user.authId!,
          fullName: user.fullName,
          phoneNumber: user.phoneNumber,
        );
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthHiveModel> register(AuthHiveModel model) async {
    return await _hiveService.registerUser(model);
  }

  @override
  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    try {
      final exits = _hiveService.isPhoneNumberExists(phoneNumber);
      return exits;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthHiveModel?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final user = await _hiveService.getUserByPhoneNumber(phoneNumber);
      return user;
    } catch (e) {
      return null;
    }
  }
}
