import 'dart:io';

abstract interface class IProfileRemoteDataSource{
  Future<String> uploadProfileImage(File image);
}