import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/usecases/upload_photo_usecase.dart';

class MockProfileRepository extends Mock implements IProfileRepository {}

class FakeFile extends Fake implements File {}

void main() {
  late UploadPhotoUsecase usecase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = UploadPhotoUsecase(repository: mockRepository);
  });

  group('UploadPhotoUsecase', () {
    test(
      'should return image url (String) when upload is successful',
      () async {
        final file = File('path/to/image.png');
        const imageUrl = 'https://example.com/uploads/image.png';

        when(
          () => mockRepository.uploadProfileImage(any()),
        ).thenAnswer((_) async => const Right(imageUrl));

        final result = await usecase(file);

        expect(result, const Right(imageUrl));
        verify(() => mockRepository.uploadProfileImage(file)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('should return Failure when repository returns failure', () async {
      final file = File('path/to/image.png');
      const failure = ApiFalilure(message: 'Upload failed');

      when(
        () => mockRepository.uploadProfileImage(any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await usecase(file);

      expect(result, const Left(failure));
      verify(() => mockRepository.uploadProfileImage(file)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when there is no internet', () async {
      final file = File('path/to/image.png');
      const failure = NetworkFailure(message: 'No internet');

      when(
        () => mockRepository.uploadProfileImage(any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await usecase(file);

      expect(result, const Left(failure));
      verify(() => mockRepository.uploadProfileImage(file)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass the correct File instance to repository', () async {
      
      final file = File('path/to/specific_image.png');
      File? captured;
      when(() => mockRepository.uploadProfileImage(any())).thenAnswer((
        invocation,
      ) async {
        captured = invocation.positionalArguments[0] as File;
        return const Right('ok');
      });

      await usecase(file);

      expect(captured, isNotNull);
      expect(captured?.path, 'path/to/specific_image.png');
      verify(() => mockRepository.uploadProfileImage(file)).called(1);
    });
  });
}
