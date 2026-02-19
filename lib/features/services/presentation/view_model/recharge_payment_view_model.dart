import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/domain/usecases/recharge_usecases.dart';
import 'package:payhive/features/services/presentation/state/recharge_payment_state.dart';
import 'package:uuid/uuid.dart';

final rechargePaymentViewModelProvider =
    NotifierProvider<RechargePaymentViewModel, RechargePaymentState>(
      RechargePaymentViewModel.new,
    );

class RechargePaymentViewModel extends Notifier<RechargePaymentState> {
  late final PayRechargeServiceUsecase _payRechargeServiceUsecase;
  final Uuid _uuid = const Uuid();
  final Map<String, String> _idempotencyKeysByTarget = {};

  @override
  RechargePaymentState build() {
    _payRechargeServiceUsecase = ref.read(payRechargeServiceUsecaseProvider);
    return RechargePaymentState.initial();
  }

  void setService(RechargeServiceEntity service) {
    final currentService = state.service;
    if (currentService != null && currentService.id == service.id) {
      state = state.copyWith(service: service);
      return;
    }

    state = state.copyWith(
      status: RechargePaymentViewStatus.loaded,
      action: RechargePaymentAction.none,
      service: service,
      phoneNumber: '',
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  void setPhoneNumber(String value) {
    if (state.payLocked) return;

    final normalized = value.trim();
    if (normalized == state.phoneNumber) return;

    state = state.copyWith(
      phoneNumber: normalized,
      paymentResult: null,
      errorMessage: null,
      status: state.service == null
          ? RechargePaymentViewStatus.initial
          : RechargePaymentViewStatus.loaded,
      action: RechargePaymentAction.none,
      payLocked: false,
    );
  }

  Future<void> payService() async {
    if (state.status == RechargePaymentViewStatus.loading || state.payLocked) {
      return;
    }

    final service = state.service;
    if (service == null) {
      state = state.copyWith(
        status: RechargePaymentViewStatus.error,
        action: RechargePaymentAction.none,
        errorMessage: 'Service details are missing.',
      );
      return;
    }

    final phoneNumber = state.phoneNumber.trim();
    if (phoneNumber.isEmpty) {
      state = state.copyWith(
        status: RechargePaymentViewStatus.error,
        action: RechargePaymentAction.none,
        errorMessage: 'Phone number is required.',
      );
      return;
    }

    final targetKey = '${service.id}|$phoneNumber';
    final idempotencyKey = _idempotencyKeysByTarget[targetKey] ?? _uuid.v4();
    _idempotencyKeysByTarget[targetKey] = idempotencyKey;

    state = state.copyWith(
      status: RechargePaymentViewStatus.loading,
      action: RechargePaymentAction.pay,
      phoneNumber: phoneNumber,
      errorMessage: null,
      payIdempotencyKey: idempotencyKey,
      payLocked: true,
    );

    final result = await _payRechargeServiceUsecase(
      PayRechargeServiceParams(
        serviceId: service.id,
        phoneNumber: phoneNumber,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: RechargePaymentViewStatus.error,
          action: RechargePaymentAction.none,
          errorMessage: failure.message,
          payIdempotencyKey: idempotencyKey,
          payLocked: false,
        );
      },
      (paymentResult) {
        state = state.copyWith(
          status: RechargePaymentViewStatus.loaded,
          action: RechargePaymentAction.none,
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
          ? RechargePaymentViewStatus.initial
          : RechargePaymentViewStatus.loaded,
      action: RechargePaymentAction.none,
    );
  }
}
