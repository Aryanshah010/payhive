import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/presentation/state/flight_bookings_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_bookings_view_model.dart';

class MyFlightBookingsPage extends ConsumerStatefulWidget {
  const MyFlightBookingsPage({super.key});

  @override
  ConsumerState<MyFlightBookingsPage> createState() =>
      _MyFlightBookingsPageState();
}

class _MyFlightBookingsPageState extends ConsumerState<MyFlightBookingsPage> {
  static const double _loadMoreThreshold = 220;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(flightBookingsViewModelProvider.notifier).loadInitial();
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
      ref.read(flightBookingsViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightBookingsViewModelProvider);
    final viewModel = ref.read(flightBookingsViewModelProvider.notifier);

    ref.listen<FlightBookingsState>(flightBookingsViewModelProvider, (
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
        SnackbarUtil.showSuccess(context, 'Booking payment successful.');
        viewModel.clearLastPaidSignal();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Flight Bookings')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(FlightBookingsState state) {
    if ((state.status == FlightBookingsViewStatus.initial ||
            state.status == FlightBookingsViewStatus.loading) &&
        state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FlightBookingsViewStatus.error &&
        state.bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 44),
              const SizedBox(height: 10),
              const Text('Could not load flight bookings.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(flightBookingsViewModelProvider.notifier)
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
            ref.read(flightBookingsViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.inbox_outlined, size: 52),
            const SizedBox(height: 16),
            const Center(child: Text('No flight bookings found.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(flightBookingsViewModelProvider.notifier).refresh(),
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
                  .read(flightBookingsViewModelProvider.notifier)
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

  final FlightBookingItemEntity booking;
  final bool isPaying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final status = booking.status.toLowerCase();
    final canPay = status == 'created';
    final dateFormat = DateFormat('MMM d, hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.airline != null && booking.flightNumber != null
                  ? '${booking.airline} (${booking.flightNumber})'
                  : 'Flight Booking',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              (booking.from != null && booking.to != null)
                  ? '${booking.from} -> ${booking.to}'
                  : 'Route unavailable',
            ),
            if (booking.departure != null) ...[
              const SizedBox(height: 4),
              Text(
                'Departure: ${dateFormat.format(booking.departure!.toLocal())}',
              ),
            ],
            const SizedBox(height: 8),
            Text('Booking ID: ${booking.id}'),
            Text('Status: ${status.toUpperCase()}'),
            if (booking.quantity != null)
              Text('Passengers: ${booking.quantity}'),
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
