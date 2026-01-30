import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';
import 'package:payhive/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late LoginUsecase loginUsecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUsecase = LoginUsecase(authRepository: mockAuthRepository);
  });

  const params = LoginUsecaseParams(
    phoneNumber: '9800000000',
    password: 'password123',
  );

  const authEntity = AuthEntity(
    authId: 'auth_1',
    fullName: 'John Doe',
    phoneNumber: '9800000000',
  );

  test('should return AuthEntity when login is successful', () async {
    when(
      () => mockAuthRepository.login(params.phoneNumber, params.password),
    ).thenAnswer((_) async => const Right(authEntity));

    final result = await loginUsecase(params);
    expect(result, const Right(authEntity));

    verify(
      () => mockAuthRepository.login(params.phoneNumber, params.password),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return Failure when login fails', () async {
    const params = LoginUsecaseParams(
      phoneNumber: '9800000000',
      password: 'wrong_password',
    );

    const failure = ApiFalilure(message: 'Invalid credentials');

    when(
      () => mockAuthRepository.login(params.phoneNumber, params.password),
    ).thenAnswer((_) async => const Left(failure));

    final result = await loginUsecase(params);

    expect(result, const Left(failure));

    verify(
      () => mockAuthRepository.login(params.phoneNumber, params.password),
    ).called(1);

    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    const failure = NetworkFailure(message: 'No internet connection');

    when(
      () => mockAuthRepository.login(params.phoneNumber, params.password),
    ).thenAnswer((_) async => const Left(failure));

    final result = await loginUsecase(params);

    expect(result, const Left(failure));

    verify(
      () => mockAuthRepository.login(params.phoneNumber, params.password),
    ).called(1);

    verifyNoMoreInteractions(mockAuthRepository);
  });
}
