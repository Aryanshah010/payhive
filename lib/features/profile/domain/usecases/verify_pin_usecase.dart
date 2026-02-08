import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/profile/data/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

class VerifyPinParams extends Equatable {
  final String pin;

  const VerifyPinParams({required this.pin});

  @override
  List<Object?> get props => [pin];
}

final verifyPinUsecaseProvider = Provider<VerifyPinUsecase>((ref) {
  return VerifyPinUsecase(repository: ref.read(profileRepositoryProvider));
});

class VerifyPinUsecase implements UsecaseWithParams<bool, VerifyPinParams> {
  final IProfileRepository _repository;

  VerifyPinUsecase({required IProfileRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(VerifyPinParams params) {
    final pinError = _validatePin(params.pin);
    if (pinError != null) {
      return Future.value(Left(ValidationFailure(message: pinError)));
    }

    return _repository.verifyPin(pin: params.pin);
  }
}

String? _validatePin(String value) {
  final cleaned = value.trim();
  if (!RegExp(r'^\d{4}$').hasMatch(cleaned)) {
    return 'PIN must be exactly 4 digits.';
  }
  return null;
}
