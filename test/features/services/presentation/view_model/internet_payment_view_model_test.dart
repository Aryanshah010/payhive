import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/domain/usecases/internet_usecases.dart';
import 'package:payhive/features/services/presentation/state/internet_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/internet_payment_view_model.dart';

class MockPayInternetServiceUsecase extends Mock
    implements PayInternetServiceUsecase {}

void main() {
  late MockPayInternetServiceUsecase mockPayUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const PayInternetServiceParams(
        serviceId: 'service-1',
        customerId: 'ABCD1234',
      ),
    );
  });

  setUp(() {
    mockPayUsecase = MockPayInternetServiceUsecase();
    container = ProviderContainer(
      overrides: [
        payInternetServiceUsecaseProvider.overrideWithValue(mockPayUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  InternetServiceEntity makeService({
    String validationRegex = r'^[A-Z0-9]{6,16}$',
  }) {
    return InternetServiceEntity(
      id: 'service-1',
      type: 'internet',
      provider: 'Airtel Xstream',
      name: 'Fiber 100 Mbps',
      packageLabel: 'Monthly',
      amount: 999,
      validationRegex: validationRegex,
      isActive: true,
      meta: const {},
    );
  }

  PayInternetResultEntity makePayResult() {
    return PayInternetResultEntity(
      transactionId: 'txn-1',
      receipt: InternetPaymentReceiptEntity(
        receiptNo: 'RCP-1',
        serviceType: 'internet',
        serviceId: 'service-1',
        provider: 'Airtel Xstream',
        planName: 'Fiber 100 Mbps',
        customerIdMasked: 'AB****34',
        amount: 999,
        createdAt: DateTime(2026, 3, 10, 10, 30),
      ),
      idempotentReplay: false,
    );
  }

  group('InternetPaymentViewModel', () {
    test('pay success stores payment result', () async {
      when(
        () => mockPayUsecase(any()),
      ).thenAnswer((_) async => Right(makePayResult()));

      final vm = container.read(internetPaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setCustomerId('ABCD1234');
      await vm.payService();

      final state = container.read(internetPaymentViewModelProvider);
      expect(state.status, InternetPaymentViewStatus.loaded);
      expect(state.paymentResult?.transactionId, 'txn-1');
      expect(state.payLocked, isFalse);
    });

    test('invalid customer id fails local regex validation', () async {
      when(() => mockPayUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as PayInternetServiceParams;

        if (params.customerId == 'abc') {
          return const Left(
            ValidationFailure(
              message: 'Customer ID format is invalid for selected service',
            ),
          );
        }

        return Right(makePayResult());
      });

      final vm = container.read(internetPaymentViewModelProvider.notifier);
      vm.setService(makeService(validationRegex: r'^[A-Z0-9]{8}$'));
      vm.setCustomerId('abc');

      await vm.payService();
      final state = container.read(internetPaymentViewModelProvider);

      expect(state.status, InternetPaymentViewStatus.error);
      expect(state.errorMessage, contains('invalid'));
      verify(() => mockPayUsecase(any())).called(1);
    });

    test('duplicate pay taps are ignored while request is in-flight', () async {
      final vm = container.read(internetPaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setCustomerId('ABCD1234');

      final completer = Completer<Either<Failure, PayInternetResultEntity>>();
      when(() => mockPayUsecase(any())).thenAnswer((_) => completer.future);

      unawaited(vm.payService());
      unawaited(vm.payService());

      await Future<void>.delayed(const Duration(milliseconds: 10));
      verify(() => mockPayUsecase(any())).called(1);

      completer.complete(Right(makePayResult()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('pay failure retries with same idempotency key', () async {
      final vm = container.read(internetPaymentViewModelProvider.notifier);
      vm.setService(makeService());
      vm.setCustomerId('ABCD1234');

      final capturedKeys = <String?>[];
      var callCount = 0;

      when(() => mockPayUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as PayInternetServiceParams;
        capturedKeys.add(params.idempotencyKey);
        callCount++;

        if (callCount == 1) {
          return const Left(ApiFalilure(message: 'Payment failed'));
        }
        return Right(makePayResult());
      });

      await vm.payService();

      var state = container.read(internetPaymentViewModelProvider);
      expect(state.status, InternetPaymentViewStatus.error);
      expect(state.payLocked, isFalse);

      await vm.payService();
      state = container.read(internetPaymentViewModelProvider);

      expect(state.status, InternetPaymentViewStatus.loaded);
      expect(state.paymentResult, isNotNull);
      expect(capturedKeys.length, 2);
      expect(capturedKeys.first, isNotNull);
      expect(capturedKeys.first, capturedKeys.last);
    });
  });
}
