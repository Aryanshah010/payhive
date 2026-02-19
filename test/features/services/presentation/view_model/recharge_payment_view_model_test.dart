import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/domain/usecases/recharge_usecases.dart';
import 'package:payhive/features/services/presentation/state/recharge_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_payment_view_model.dart';

class MockPayRechargeServiceUsecase extends Mock
    implements PayRechargeServiceUsecase {}

void main() {
  late MockPayRechargeServiceUsecase mockPayUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const PayRechargeServiceParams(
        serviceId: 'service-1',
        phoneNumber: '9812345678',
      ),
    );
  });

  setUp(() {
    mockPayUsecase = MockPayRechargeServiceUsecase();
    container = ProviderContainer(
      overrides: [
        payRechargeServiceUsecaseProvider.overrideWithValue(mockPayUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  RechargeServiceEntity makeService() {
    return RechargeServiceEntity(
      id: 'service-1',
      type: 'topup',
      provider: 'NTC',
      name: 'Data Pack',
      packageLabel: '2GB Daily',
      amount: 299,
      validationRegex: r'^\d{10}$',
      isActive: true,
      meta: const {},
    );
  }

  PayRechargeResultEntity makePayResult() {
    return PayRechargeResultEntity(
      transactionId: 'txn-1',
      receipt: RechargePaymentReceiptEntity(
        receiptNo: 'RCP-1',
        serviceType: 'topup',
        serviceId: 'service-1',
        carrier: 'NTC',
        packageLabel: '2GB Daily',
        phoneMasked: '98******78',
        amount: 299,
        createdAt: DateTime(2026, 3, 10, 10, 30),
      ),
      idempotentReplay: false,
    );
  }

  group('RechargePaymentViewModel', () {
    test('pay success stores payment result', () async {
      when(
        () => mockPayUsecase(any()),
      ).thenAnswer((_) async => Right(makePayResult()));

      final vm = container.read(rechargePaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setPhoneNumber('9812345678');
      await vm.payService();

      final state = container.read(rechargePaymentViewModelProvider);
      expect(state.status, RechargePaymentViewStatus.loaded);
      expect(state.paymentResult?.transactionId, 'txn-1');
      expect(state.payLocked, isTrue);
    });

    test('invalid phone fails local validation', () async {
      when(() => mockPayUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as PayRechargeServiceParams;

        if (params.phoneNumber == '98123') {
          return const Left(
            ValidationFailure(
              message: 'Phone number must be exactly 10 digits',
            ),
          );
        }

        return Right(makePayResult());
      });

      final vm = container.read(rechargePaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setPhoneNumber('98123');

      await vm.payService();
      final state = container.read(rechargePaymentViewModelProvider);

      expect(state.status, RechargePaymentViewStatus.error);
      expect(state.errorMessage, contains('10 digits'));
      verify(() => mockPayUsecase(any())).called(1);
    });

    test('duplicate pay taps are ignored while request is in-flight', () async {
      final vm = container.read(rechargePaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setPhoneNumber('9812345678');

      final completer = Completer<Either<Failure, PayRechargeResultEntity>>();
      when(() => mockPayUsecase(any())).thenAnswer((_) => completer.future);

      unawaited(vm.payService());
      unawaited(vm.payService());

      await Future<void>.delayed(const Duration(milliseconds: 10));
      verify(() => mockPayUsecase(any())).called(1);

      completer.complete(Right(makePayResult()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('repeat pay is ignored after successful payment lock', () async {
      when(
        () => mockPayUsecase(any()),
      ).thenAnswer((_) async => Right(makePayResult()));

      final vm = container.read(rechargePaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setPhoneNumber('9812345678');

      await vm.payService();
      await vm.payService();

      final state = container.read(rechargePaymentViewModelProvider);
      expect(state.status, RechargePaymentViewStatus.loaded);
      expect(state.payLocked, isTrue);
      verify(() => mockPayUsecase(any())).called(1);
    });

    test('pay failure retries with same idempotency key', () async {
      final vm = container.read(rechargePaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setPhoneNumber('9812345678');

      final capturedKeys = <String?>[];
      var callCount = 0;

      when(() => mockPayUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as PayRechargeServiceParams;
        capturedKeys.add(params.idempotencyKey);
        callCount++;

        if (callCount == 1) {
          return const Left(ApiFalilure(message: 'Payment failed'));
        }
        return Right(makePayResult());
      });

      await vm.payService();

      var state = container.read(rechargePaymentViewModelProvider);
      expect(state.status, RechargePaymentViewStatus.error);
      expect(state.payLocked, isFalse);

      await vm.payService();
      state = container.read(rechargePaymentViewModelProvider);

      expect(state.status, RechargePaymentViewStatus.loaded);
      expect(state.paymentResult, isNotNull);
      expect(capturedKeys.length, 2);
      expect(capturedKeys.first, isNotNull);
      expect(capturedKeys.first, capturedKeys.last);
    });
  });
}
