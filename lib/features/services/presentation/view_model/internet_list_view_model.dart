import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/services/domain/usecases/internet_usecases.dart';
import 'package:payhive/features/services/presentation/state/internet_list_state.dart';

final internetListViewModelProvider =
    NotifierProvider<InternetListViewModel, InternetListState>(
      InternetListViewModel.new,
    );

class InternetListViewModel extends Notifier<InternetListState> {
  static const int pageSize = 10;

  late final GetInternetServicesUsecase _getInternetServicesUsecase;

  @override
  InternetListState build() {
    _getInternetServicesUsecase = ref.read(getInternetServicesUsecaseProvider);
    return InternetListState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: InternetListViewStatus.loading,
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
    if (state.status == InternetListViewStatus.loading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(page: state.page + 1, append: true);
  }

  Future<void> applyFilters({
    required String provider,
    required String search,
  }) async {
    final normalizedProvider = provider.trim();
    final normalizedSearch = search.trim();

    if (normalizedProvider == state.provider &&
        normalizedSearch == state.search) {
      return;
    }

    state = state.copyWith(
      provider: normalizedProvider,
      search: normalizedSearch,
    );
    await loadInitial();
  }

  Future<void> clearFilters() async {
    if (state.provider.isEmpty && state.search.isEmpty) return;

    state = state.copyWith(provider: '', search: '');
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
        status: InternetListViewStatus.loading,
        errorMessage: null,
      );
    }

    final result = await _getInternetServicesUsecase(
      GetInternetServicesParams(
        page: page,
        limit: pageSize,
        provider: state.provider,
        search: state.search,
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

        final nextStatus = state.services.isEmpty
            ? InternetListViewStatus.error
            : InternetListViewStatus.loaded;

        state = state.copyWith(
          status: nextStatus,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (pagedData) {
        final mergedItems = append
            ? [...state.services, ...pagedData.items]
            : pagedData.items;

        state = state.copyWith(
          status: InternetListViewStatus.loaded,
          services: mergedItems,
          page: pagedData.page,
          totalPages: pagedData.totalPages < 1 ? 1 : pagedData.totalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
      },
    );
  }
}
