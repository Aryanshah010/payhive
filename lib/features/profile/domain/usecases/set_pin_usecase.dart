import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/profile/data/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

class SetPinParams extends Equatable {
  final String newPin;
  final String? oldPin;

  const SetPinParams({required this.newPin, this.oldPin});

  @override
  List<Object?> get props => [newPin, oldPin];
}

final setPinUsecaseProvider = Provider<SetPinUsecase>((ref) {
  return SetPinUsecase(repository: ref.read(profileRepositoryProvider));
});

class SetPinUsecase implements UsecaseWithParams<bool, SetPinParams> {
  final IProfileRepository _repository;

  SetPinUsecase({required IProfileRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(SetPinParams params) {
    final pinError = _validatePin(params.newPin);
    if (pinError != null) {
      return Future.value(Left(ValidationFailure(message: pinError)));
    }

    if (params.oldPin != null && params.oldPin!.trim().isNotEmpty) {
      final oldPinError = _validatePin(params.oldPin!);
      if (oldPinError != null) {
        return Future.value(Left(ValidationFailure(message: oldPinError)));
      }
    }

    return _repository.setPin(newPin: params.newPin, oldPin: params.oldPin);
  }
}

String? _validatePin(String value) {
  final cleaned = value.trim();
  if (!RegExp(r'^\d{4}$').hasMatch(cleaned)) {
    return 'PIN must be exactly 4 digits.';
  }
  return null;
}
