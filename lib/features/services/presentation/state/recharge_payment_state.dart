import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';

enum RechargePaymentViewStatus { initial, loading, loaded, error }

enum RechargePaymentAction { none, pay }

class RechargePaymentState extends Equatable {
  static const Object _unset = Object();

  final RechargePaymentViewStatus status;
  final RechargePaymentAction action;
  final RechargeServiceEntity? service;
  final String phoneNumber;
  final PayRechargeResultEntity? paymentResult;
  final String? errorMessage;
  final String? payIdempotencyKey;
  final bool payLocked;

  const RechargePaymentState({
    required this.status,
    required this.action,
    this.service,
    required this.phoneNumber,
    this.paymentResult,
    this.errorMessage,
    this.payIdempotencyKey,
    required this.payLocked,
  });

  factory RechargePaymentState.initial() {
    return const RechargePaymentState(
      status: RechargePaymentViewStatus.initial,
      action: RechargePaymentAction.none,
      phoneNumber: '',
      payLocked: false,
    );
  }

  RechargePaymentState copyWith({
    RechargePaymentViewStatus? status,
    RechargePaymentAction? action,
    Object? service = _unset,
    String? phoneNumber,
    Object? paymentResult = _unset,
    Object? errorMessage = _unset,
    Object? payIdempotencyKey = _unset,
    bool? payLocked,
  }) {
    return RechargePaymentState(
      status: status ?? this.status,
      action: action ?? this.action,
      service: service == _unset
          ? this.service
          : service as RechargeServiceEntity?,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paymentResult: paymentResult == _unset
          ? this.paymentResult
          : paymentResult as PayRechargeResultEntity?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      payIdempotencyKey: payIdempotencyKey == _unset
          ? this.payIdempotencyKey
          : payIdempotencyKey as String?,
      payLocked: payLocked ?? this.payLocked,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    service,
    phoneNumber,
    paymentResult,
    errorMessage,
    payIdempotencyKey,
    payLocked,
  ];
}
