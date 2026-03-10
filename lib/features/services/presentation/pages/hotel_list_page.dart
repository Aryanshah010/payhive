import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/presentation/pages/hotel_detail_page.dart';
import 'package:payhive/features/services/presentation/pages/my_hotel_bookings_page.dart';
import 'package:payhive/features/services/presentation/state/hotel_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_list_view_model.dart';

class HotelListPage extends ConsumerStatefulWidget {
  const HotelListPage({super.key});

  @override
  ConsumerState<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends ConsumerState<HotelListPage> {
  static const double _loadMoreThreshold = 220;

  final TextEditingController _cityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      final currentState = ref.read(hotelListViewModelProvider);
      _cityController.text = currentState.city;
      ref.read(hotelListViewModelProvider.notifier).loadInitial();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _loadMoreThreshold) {
      ref.read(hotelListViewModelProvider.notifier).loadMore();
    }
  }

  void _applyFilter() {
    ref
        .read(hotelListViewModelProvider.notifier)
        .applyCityFilter(_cityController.text);
  }

  void _clearFilter() {
    _cityController.clear();
    ref.read(hotelListViewModelProvider.notifier).clearFilter();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelListViewModelProvider);
    final viewModel = ref.read(hotelListViewModelProvider.notifier);

    ref.listen<HotelListState>(hotelListViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels'),
        actions: [
          TextButton.icon(
            onPressed: () {
              AppRoutes.push(context, const MyHotelBookingsPage());
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('My Bookings'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(child: _buildBody(state: state)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _cityController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'Kathmandu',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            onSubmitted: (_) => _applyFilter(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  child: const Text('Search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilter,
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody({required HotelListState state}) {
    if ((state.status == HotelListViewStatus.initial ||
            state.status == HotelListViewStatus.loading) &&
        state.hotels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == HotelListViewStatus.error && state.hotels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hotel_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('Unable to load hotels.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(hotelListViewModelProvider.notifier).loadInitial();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.hotels.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(hotelListViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 52),
            SizedBox(height: 16),
            Center(child: Text('No hotels found.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(hotelListViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.hotels.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.hotels.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final hotel = state.hotels[index];
          return _HotelCard(
            hotel: hotel,
            onBookTap: () {
              AppRoutes.push(context, HotelDetailPage(hotel: hotel));
            },
          );
        },
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.hotel, required this.onBookTap});

  final HotelEntity hotel;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotel.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('${hotel.city} • ${hotel.roomType}'),
            const SizedBox(height: 6),
            Text(
              'Rooms available: ${hotel.roomsAvailable}/${hotel.roomsTotal}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (hotel.amenities.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Amenities: ${hotel.amenities.take(3).join(', ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatNpr(hotel.pricePerNight),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('per night'),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hotel.roomsAvailable > 0 ? onBookTap : null,
                child: Text(
                  hotel.roomsAvailable > 0 ? 'Book Hotel' : 'Sold Out',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
