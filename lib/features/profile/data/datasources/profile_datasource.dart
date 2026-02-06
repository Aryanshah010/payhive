import 'dart:io';
import 'package:payhive/features/profile/data/models/profile_api_model.dart';


abstract interface class IProfileRemoteDataSource{
  Future<String> uploadProfileImage(File image);
  Future<ProfileApiModel> getProfile();
  Future<void> setPin({required String newPin, String? oldPin});
}
