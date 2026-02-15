import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/core/services/hive/hive_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/profile/data/datasources/profile_datasource.dart';
import 'package:payhive/features/profile/data/models/profile_api_model.dart';
import 'package:payhive/features/profile/data/models/profile_hive_model.dart';
import 'package:payhive/features/profile/data/repositories/profile_repository.dart';

class MockNetworkInfo extends Mock implements INetworkInfo {}

class MockProfileRemoteDataSource extends Mock
    implements IProfileRemoteDataSource {}

class MockHiveService extends Mock implements HiveService {}

class MockUserSessionService extends Mock implements UserSessionService {}

void main() {
  late MockNetworkInfo networkInfo;
  late MockProfileRemoteDataSource remoteDataSource;
  late MockHiveService hiveService;
  late MockUserSessionService userSessionService;
  late ProfileRepository repository;

  final fallbackHiveProfile = ProfileHiveModel(
    userId: 'fallback-user',
    fullName: 'Fallback',
    phoneNumber: '9800000000',
    email: 'fallback@payhive.com',
    imageUrl: null,
    balance: 0,
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(fallbackHiveProfile);
  });

  setUp(() {
    networkInfo = MockNetworkInfo();
    remoteDataSource = MockProfileRemoteDataSource();
    hiveService = MockHiveService();
    userSessionService = MockUserSessionService();

    repository = ProfileRepository(
      networkInfo: networkInfo,
      profileRemoteDatasource: remoteDataSource,
      hiveService: hiveService,
      userSessionService: userSessionService,
    );
  });

  group('ProfileRepository.getProfile', () {
    test('returns remote profile and caches it when online', () async {
      final remoteModel = ProfileApiModel(
        id: 'user-1',
        fullName: 'Aryan Shah',
        phoneNumber: '9800000000',
        email: 'aryan@payhive.com',
        imageUrl: '/uploads/pic.jpg',
        hasPin: true,
        balance: 2500.50,
      );

      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remoteDataSource.getProfile(),
      ).thenAnswer((_) async => remoteModel);
      when(() => hiveService.saveProfile(any())).thenAnswer((_) async {});

      final result = await repository.getProfile();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right(ProfileEntity)'), (profile) {
        expect(profile.id, 'user-1');
        expect(profile.balance, 2500.50);
      });

      final captured =
          verify(() => hiveService.saveProfile(captureAny())).captured.single
              as ProfileHiveModel;
      expect(captured.userId, 'user-1');
      expect(captured.balance, 2500.50);
      verify(() => remoteDataSource.getProfile()).called(1);
    });

    test('returns cached profile when remote fails', () async {
      final cached = ProfileHiveModel(
        userId: 'user-1',
        fullName: 'Cached User',
        phoneNumber: '9800111111',
        email: 'cached@payhive.com',
        imageUrl: '/uploads/cached.jpg',
        balance: 777.70,
        updatedAt: DateTime(2026, 1, 1),
      );

      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remoteDataSource.getProfile(),
      ).thenThrow(Exception('server down'));
      when(() => userSessionService.getUserId()).thenReturn('user-1');
      when(
        () => hiveService.getProfileByUserId('user-1'),
      ).thenAnswer((_) async => cached);

      final result = await repository.getProfile();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected cached profile'), (profile) {
        expect(profile.fullName, 'Cached User');
        expect(profile.balance, 777.70);
      });
    });

    test(
      'returns no internet failure when offline and cache is missing',
      () async {
        when(() => networkInfo.isConnected).thenAnswer((_) async => false);
        when(() => userSessionService.getUserId()).thenReturn('user-1');
        when(
          () => hiveService.getProfileByUserId('user-1'),
        ).thenAnswer((_) async => null);

        final result = await repository.getProfile();

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ApiFalilure>());
          expect(failure.message, 'No Internet connection');
        }, (_) => fail('Expected Left(Failure)'));
      },
    );

    test(
      'returns no active session failure when offline and no user id',
      () async {
        when(() => networkInfo.isConnected).thenAnswer((_) async => false);
        when(() => userSessionService.getUserId()).thenReturn(null);

        final result = await repository.getProfile();

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ApiFalilure>());
          expect(failure.message, 'No active user session');
        }, (_) => fail('Expected Left(Failure)'));
      },
    );
  });

  group('ProfileRepository.uploadProfileImage', () {
    test('returns no internet failure when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.uploadProfileImage(File(''));

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ApiFalilure>());
        expect(failure.message, 'No Internet connection');
      }, (_) => fail('Expected Left(Failure)'));
    });
  });
}
