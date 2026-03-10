import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/view_model/request_money_info_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetMoneyRequestDetailUsecase extends Mock
    implements GetMoneyRequestDetailUsecase {}

class MockRespondMoneyRequestUsecase extends Mock
    implements RespondMoneyRequestUsecase {}

void main() {
  late MockGetMoneyRequestDetailUsecase mockGetDetailUsecase;
  late MockRespondMoneyRequestUsecase mockRespondUsecase;
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(const GetMoneyRequestDetailParams(requestId: 'mr-1'));
    registerFallbackValue(
      const RespondMoneyRequestParams(
        requestId: 'mr-1',
        action: MoneyRequestAction.reject,
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_phone_number': '9800000002'});
    prefs = await SharedPreferences.getInstance();

    mockGetDetailUsecase = MockGetMoneyRequestDetailUsecase();
    mockRespondUsecase = MockRespondMoneyRequestUsecase();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        getMoneyRequestDetailUsecaseProvider.overrideWithValue(
          mockGetDetailUsecase,
        ),
        respondMoneyRequestUsecaseProvider.overrideWithValue(
          mockRespondUsecase,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  MoneyRequestEntity request({required String status}) {
    return MoneyRequestEntity(
      id: 'mr-1',
      requester: const RecipientEntity(
        id: 'requester',
        fullName: 'Requester',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'receiver',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 150,
      remark: 'Lunch',
      status: status,
      expiresAt: DateTime(2026, 1, 20),
      respondedAt: status == 'PENDING' ? null : DateTime(2026, 1, 2),
      transactionId: null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  test('fetch detail success enables actions for pending receiver', () async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'PENDING')));

    await container
        .read(requestMoneyInfoViewModelProvider.notifier)
        .initialize(requestId: 'mr-1');

    final state = container.read(requestMoneyInfoViewModelProvider);
    expect(state.request?.status, 'PENDING');
    expect(state.canTakeAction, isTrue);
  });

  test('non pending request is read-only', () async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'CANCELED')));

    await container
        .read(requestMoneyInfoViewModelProvider.notifier)
        .initialize(requestId: 'mr-1');

    final state = container.read(requestMoneyInfoViewModelProvider);
    expect(state.canTakeAction, isFalse);
    expect(state.isReadOnly, isTrue);
  });

  test('reject success refreshes request and disables actions', () async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'PENDING')));
    when(
      () => mockRespondUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'REJECTED')));

    final vm = container.read(requestMoneyInfoViewModelProvider.notifier);
    await vm.initialize(requestId: 'mr-1');
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'REJECTED')));

    await vm.rejectRequest();

    final state = container.read(requestMoneyInfoViewModelProvider);
    expect(state.request?.status, 'REJECTED');
    expect(state.canTakeAction, isFalse);
    verify(
      () => mockRespondUsecase(
        const RespondMoneyRequestParams(
          requestId: 'mr-1',
          action: MoneyRequestAction.reject,
        ),
      ),
    ).called(1);
  });

  test('reject failure refreshes and returns read-only state', () async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'PENDING')));
    when(() => mockRespondUsecase(any())).thenAnswer(
      (_) async => const Left(ApiFalilure(message: 'Already canceled')),
    );

    final vm = container.read(requestMoneyInfoViewModelProvider.notifier);
    await vm.initialize(requestId: 'mr-1');
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'CANCELED')));

    await vm.rejectRequest();

    final state = container.read(requestMoneyInfoViewModelProvider);
    expect(state.request?.status, 'CANCELED');
    expect(state.canTakeAction, isFalse);
  });
}
