import 'package:payhive/features/auth/data/models/auth_hive_model.dart';

abstract interface class IAuthDataSource{
  Future<bool> registerUser(AuthHiveModel model);
  Future<AuthHiveModel?> login(String phoneNumber,String password);
  Future<bool> isPhoneNumberExists(String phoneNumber);
}