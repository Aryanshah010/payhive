import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/presentation/state/hotel_bookings_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_bookings_view_model.dart';

class MyHotelBookingsPage extends ConsumerStatefulWidget {
  const MyHotelBookingsPage({super.key});

  @override
  ConsumerState<MyHotelBookingsPage> createState() =>
      _MyHotelBookingsPageState();
}

class _MyHotelBookingsPageState extends ConsumerState<MyHotelBookingsPage> {
  static const double _loadMoreThreshold = 220;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(hotelBookingsViewModelProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _loadMoreThreshold) {
      ref.read(hotelBookingsViewModelProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    HotelBookingFilter selected,
  ) async {
    final nextFilter = await showModalBottomSheet<HotelBookingFilter>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ...HotelBookingFilter.values.map((filter) {
                return RadioListTile<HotelBookingFilter>(
                  value: filter,
                  groupValue: selected,
                  title: Text(filter.label),
                  onChanged: (next) {
                    if (next == null) return;
                    Navigator.pop(context, next);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (nextFilter == null || nextFilter == selected) return;
    await ref
        .read(hotelBookingsViewModelProvider.notifier)
        .applyFilter(nextFilter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelBookingsViewModelProvider);
    final viewModel = ref.read(hotelBookingsViewModelProvider.notifier);

    ref.listen<HotelBookingsState>(hotelBookingsViewModelProvider, (
      prev,
      next,
    ) {
      if (prev?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearError();
      }

      if (prev?.lastPaidBookingId != next.lastPaidBookingId &&
          next.lastPaidBookingId != null) {
        ref.read(profileViewModelProvider.notifier).refreshProfile();
        SnackbarUtil.showSuccess(context, 'Booking payment successful.');
        viewModel.clearLastPaidSignal();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hotel Bookings'),
        actions: [
          IconButton(
            onPressed: () => _openFilterSheet(context, state.filter),
            tooltip: 'Filter status',
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(HotelBookingsState state) {
    if ((state.status == HotelBookingsViewStatus.initial ||
            state.status == HotelBookingsViewStatus.loading) &&
        state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == HotelBookingsViewStatus.error &&
        state.bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 44),
              const SizedBox(height: 10),
              const Text('Could not load hotel bookings.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(hotelBookingsViewModelProvider.notifier)
                      .loadInitial();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(hotelBookingsViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.inbox_outlined, size: 52),
            const SizedBox(height: 16),
            Center(child: Text('No bookings found for ${state.filter.label}.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(hotelBookingsViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.bookings.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.bookings.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final booking = state.bookings[index];
          return _BookingCard(
            booking: booking,
            isPaying: state.isBookingPaying(booking.id),
            onPay: () {
              ref
                  .read(hotelBookingsViewModelProvider.notifier)
                  .payBooking(booking.id);
            },
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isPaying,
    required this.onPay,
  });

  final HotelBookingItemEntity booking;
  final bool isPaying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final status = booking.status.toLowerCase();
    final canPay = status == 'created';
    final checkin = booking.checkin;
    final checkinText = checkin == null
        ? null
        : DateFormat('yyyy-MM-dd').format(checkin.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.name ?? 'Hotel Booking',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              [
                    if (booking.city != null && booking.city!.trim().isNotEmpty)
                      booking.city!,
                    if (booking.roomType != null &&
                        booking.roomType!.trim().isNotEmpty)
                      booking.roomType!,
                  ].join(' • ').isEmpty
                  ? 'Hotel details unavailable'
                  : [
                      if (booking.city != null &&
                          booking.city!.trim().isNotEmpty)
                        booking.city!,
                      if (booking.roomType != null &&
                          booking.roomType!.trim().isNotEmpty)
                        booking.roomType!,
                    ].join(' • '),
            ),
            if (checkinText != null) ...[
              const SizedBox(height: 4),
              Text('Checkin: $checkinText'),
            ],
            const SizedBox(height: 8),
            Text('Booking ID: ${booking.id}'),
            Text('Status: ${status.toUpperCase()}'),
            if (booking.quantity != null) Text('Rooms: ${booking.quantity}'),
            if (booking.nights != null) Text('Nights: ${booking.nights}'),
            if (booking.price != null)
              Text('Amount: ${formatNpr(booking.price!)}'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPay && !isPaying ? onPay : null,
                child: isPaying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(canPay ? 'Pay Booking' : 'Paid / Not Payable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
