import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';

enum HotelBookingsViewStatus { initial, loading, loaded, error }

enum HotelBookingFilter { all, created, paid, cancelled, refunded }

extension HotelBookingFilterX on HotelBookingFilter {
  String? get apiValue {
    switch (this) {
      case HotelBookingFilter.all:
        return null;
      case HotelBookingFilter.created:
        return 'created';
      case HotelBookingFilter.paid:
        return 'paid';
      case HotelBookingFilter.cancelled:
        return 'cancelled';
      case HotelBookingFilter.refunded:
        return 'refunded';
    }
  }

  String get label {
    switch (this) {
      case HotelBookingFilter.all:
        return 'All';
      case HotelBookingFilter.created:
        return 'Created';
      case HotelBookingFilter.paid:
        return 'Paid';
      case HotelBookingFilter.cancelled:
        return 'Cancelled';
      case HotelBookingFilter.refunded:
        return 'Refunded';
    }
  }
}

class HotelBookingsState extends Equatable {
  static const Object _unset = Object();

  final HotelBookingsViewStatus status;
  final List<HotelBookingItemEntity> bookings;
  final HotelBookingFilter filter;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final List<String> payingBookingIds;
  final String? lastPaidBookingId;

  const HotelBookingsState({
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

  factory HotelBookingsState.initial() {
    return const HotelBookingsState(
      status: HotelBookingsViewStatus.initial,
      bookings: [],
      filter: HotelBookingFilter.all,
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

  HotelBookingsState copyWith({
    HotelBookingsViewStatus? status,
    List<HotelBookingItemEntity>? bookings,
    HotelBookingFilter? filter,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    List<String>? payingBookingIds,
    Object? lastPaidBookingId = _unset,
  }) {
    return HotelBookingsState(
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
