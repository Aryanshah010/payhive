import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';

abstract interface class IProfileRepository {
  Future<Either<Failure, String>> uploadProfileImage(File image);
  Future<Either<Failure, ProfileEntity>> getProfile();
}
