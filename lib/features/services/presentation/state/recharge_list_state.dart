import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';

enum RechargeListViewStatus { initial, loading, loaded, error }

class RechargeListState extends Equatable {
  static const Object _unset = Object();

  final RechargeListViewStatus status;
  final List<RechargeServiceEntity> services;
  final String provider;
  final String search;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  const RechargeListState({
    required this.status,
    required this.services,
    required this.provider,
    required this.search,
    this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
  });

  factory RechargeListState.initial() {
    return const RechargeListState(
      status: RechargeListViewStatus.initial,
      services: [],
      provider: '',
      search: '',
      errorMessage: null,
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
    );
  }

  bool get hasMore => page < totalPages;

  RechargeListState copyWith({
    RechargeListViewStatus? status,
    List<RechargeServiceEntity>? services,
    String? provider,
    String? search,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return RechargeListState(
      status: status ?? this.status,
      services: services ?? this.services,
      provider: provider ?? this.provider,
      search: search ?? this.search,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    services,
    provider,
    search,
    errorMessage,
    page,
    totalPages,
    isLoadingMore,
  ];
}
