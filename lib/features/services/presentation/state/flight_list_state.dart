import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';

enum FlightListViewStatus { initial, loading, loaded, error }

class FlightListState extends Equatable {
  static const Object _unset = Object();

  final FlightListViewStatus status;
  final List<FlightEntity> flights;
  final String from;
  final String to;
  final String date;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  const FlightListState({
    required this.status,
    required this.flights,
    required this.from,
    required this.to,
    required this.date,
    this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
  });

  factory FlightListState.initial() {
    return const FlightListState(
      status: FlightListViewStatus.initial,
      flights: [],
      from: '',
      to: '',
      date: '',
      errorMessage: null,
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
    );
  }

  bool get hasMore => page < totalPages;

  FlightListState copyWith({
    FlightListViewStatus? status,
    List<FlightEntity>? flights,
    String? from,
    String? to,
    String? date,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return FlightListState(
      status: status ?? this.status,
      flights: flights ?? this.flights,
      from: from ?? this.from,
      to: to ?? this.to,
      date: date ?? this.date,
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
    flights,
    from,
    to,
    date,
    errorMessage,
    page,
    totalPages,
    isLoadingMore,
  ];
}
