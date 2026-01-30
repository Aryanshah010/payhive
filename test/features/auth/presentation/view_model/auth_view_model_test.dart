import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:payhive/features/auth/domain/usecases/login_usecase.dart';
import 'package:payhive/features/auth/domain/usecases/logout_usecase.dart';
import 'package:payhive/features/auth/domain/usecases/register_usecase.dart';
import 'package:payhive/features/auth/presentation/state/auth_state.dart';
import 'package:payhive/features/auth/presentation/view_model/auth_view_model.dart';

class MockRegisterUsecase extends Mock implements RegisterUsecase {}

class MockLoginUsecase extends Mock implements LoginUsecase {}

class MockLogoutUsecase extends Mock implements LogoutUsecase {}

void main() {
  late MockRegisterUsecase mockRegisterUsecase;
  late MockLoginUsecase mockLoginUsecase;
  late MockLogoutUsecase mockLogoutUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const RegisterUsecaseParams(
        fullName: 'fallback',
        phoneNumber: '0000000000',
        password: 'fallback',
      ),
    );

    registerFallbackValue(
      const LoginUsecaseParams(phoneNumber: '0000000000', password: 'fallback'),
    );

    registerFallbackValue(
      const AuthEntity(
        authId: 'fallback',
        fullName: 'fallback',
        phoneNumber: '0000000000',
        password: 'fallback',
      ),
    );
  });

  setUp(() {
    mockRegisterUsecase = MockRegisterUsecase();
    mockLoginUsecase = MockLoginUsecase();
    mockLogoutUsecase = MockLogoutUsecase();

    container = ProviderContainer(
      overrides: [
        registerUsecaseProvider.overrideWithValue(mockRegisterUsecase),
        loginUsecaseProvider.overrideWithValue(mockLoginUsecase),
        logoutUsecaseProvider.overrideWithValue(mockLogoutUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const tUser = AuthEntity(
    authId: '1',
    fullName: 'Test User',
    phoneNumber: '9800000000',
    password: 'Password123',
  );

  group('AuthViewModel', () {
    test('initial state when created', () {
      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    group('register', () {
      test(
        'should emit registered state when registration is successful',
        () async {
          when(
            () => mockRegisterUsecase(any()),
          ).thenAnswer((_) async => const Right(true));

          final viewModel = container.read(authViewModelProvider.notifier);

          await viewModel.register(
            fullName: 'Test User',
            phoneNumber: '9800000000',
            password: 'password123',
          );

          final state = container.read(authViewModelProvider);
          expect(state.status, AuthStatus.registered);
          verify(() => mockRegisterUsecase(any())).called(1);
        },
      );

      test('should emit error state when registration fails', () async {
        const failure = ApiFalilure(message: 'User already exists');
        when(
          () => mockRegisterUsecase(any()),
        ).thenAnswer((_) async => const Left(failure));

        final viewModel = container.read(authViewModelProvider.notifier);

        await viewModel.register(
          fullName: 'Test User',
          phoneNumber: '9800000000',
          password: 'password123',
        );

        final state = container.read(authViewModelProvider);
        expect(state.status, AuthStatus.error);
        expect(state.errorMessage, 'User already exists');
        verify(() => mockRegisterUsecase(any())).called(1);
      });

      test('should pass optional params correctly to usecase', () async {
        RegisterUsecaseParams? captured;
        when(() => mockRegisterUsecase(any())).thenAnswer((invocation) {
          captured = invocation.positionalArguments[0] as RegisterUsecaseParams;
          return Future.value(const Right(true));
        });

        final viewModel = container.read(authViewModelProvider.notifier);

        await viewModel.register(
          fullName: 'Test User',
          phoneNumber: '9800000000',
          password: 'password123',
        );

        expect(captured?.fullName, 'Test User');
        expect(captured?.phoneNumber, '9800000000');
      });
    });

    group('login', () {
      test(
        'should emit authenticated state with user when login is successful',
        () async {
          when(
            () => mockLoginUsecase(any()),
          ).thenAnswer((_) async => const Right(tUser));

          final viewModel = container.read(authViewModelProvider.notifier);

          await viewModel.login(
            phoneNumber: '9800000000',
            password: 'Password123',
          );

          final state = container.read(authViewModelProvider);
          expect(state.status, AuthStatus.authenticated);
          expect(state.user, tUser);
          verify(() => mockLoginUsecase(any())).called(1);
        },
      );

      test('should emit error state when login fails', () async {
        const failure = ApiFalilure(message: 'Invalid credentials');
        when(
          () => mockLoginUsecase(any()),
        ).thenAnswer((_) async => const Left(failure));

        final viewModel = container.read(authViewModelProvider.notifier);

        await viewModel.login(phoneNumber: '9800000000', password: 'wrong');

        final state = container.read(authViewModelProvider);
        expect(state.status, AuthStatus.error);
        expect(state.errorMessage, 'Invalid credentials');
        verify(() => mockLoginUsecase(any())).called(1);
      });

      test('should pass correct credentials to login usecase', () async {
        LoginUsecaseParams? captured;
        when(() => mockLoginUsecase(any())).thenAnswer((invocation) {
          captured = invocation.positionalArguments[0] as LoginUsecaseParams;
          return Future.value(const Right(tUser));
        });

        final viewModel = container.read(authViewModelProvider.notifier);

        await viewModel.login(
          phoneNumber: '9800000000',
          password: 'password123',
        );

        expect(captured?.phoneNumber, '9800000000');
        expect(captured?.password, 'password123');
      });
    });

    group('logout', () {
      test(
        'should emit unauthenticated state when logout successful',
        () async {
          when(
            () => mockLogoutUsecase(),
          ).thenAnswer((_) async => const Right(true));

          final viewModel = container.read(authViewModelProvider.notifier);
          await viewModel.logout();

          final state = container.read(authViewModelProvider);
          expect(state.status, AuthStatus.unauthenticated);
          expect(state.user, isNull);
          verify(() => mockLogoutUsecase()).called(1);
        },
      );

      test('should emit error state when logout fails', () async {
        const failure = ApiFalilure(message: 'Logout failed');
        when(
          () => mockLogoutUsecase(),
        ).thenAnswer((_) async => const Left(failure));

        final viewModel = container.read(authViewModelProvider.notifier);
        await viewModel.logout();

        final state = container.read(authViewModelProvider);
        expect(state.status, AuthStatus.error);
        expect(state.errorMessage, 'Logout failed');
        verify(() => mockLogoutUsecase()).called(1);
      });
    });
  });

  group('AuthState value semantics', () {
    test('AuthState initial values', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates specified fields', () {
      const state = AuthState();
      final newState = state.copyWith(
        status: AuthStatus.authenticated,
        user: tUser,
      );
      expect(newState.status, AuthStatus.authenticated);
      expect(newState.user, tUser);
      expect(newState.errorMessage, isNull);
    });

    test('props contains all fields', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        errorMessage: 'error',
      );
      expect(state.props, [AuthStatus.authenticated, tUser, 'error']);
    });

    test('two states with same values are equal', () {
      const s1 = AuthState(status: AuthStatus.authenticated, user: tUser);
      const s2 = AuthState(status: AuthStatus.authenticated, user: tUser);
      expect(s1, s2);
    });
  });
}
