import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/usecases/get_profile_usecase.dart';

class MockProfileRepository extends Mock implements IProfileRepository {}

void main() {
  late GetProfileUsecase usecase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = GetProfileUsecase(repository: mockRepository);
  });

  group('GetProfileUsecase', () {
    const tProfile = ProfileEntity(
      id: '1',
      fullName: 'John Doe',
      phoneNumber: '9800000000',
      imageUrl: 'https://example.com/profile.jpg',
    );

    test('should return ProfileEntity when repository returns data', () async {
      when(
        () => mockRepository.getProfile(),
      ).thenAnswer((_) async => const Right(tProfile));

      final result = await usecase();

      expect(result, const Right(tProfile));
      verify(() => mockRepository.getProfile()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Failure when repository returns failure', () async {
      const failure = ApiFalilure(message: 'Server error');
      when(
        () => mockRepository.getProfile(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await usecase();

      expect(result, const Left(failure));
      verify(() => mockRepository.getProfile()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
