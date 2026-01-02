import 'package:payhive/features/auth/data/models/auth_hive_model.dart';

abstract interface class IAuthDatasource{
  Future<bool> register(AuthHiveModel model);
  Future<AuthHiveModel?> login(String phoneNumber,String password);
  Future<bool> isPhoneNumberExists(String phoneNumber);
  Future<AuthHiveModel?> getUserByPhoneNumber(String phoneNumber);
}