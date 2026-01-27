import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';

abstract interface class IProfileRepository {
  Future<Either<Failure, String>> uploadProfileImage(File image);
}
