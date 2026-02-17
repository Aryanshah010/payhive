import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';

enum FlightBookingsViewStatus { initial, loading, loaded, error }

enum FlightBookingFilter { all, created, paid, cancelled, refunded }

extension FlightBookingFilterX on FlightBookingFilter {
  String? get apiValue {
    switch (this) {
      case FlightBookingFilter.all:
        return null;
      case FlightBookingFilter.created:
        return 'created';
      case FlightBookingFilter.paid:
        return 'paid';
      case FlightBookingFilter.cancelled:
        return 'cancelled';
      case FlightBookingFilter.refunded:
        return 'refunded';
    }
  }

  String get label {
    switch (this) {
      case FlightBookingFilter.all:
        return 'All';
      case FlightBookingFilter.created:
        return 'Created';
      case FlightBookingFilter.paid:
        return 'Paid';
      case FlightBookingFilter.cancelled:
        return 'Cancelled';
      case FlightBookingFilter.refunded:
        return 'Refunded';
    }
  }
}

class FlightBookingsState extends Equatable {
  static const Object _unset = Object();

  final FlightBookingsViewStatus status;
  final List<FlightBookingItemEntity> bookings;
  final FlightBookingFilter filter;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final List<String> payingBookingIds;
  final String? lastPaidBookingId;

  const FlightBookingsState({
    required this.status,
    required this.bookings,
    required this.filter,
    this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
    required this.payingBookingIds,
    this.lastPaidBookingId,
  });

  factory FlightBookingsState.initial() {
    return const FlightBookingsState(
      status: FlightBookingsViewStatus.initial,
      bookings: [],
      filter: FlightBookingFilter.all,
      errorMessage: null,
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
      payingBookingIds: [],
      lastPaidBookingId: null,
    );
  }

  bool get hasMore => page < totalPages;

  bool isBookingPaying(String bookingId) {
    return payingBookingIds.contains(bookingId);
  }

  FlightBookingsState copyWith({
    FlightBookingsViewStatus? status,
    List<FlightBookingItemEntity>? bookings,
    FlightBookingFilter? filter,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    List<String>? payingBookingIds,
    Object? lastPaidBookingId = _unset,
  }) {
    return FlightBookingsState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      filter: filter ?? this.filter,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      payingBookingIds: payingBookingIds ?? this.payingBookingIds,
      lastPaidBookingId: lastPaidBookingId == _unset
          ? this.lastPaidBookingId
          : lastPaidBookingId as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bookings,
    filter,
    errorMessage,
    page,
    totalPages,
    isLoadingMore,
    payingBookingIds,
    lastPaidBookingId,
  ];
}
