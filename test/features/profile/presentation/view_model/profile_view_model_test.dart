import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';
import 'package:payhive/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:payhive/features/profile/domain/usecases/upload_photo_usecase.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class MockGetProfileUsecase extends Mock implements GetProfileUsecase {}

class MockUploadPhotoUsecase extends Mock implements UploadPhotoUsecase {}

void main() {
  late MockGetProfileUsecase mockGetProfileUsecase;
  late MockUploadPhotoUsecase mockUploadPhotoUsecase;
  late ProviderContainer container;

  setUp(() {
    mockGetProfileUsecase = MockGetProfileUsecase();
    mockUploadPhotoUsecase = MockUploadPhotoUsecase();

    container = ProviderContainer(
      overrides: [
        getProfileUsecaseProvider.overrideWithValue(mockGetProfileUsecase),
        uploadPhotoUsecaseProvider.overrideWithValue(mockUploadPhotoUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProfileViewModel', () {
    test('loadProfile sets loaded state with balance', () async {
      const profile = ProfileEntity(
        id: 'user-1',
        fullName: 'Aryan Shah',
        phoneNumber: '9800000000',
        email: 'aryan@payhive.com',
        imageUrl: '/uploads/me.jpg',
        hasPin: true,
        balance: 3200.50,
      );

      when(
        () => mockGetProfileUsecase(),
      ).thenAnswer((_) async => const Right(profile));

      await container.read(profileViewModelProvider.notifier).loadProfile();

      final state = container.read(profileViewModelProvider);
      expect(state.status, ProfileStatus.loaded);
      expect(state.fullName, 'Aryan Shah');
      expect(state.balance, 3200.50);
      expect(state.hasPin, isTrue);
    });

    test('refreshProfile updates balance to latest profile value', () async {
      var callCount = 0;

      when(() => mockGetProfileUsecase()).thenAnswer((_) async {
        callCount++;
        final balance = callCount == 1 ? 1000.00 : 1550.25;
        return Right(
          ProfileEntity(
            id: 'user-1',
            fullName: 'Aryan Shah',
            phoneNumber: '9800000000',
            email: 'aryan@payhive.com',
            imageUrl: '/uploads/me.jpg',
            hasPin: true,
            balance: balance,
          ),
        );
      });

      final notifier = container.read(profileViewModelProvider.notifier);
      await notifier.loadProfile();
      await notifier.refreshProfile();

      final state = container.read(profileViewModelProvider);
      expect(state.status, ProfileStatus.loaded);
      expect(state.balance, 1550.25);
    });

    test('loadProfile sets error state when usecase fails', () async {
      const failure = ApiFalilure(message: 'Unable to fetch profile');
      when(
        () => mockGetProfileUsecase(),
      ).thenAnswer((_) async => const Left(failure));

      await container.read(profileViewModelProvider.notifier).loadProfile();

      final state = container.read(profileViewModelProvider);
      expect(state.status, ProfileStatus.error);
      expect(state.errorMessage, 'Unable to fetch profile');
    });
  });
}
