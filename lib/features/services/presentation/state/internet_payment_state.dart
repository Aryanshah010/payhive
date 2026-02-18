import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';

enum InternetPaymentViewStatus { initial, loading, loaded, error }

enum InternetPaymentAction { none, pay }

class InternetPaymentState extends Equatable {
  static const Object _unset = Object();

  final InternetPaymentViewStatus status;
  final InternetPaymentAction action;
  final InternetServiceEntity? service;
  final String customerId;
  final PayInternetResultEntity? paymentResult;
  final String? errorMessage;
  final String? payIdempotencyKey;
  final bool payLocked;

  const InternetPaymentState({
    required this.status,
    required this.action,
    this.service,
    required this.customerId,
    this.paymentResult,
    this.errorMessage,
    this.payIdempotencyKey,
    required this.payLocked,
  });

  factory InternetPaymentState.initial() {
    return const InternetPaymentState(
      status: InternetPaymentViewStatus.initial,
      action: InternetPaymentAction.none,
      customerId: '',
      payLocked: false,
    );
  }

  InternetPaymentState copyWith({
    InternetPaymentViewStatus? status,
    InternetPaymentAction? action,
    Object? service = _unset,
    String? customerId,
    Object? paymentResult = _unset,
    Object? errorMessage = _unset,
    Object? payIdempotencyKey = _unset,
    bool? payLocked,
  }) {
    return InternetPaymentState(
      status: status ?? this.status,
      action: action ?? this.action,
      service: service == _unset
          ? this.service
          : service as InternetServiceEntity?,
      customerId: customerId ?? this.customerId,
      paymentResult: paymentResult == _unset
          ? this.paymentResult
          : paymentResult as PayInternetResultEntity?,
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
    customerId,
    paymentResult,
    errorMessage,
    payIdempotencyKey,
    payLocked,
  ];
}
