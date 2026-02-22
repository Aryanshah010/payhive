import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/send_money/domain/repositories/send_money_repositories.dart';
import 'package:payhive/features/send_money/domain/usecases/send_money_usecase.dart';
import 'package:payhive/features/send_money/presentation/state/bank_transfer_state.dart';
import 'package:payhive/features/send_money/presentation/view_model/bank_transfer_view_model.dart';

class MockSendMoneyRepository extends Mock implements ISendMoneyRepository {}

void main() {
  late MockSendMoneyRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockSendMoneyRepository();

    container = ProviderContainer(
      overrides: [
        previewBankTransferUsecaseProvider.overrideWith(
          (ref) => PreviewBankTransferUsecase(repository: mockRepository),
        ),
        confirmBankTransferUsecaseProvider.overrideWith(
          (ref) => ConfirmBankTransferUsecase(repository: mockRepository),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  PreviewEntity makePreview({String? warning}) {
    return PreviewEntity(
      recipient: const RecipientEntity(
        id: 'preview',
        fullName: 'Bank Beneficiary',
        phoneNumber: '',
      ),
      warning: warning,
    );
  }

  ReceiptEntity makeReceipt() {
    return ReceiptEntity(
      txId: 'txn-1',
      status: 'SUCCESS',
      amount: 500,
      remark: 'Transfer',
      paymentType: 'BANK_TRANSFER',
      meta: const {'bankName': 'Nabil Bank', 'accountNumber': '123456789012'},
      from: const RecipientEntity(
        id: 'user-1',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      to: const RecipientEntity(
        id: 'bank-beneficiary',
        fullName: 'Receiver',
        phoneNumber: '',
      ),
      createdAt: DateTime(2026, 1, 1, 10, 0),
      direction: 'DEBIT',
    );
  }

  void enterValidInputs(BankTransferViewModel viewModel) {
    viewModel.setBankName('Nabil Bank');
    viewModel.setAccountNumber('123456789012');
    viewModel.appendAmountKey('5');
    viewModel.appendAmountKey('0');
    viewModel.appendAmountKey('0');
  }

  group('BankTransferViewModel', () {
    test(
      'invalid bank name fails validation and skips repository call',
      () async {
        final vm = container.read(bankTransferViewModelProvider.notifier);
        vm.setBankName('N');
        vm.setAccountNumber('123456789012');
        vm.appendAmountKey('1');
        vm.appendAmountKey('0');

        await vm.previewTransfer();
        final state = container.read(bankTransferViewModelProvider);

        expect(state.status, BankTransferStatus.error);
        expect(state.errorMessage, contains('Bank name'));
        verifyNever(
          () => mockRepository.previewBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            remark: any(named: 'remark'),
          ),
        );
      },
    );

    test(
      'invalid account number and invalid pin fail validation without network call',
      () async {
        final vm = container.read(bankTransferViewModelProvider.notifier);
        vm.setBankName('Nabil Bank');
        vm.setAccountNumber('1234');
        vm.appendAmountKey('2');
        vm.appendAmountKey('0');

        await vm.previewTransfer();
        var state = container.read(bankTransferViewModelProvider);

        expect(state.status, BankTransferStatus.error);
        expect(state.errorMessage, contains('Account number'));
        verifyNever(
          () => mockRepository.previewBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            remark: any(named: 'remark'),
          ),
        );

        vm.resetFlow();
        enterValidInputs(vm);
        await vm.confirmTransfer('12');
        state = container.read(bankTransferViewModelProvider);

        expect(state.status, BankTransferStatus.error);
        expect(state.errorMessage, contains('PIN must be exactly 4 digits'));
        verifyNever(
          () => mockRepository.confirmBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            pin: any(named: 'pin'),
            remark: any(named: 'remark'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        );
      },
    );

    test('preview success updates preview state and warning', () async {
      when(
        () => mockRepository.previewBankTransfer(
          bankName: any(named: 'bankName'),
          accountNumber: any(named: 'accountNumber'),
          amount: any(named: 'amount'),
          remark: any(named: 'remark'),
        ),
      ).thenAnswer((_) async => Right(makePreview(warning: 'Large amount')));

      final vm = container.read(bankTransferViewModelProvider.notifier);
      enterValidInputs(vm);
      await vm.previewTransfer();

      final state = container.read(bankTransferViewModelProvider);
      expect(state.status, BankTransferStatus.previewSuccess);
      expect(state.action, BankTransferAction.none);
      expect(state.warning, 'Large amount');
      expect(state.confirmIdempotencyKey, isNotNull);
      expect(state.confirmLocked, isFalse);
      verify(
        () => mockRepository.previewBankTransfer(
          bankName: any(named: 'bankName'),
          accountNumber: any(named: 'accountNumber'),
          amount: any(named: 'amount'),
          remark: any(named: 'remark'),
        ),
      ).called(1);
    });

    test(
      'confirm success locks repeat submission and reuses idempotency key',
      () async {
        when(
          () => mockRepository.previewBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            remark: any(named: 'remark'),
          ),
        ).thenAnswer((_) async => Right(makePreview()));

        final capturedIdempotencyKeys = <String?>[];
        when(
          () => mockRepository.confirmBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            pin: any(named: 'pin'),
            remark: any(named: 'remark'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer((invocation) async {
          capturedIdempotencyKeys.add(
            invocation.namedArguments[#idempotencyKey] as String?,
          );
          return Right(makeReceipt());
        });

        final vm = container.read(bankTransferViewModelProvider.notifier);
        enterValidInputs(vm);
        await vm.previewTransfer();
        await vm.confirmTransfer('1234');
        await vm.confirmTransfer('1234');

        final state = container.read(bankTransferViewModelProvider);
        expect(state.status, BankTransferStatus.error);
        expect(state.errorMessage, contains('already submitted'));
        expect(state.confirmLocked, isTrue);
        expect(capturedIdempotencyKeys.length, 1);
        expect(capturedIdempotencyKeys.first, isNotNull);
        verify(
          () => mockRepository.confirmBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            pin: any(named: 'pin'),
            remark: any(named: 'remark'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).called(1);
      },
    );

    test(
      'handles 423 lockout by entering locked state and counting down',
      () async {
        when(
          () => mockRepository.confirmBankTransfer(
            bankName: any(named: 'bankName'),
            accountNumber: any(named: 'accountNumber'),
            amount: any(named: 'amount'),
            pin: any(named: 'pin'),
            remark: any(named: 'remark'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            PinLockoutFailure(
              message: 'Too many attempts',
              remainingMs: 2200,
              statusCode: 423,
            ),
          ),
        );

        final vm = container.read(bankTransferViewModelProvider.notifier);
        enterValidInputs(vm);
        await vm.confirmTransfer('1234');

        final lockedState = container.read(bankTransferViewModelProvider);
        expect(lockedState.status, BankTransferStatus.locked);
        expect(lockedState.lockoutRemainingMs, 2200);

        await Future<void>.delayed(const Duration(milliseconds: 1200));
        final tickingState = container.read(bankTransferViewModelProvider);
        expect(tickingState.lockoutRemainingMs, lessThan(2200));
      },
    );
  });
}
