import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final result = await _getHotelsUsecase(
      GetHotelsParams(page: page, limit: pageSize, city: state.city),
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

        final nextStatus = state.hotels.isEmpty
            ? HotelListViewStatus.error
            : HotelListViewStatus.loaded;

        state = state.copyWith(
          status: nextStatus,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (pagedData) {
        final mergedItems = append
            ? [...state.hotels, ...pagedData.items]
            : pagedData.items;

        state = state.copyWith(
          status: HotelListViewStatus.loaded,
          hotels: mergedItems,
          page: pagedData.page,
          totalPages: pagedData.totalPages < 1 ? 1 : pagedData.totalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
      },
    );
  }
}
