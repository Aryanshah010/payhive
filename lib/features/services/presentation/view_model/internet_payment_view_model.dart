import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/domain/usecases/internet_usecases.dart';
import 'package:payhive/features/services/presentation/state/internet_payment_state.dart';
import 'package:uuid/uuid.dart';

final internetPaymentViewModelProvider =
    NotifierProvider<InternetPaymentViewModel, InternetPaymentState>(
      InternetPaymentViewModel.new,
    );

class InternetPaymentViewModel extends Notifier<InternetPaymentState> {
  late final PayInternetServiceUsecase _payInternetServiceUsecase;
  final Uuid _uuid = const Uuid();
  final Map<String, String> _idempotencyKeysByTarget = {};

  @override
  InternetPaymentState build() {
    _payInternetServiceUsecase = ref.read(payInternetServiceUsecaseProvider);
    return InternetPaymentState.initial();
  }

  void setService(InternetServiceEntity service) {
    final currentService = state.service;
    if (currentService != null && currentService.id == service.id) {
      state = state.copyWith(service: service);
      return;
    }

    state = state.copyWith(
      status: InternetPaymentViewStatus.loaded,
      action: InternetPaymentAction.none,
      service: service,
      customerId: '',
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  void setCustomerId(String value) {
    if (state.payLocked) return;

    final normalized = value.trim();
    if (normalized == state.customerId) return;

    state = state.copyWith(
      customerId: normalized,
      paymentResult: null,
      errorMessage: null,
      status: state.service == null
          ? InternetPaymentViewStatus.initial
          : InternetPaymentViewStatus.loaded,
      action: InternetPaymentAction.none,
      payLocked: false,
    );
  }

  Future<void> payService() async {
    if (state.status == InternetPaymentViewStatus.loading || state.payLocked) {
      return;
    }

    final service = state.service;
    if (service == null) {
      state = state.copyWith(
        status: InternetPaymentViewStatus.error,
        action: InternetPaymentAction.none,
        errorMessage: 'Service details are missing.',
      );
      return;
    }

    final customerId = state.customerId.trim();
    if (customerId.isEmpty) {
      state = state.copyWith(
        status: InternetPaymentViewStatus.error,
        action: InternetPaymentAction.none,
        errorMessage: 'Customer ID is required.',
      );
      return;
    }

    final targetKey = '${service.id}|$customerId';
    final idempotencyKey = _idempotencyKeysByTarget[targetKey] ?? _uuid.v4();
    _idempotencyKeysByTarget[targetKey] = idempotencyKey;

    state = state.copyWith(
      status: InternetPaymentViewStatus.loading,
      action: InternetPaymentAction.pay,
      customerId: customerId,
      errorMessage: null,
      payIdempotencyKey: idempotencyKey,
      payLocked: true,
    );

    final result = await _payInternetServiceUsecase(
      PayInternetServiceParams(
        serviceId: service.id,
        customerId: customerId,
        validationRegex: service.validationRegex,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: InternetPaymentViewStatus.error,
          action: InternetPaymentAction.none,
          errorMessage: failure.message,
          payIdempotencyKey: idempotencyKey,
          payLocked: false,
        );
      },
      (paymentResult) {
        state = state.copyWith(
          status: InternetPaymentViewStatus.loaded,
          action: InternetPaymentAction.none,
          paymentResult: paymentResult,
          errorMessage: null,
          payIdempotencyKey: idempotencyKey,
          payLocked: true,
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;

    state = state.copyWith(
      errorMessage: null,
      status: state.service == null
          ? InternetPaymentViewStatus.initial
          : InternetPaymentViewStatus.loaded,
      action: InternetPaymentAction.none,
    );
  }
}
