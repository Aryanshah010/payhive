import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';
import 'package:payhive/features/auth/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late RegisterUsecase registerUsecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    registerUsecase = RegisterUsecase(authRepository: mockAuthRepository);
  });

  const params = RegisterUsecaseParams(
    fullName: 'John Doe',
    phoneNumber: '9800000000',
    password: 'password123',
  );

  setUpAll(() {
    registerFallbackValue(
      const AuthEntity(
        fullName: 'fake',
        phoneNumber: '0000000000',
        password: 'fake',
      ),
    );
  });

  group('RegisterUsecase', () {
    test('should return true when registration is successful', () async {
      when(
        () => mockAuthRepository.register(any()),
      ).thenAnswer((_) async => const Right(true));

      final result = await registerUsecase(params);

      expect(result, const Right(true));

      verify(
        () => mockAuthRepository.register(
          AuthEntity(
            fullName: params.fullName,
            phoneNumber: params.phoneNumber,
            password: params.password,
          ),
        ),
      ).called(1);

      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Failure when registration fails', () async {
      const failure = ApiFalilure(message: 'User already exists');

      when(
        () => mockAuthRepository.register(any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await registerUsecase(params);
      expect(result, const Left(failure));

      verify(() => mockAuthRepository.register(any())).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return NetworkFailure when there is no internet', () async {
      const failure = NetworkFailure(message: 'No internet connection');

      when(
        () => mockAuthRepository.register(any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await registerUsecase(params);
      expect(result, const Left(failure));

      verify(() => mockAuthRepository.register(any())).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
