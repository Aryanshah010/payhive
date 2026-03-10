import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/repositories/request_money_repositories.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';

class MockRequestMoneyRepository extends Mock
    implements IRequestMoneyRepository {}

void main() {
  late MockRequestMoneyRepository mockRepository;
  late CreateMoneyRequestUsecase createUsecase;
  late GetOutgoingMoneyRequestsUsecase getOutgoingUsecase;
  late CancelMoneyRequestUsecase cancelUsecase;

  setUp(() {
    mockRepository = MockRequestMoneyRepository();
    createUsecase = CreateMoneyRequestUsecase(repository: mockRepository);
    getOutgoingUsecase = GetOutgoingMoneyRequestsUsecase(
      repository: mockRepository,
    );
    cancelUsecase = CancelMoneyRequestUsecase(repository: mockRepository);
  });

  MoneyRequestEntity sampleRequest() {
    return MoneyRequestEntity(
      id: 'req-1',
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
      amount: 125,
      remark: 'Rent',
      status: 'PENDING',
      expiresAt: DateTime(2026, 1, 15),
      respondedAt: null,
      transactionId: null,
      createdAt: DateTime(2026, 1, 8),
      updatedAt: DateTime(2026, 1, 8),
    );
  }

  group('CreateMoneyRequestUsecase', () {
    test('returns validation failure when phone number is invalid', () async {
      final result = await createUsecase(
        const CreateMoneyRequestParams(toPhoneNumber: '9800', amount: 100),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure,
          const ValidationFailure(
            message: 'Phone number must be exactly 10 digits.',
          ),
        ),
        (_) => fail('Expected validation failure'),
      );
    });

    test(
      'returns validation failure when amount has more than 2 decimals',
      () async {
        final result = await createUsecase(
          const CreateMoneyRequestParams(
            toPhoneNumber: '9800000001',
            amount: 100.123,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            const ValidationFailure(
              message: 'Amount can have at most 2 decimal places.',
            ),
          ),
          (_) => fail('Expected validation failure'),
        );
      },
    );

    test('returns validation failure when remark exceeds 140 chars', () async {
      final longRemark = 'a' * 141;

      final result = await createUsecase(
        CreateMoneyRequestParams(
          toPhoneNumber: '9800000001',
          amount: 100,
          remark: longRemark,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure,
          const ValidationFailure(
            message: 'Request message must be at most 140 characters.',
          ),
        ),
        (_) => fail('Expected validation failure'),
      );
    });

    test('valid payload calls repository with normalized values', () async {
      when(
        () => mockRepository.createRequest(
          toPhoneNumber: any(named: 'toPhoneNumber'),
          amount: any(named: 'amount'),
          remark: any(named: 'remark'),
        ),
      ).thenAnswer((_) async => Right(sampleRequest()));

      final result = await createUsecase(
        const CreateMoneyRequestParams(
          toPhoneNumber: '9800000001',
          amount: 100.5,
          remark: '  monthly rent  ',
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.createRequest(
          toPhoneNumber: '9800000001',
          amount: 100.50,
          remark: 'monthly rent',
        ),
      ).called(1);
    });
  });

  group('GetOutgoingMoneyRequestsUsecase', () {
    test('returns validation failure when page is invalid', () async {
      final result = await getOutgoingUsecase(
        const GetOutgoingMoneyRequestsParams(page: 0, limit: 10),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure,
          const ValidationFailure(message: 'Page must be at least 1.'),
        ),
        (_) => fail('Expected validation failure'),
      );
    });
  });

  group('CancelMoneyRequestUsecase', () {
    test('returns validation failure when requestId is empty', () async {
      final result = await cancelUsecase(
        const CancelMoneyRequestParams(requestId: '   '),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure,
          const ValidationFailure(message: 'Request ID is required.'),
        ),
        (_) => fail('Expected validation failure'),
      );
    });
  });
}
