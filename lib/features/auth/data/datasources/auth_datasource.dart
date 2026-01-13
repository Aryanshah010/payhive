import 'package:payhive/features/auth/data/models/auth_api_model.dart';
import 'package:payhive/features/auth/data/models/auth_hive_model.dart';

abstract interface class IAuthLocalDatasource{
  Future<AuthHiveModel> register(AuthHiveModel model);
  Future<AuthHiveModel?> login(String phoneNumber,String password);
  Future<bool> isPhoneNumberExists(String phoneNumber);
  Future<AuthHiveModel?> getUserByPhoneNumber(String phoneNumber);
}

abstract interface class IAuthRemoteDatasource{
  Future<AuthApiModel> register(AuthApiModel model);
  Future<AuthApiModel?> login(String phoneNumber,String password);
}