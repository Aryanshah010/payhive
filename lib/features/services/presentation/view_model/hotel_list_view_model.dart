import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/usecases/hotel_usecases.dart';
import 'package:payhive/features/services/presentation/state/hotel_list_state.dart';

final hotelListViewModelProvider =
    NotifierProvider<HotelListViewModel, HotelListState>(
      HotelListViewModel.new,
    );

class HotelListViewModel extends Notifier<HotelListState> {
  static const int pageSize = 10;

  late final GetHotelsUsecase _getHotelsUsecase;

  @override
  HotelListState build() {
    _getHotelsUsecase = ref.read(getHotelsUsecaseProvider);
    return HotelListState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: HotelListViewStatus.loading,
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
    if (state.status == HotelListViewStatus.loading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(page: state.page + 1, append: true);
  }

  Future<void> applyCityFilter(String city) async {
    final normalizedCity = city.trim();
    if (normalizedCity == state.city) {
      return;
    }

    state = state.copyWith(city: normalizedCity);
    await loadInitial();
  }

  Future<void> clearFilter() async {
    if (state.city.isEmpty) return;
    state = state.copyWith(city: '');
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
        status: HotelListViewStatus.loading,
        errorMessage: null,
      );
    }

    var currentPage = page;
    final filteredItems = <HotelEntity>[];
    var resolvedPage = append ? state.page : 0;
    var resolvedTotalPages = append ? state.totalPages : 1;
    Failure? failure;

    while (true) {
      final result = await _getHotelsUsecase(
        GetHotelsParams(page: currentPage, limit: pageSize, city: state.city),
      );

      var shouldContinue = false;

      result.fold(
        (nextFailure) {
          failure = nextFailure;
        },
        (pagedData) {
          filteredItems.addAll(_retainBookableHotels(pagedData.items));
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

        final nextStatus = state.hotels.isEmpty
            ? HotelListViewStatus.error
            : HotelListViewStatus.loaded;

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
        ? [...state.hotels, ...filteredItems]
        : filteredItems;

    state = state.copyWith(
      status: HotelListViewStatus.loaded,
      hotels: mergedItems,
      page: resolvedPage,
      totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
      isLoadingMore: false,
      errorMessage: null,
    );
  }

  List<HotelEntity> _retainBookableHotels(List<HotelEntity> hotels) {
    return hotels.where((hotel) => hotel.roomsAvailable > 0).toList();
  }
}
