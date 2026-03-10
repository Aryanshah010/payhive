import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/features/send_money/domain/usecases/send_money_usecase.dart';
import 'package:payhive/features/send_money/presentation/view_model/send_money_view_model.dart';

class MockPreviewTransferUsecase extends Mock
    implements PreviewTransferUsecase {}

class MockConfirmTransferUsecase extends Mock
    implements ConfirmTransferUsecase {}

class MockLookupBeneficiaryUsecase extends Mock
    implements LookupBeneficiaryUsecase {}

void main() {
  late MockPreviewTransferUsecase mockPreviewUsecase;
  late MockConfirmTransferUsecase mockConfirmUsecase;
  late MockLookupBeneficiaryUsecase mockLookupUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const PreviewTransferParams(toPhoneNumber: '9800000001', amount: 100),
    );
    registerFallbackValue(
      const ConfirmTransferParams(
        toPhoneNumber: '9800000001',
        amount: 100,
        pin: '1234',
      ),
    );
    registerFallbackValue(
      const LookupBeneficiaryParams(phoneNumber: '9800000001'),
    );
  });

  setUp(() {
    mockPreviewUsecase = MockPreviewTransferUsecase();
    mockConfirmUsecase = MockConfirmTransferUsecase();
    mockLookupUsecase = MockLookupBeneficiaryUsecase();

    container = ProviderContainer(
      overrides: [
        previewTransferUsecaseProvider.overrideWithValue(mockPreviewUsecase),
        confirmTransferUsecaseProvider.overrideWithValue(mockConfirmUsecase),
        lookupBeneficiaryUsecaseProvider.overrideWithValue(mockLookupUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('previewTransfer forwards moneyRequestId', () async {
    when(() => mockPreviewUsecase(any())).thenAnswer(
      (_) async => const Right(
        PreviewEntity(
          recipient: RecipientEntity(
            id: 'receiver',
            fullName: 'Receiver',
            phoneNumber: '9800000001',
          ),
        ),
      ),
    );

    final vm = container.read(sendMoneyViewModelProvider.notifier);
    vm.setPhoneNumber('9800000001');
    vm.setAmountInput('150');
    vm.setSourceMoneyRequestId('mr-9');

    await vm.previewTransfer();

    final captured =
        verify(() => mockPreviewUsecase(captureAny())).captured.single
            as PreviewTransferParams;

    expect(captured.moneyRequestId, 'mr-9');
  });

  test('confirmTransfer forwards moneyRequestId', () async {
    when(() => mockConfirmUsecase(any())).thenAnswer(
      (_) async => Right(
        ReceiptEntity(
          txId: 'tx-1',
          status: 'SUCCESS',
          amount: 150,
          remark: 'Rent',
          from: const RecipientEntity(
            id: 'sender',
            fullName: 'Sender',
            phoneNumber: '9800000002',
          ),
          to: const RecipientEntity(
            id: 'receiver',
            fullName: 'Receiver',
            phoneNumber: '9800000001',
          ),
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    final vm = container.read(sendMoneyViewModelProvider.notifier);
    vm.setPhoneNumber('9800000001');
    vm.setAmountInput('150');
    vm.setSourceMoneyRequestId('mr-9');

    await vm.confirmTransfer('1234');

    final captured =
        verify(() => mockConfirmUsecase(captureAny())).captured.single
            as ConfirmTransferParams;

    expect(captured.moneyRequestId, 'mr-9');
  });
}
