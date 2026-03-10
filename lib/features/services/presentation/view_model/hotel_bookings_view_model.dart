import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/services/domain/usecases/hotel_usecases.dart';
import 'package:payhive/features/services/presentation/state/hotel_bookings_state.dart';
import 'package:uuid/uuid.dart';

final hotelBookingsViewModelProvider =
    NotifierProvider<HotelBookingsViewModel, HotelBookingsState>(
      HotelBookingsViewModel.new,
    );

class HotelBookingsViewModel extends Notifier<HotelBookingsState> {
  static const int pageSize = 10;

  late final GetHotelBookingsUsecase _getHotelBookingsUsecase;
  late final PayHotelBookingUsecase _payHotelBookingUsecase;
  final Uuid _uuid = const Uuid();
  final Map<String, String> _idempotencyKeysByBooking = {};

  @override
  HotelBookingsState build() {
    _getHotelBookingsUsecase = ref.read(getHotelBookingsUsecaseProvider);
    _payHotelBookingUsecase = ref.read(payHotelBookingUsecaseProvider);
    return HotelBookingsState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: HotelBookingsViewStatus.loading,
      isLoadingMore: false,
      errorMessage: null,
      page: 0,
      totalPages: 1,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> refresh() async {
    await _loadPage(page: 1, append: false, showPrimaryLoader: false);
  }

  Future<void> loadMore() async {
    if (state.status == HotelBookingsViewStatus.loading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(page: state.page + 1, append: true);
  }

  Future<void> applyFilter(HotelBookingFilter filter) async {
    if (filter == state.filter) return;

    state = state.copyWith(filter: filter);
    await loadInitial();
  }

  Future<void> payBooking(String bookingId) async {
    final normalizedId = bookingId.trim();
    if (normalizedId.isEmpty) return;

    if (state.isBookingPaying(normalizedId)) return;

    final existing = state.bookings.where((item) => item.id == normalizedId);
    if (existing.isEmpty) return;

    final booking = existing.first;
    if (booking.status.toLowerCase() != 'created') return;

    final idempotencyKey =
        _idempotencyKeysByBooking[normalizedId] ?? _uuid.v4();
    _idempotencyKeysByBooking[normalizedId] = idempotencyKey;

    state = state.copyWith(
      payingBookingIds: [...state.payingBookingIds, normalizedId],
      errorMessage: null,
      lastPaidBookingId: null,
    );

    final result = await _payHotelBookingUsecase(
      PayHotelBookingParams(
        bookingId: normalizedId,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          payingBookingIds: _removePayingId(normalizedId),
          errorMessage: failure.message,
          lastPaidBookingId: null,
        );
      },
      (payment) {
        final updatedItems = state.bookings.map((item) {
          if (item.id != normalizedId) return item;

          final status = payment.booking.status.trim().isEmpty
              ? 'paid'
              : payment.booking.status.trim();

          return item.copyWith(
            status: status,
            paymentTxnId: payment.booking.paymentTxnId ?? payment.transactionId,
            paidAt: payment.booking.paidAt ?? DateTime.now(),
          );
        }).toList();

        state = state.copyWith(
          bookings: updatedItems,
          payingBookingIds: _removePayingId(normalizedId),
          errorMessage: null,
          lastPaidBookingId: normalizedId,
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void clearLastPaidSignal() {
    if (state.lastPaidBookingId == null) return;
    state = state.copyWith(lastPaidBookingId: null);
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    bool showPrimaryLoader = true,
  }) async {
    if (!append && showPrimaryLoader) {
      state = state.copyWith(
        status: HotelBookingsViewStatus.loading,
        errorMessage: null,
      );
    }

    final result = await _getHotelBookingsUsecase(
      GetHotelBookingsParams(
        page: page,
        limit: pageSize,
        status: state.filter.apiValue,
      ),
    );

    result.fold(
      (failure) {
        if (append) {
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: failure.message,
          );
          return;
        }

        final nextStatus = state.bookings.isEmpty
            ? HotelBookingsViewStatus.error
            : HotelBookingsViewStatus.loaded;

        state = state.copyWith(
          status: nextStatus,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (pagedData) {
        final mergedItems = append
            ? [...state.bookings, ...pagedData.items]
            : pagedData.items;

        state = state.copyWith(
          status: HotelBookingsViewStatus.loaded,
          bookings: mergedItems,
          page: pagedData.page,
          totalPages: pagedData.totalPages < 1 ? 1 : pagedData.totalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
      },
    );
  }

  List<String> _removePayingId(String bookingId) {
    return state.payingBookingIds.where((id) => id != bookingId).toList();
  }
}
