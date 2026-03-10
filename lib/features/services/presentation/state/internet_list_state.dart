import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';

enum InternetListViewStatus { initial, loading, loaded, error }

class InternetListState extends Equatable {
  static const Object _unset = Object();

  final InternetListViewStatus status;
  final List<InternetServiceEntity> services;
  final String provider;
  final String search;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  const InternetListState({
    required this.status,
    required this.services,
    required this.provider,
    required this.search,
    this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
  });

  factory InternetListState.initial() {
    return const InternetListState(
      status: InternetListViewStatus.initial,
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

  InternetListState copyWith({
    InternetListViewStatus? status,
    List<InternetServiceEntity>? services,
    String? provider,
    String? search,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return InternetListState(
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
