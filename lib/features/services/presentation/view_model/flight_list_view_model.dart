import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/usecases/flight_usecases.dart';
import 'package:payhive/features/services/presentation/state/flight_list_state.dart';

final flightListViewModelProvider =
    NotifierProvider<FlightListViewModel, FlightListState>(
      FlightListViewModel.new,
    );

class FlightListViewModel extends Notifier<FlightListState> {
  static const int pageSize = 10;

  late final GetFlightsUsecase _getFlightsUsecase;

  @override
  FlightListState build() {
    _getFlightsUsecase = ref.read(getFlightsUsecaseProvider);
    return FlightListState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: FlightListViewStatus.loading,
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
    if (state.status == FlightListViewStatus.loading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(page: state.page + 1, append: true);
  }

  Future<void> applyFilters({
    required String from,
    required String to,
    String? date,
  }) async {
    final normalizedFrom = from.trim();
    final normalizedTo = to.trim();
    final normalizedDate = date?.trim() ?? '';

    if (normalizedFrom == state.from &&
        normalizedTo == state.to &&
        normalizedDate == state.date) {
      return;
    }

    state = state.copyWith(
      from: normalizedFrom,
      to: normalizedTo,
      date: normalizedDate,
    );

    await loadInitial();
  }

  Future<void> clearFilters() async {
    if (state.from.isEmpty && state.to.isEmpty && state.date.isEmpty) {
      return;
    }

    state = state.copyWith(from: '', to: '', date: '');
    await loadInitial();
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    bool showPrimaryLoader = true,
  }) async {
    if (!append && showPrimaryLoader) {
      state = state.copyWith(
        status: FlightListViewStatus.loading,
        errorMessage: null,
      );
    }

    var currentPage = page;
    final filteredItems = <FlightEntity>[];
    var resolvedPage = append ? state.page : 0;
    var resolvedTotalPages = append ? state.totalPages : 1;
    Failure? failure;

    while (true) {
      final result = await _getFlightsUsecase(
        GetFlightsParams(
          page: currentPage,
          limit: pageSize,
          from: state.from,
          to: state.to,
          date: state.date.isEmpty ? null : state.date,
        ),
      );

      var shouldContinue = false;

      result.fold(
        (nextFailure) {
          failure = nextFailure;
        },
        (pagedData) {
          filteredItems.addAll(_retainUpcomingFlights(pagedData.items));
          resolvedPage = pagedData.page;
          resolvedTotalPages = pagedData.totalPages < 1
              ? 1
              : pagedData.totalPages;
          shouldContinue =
              filteredItems.isEmpty && resolvedPage < resolvedTotalPages;
        },
      );

      if (failure != null) {
        if (append) {
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: failure!.message,
          );
          return;
        }

        final nextStatus = state.flights.isEmpty
            ? FlightListViewStatus.error
            : FlightListViewStatus.loaded;

        state = state.copyWith(
          status: nextStatus,
          isLoadingMore: false,
          errorMessage: failure!.message,
        );
        return;
      }

      if (!shouldContinue) {
        break;
      }

      currentPage = resolvedPage + 1;
    }

    final mergedItems = append
        ? [...state.flights, ...filteredItems]
        : filteredItems;

    state = state.copyWith(
      status: FlightListViewStatus.loaded,
      flights: mergedItems,
      page: resolvedPage,
      totalPages: resolvedTotalPages,
      isLoadingMore: false,
      errorMessage: null,
    );
  }

  List<FlightEntity> _retainUpcomingFlights(List<FlightEntity> flights) {
    final today = _asLocalDate(DateTime.now());
    return flights.where((flight) {
      final departureDate = _asLocalDate(flight.departure.toLocal());
      return !departureDate.isBefore(today);
    }).toList();
  }

  DateTime _asLocalDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
