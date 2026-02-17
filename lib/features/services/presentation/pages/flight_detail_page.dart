import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/presentation/state/flight_booking_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_booking_view_model.dart';

class FlightDetailPage extends ConsumerStatefulWidget {
  const FlightDetailPage({super.key, required this.flight});

  final FlightEntity flight;

  @override
  ConsumerState<FlightDetailPage> createState() => _FlightDetailPageState();
}

class _FlightDetailPageState extends ConsumerState<FlightDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(flightBookingViewModelProvider.notifier)
          .setFlight(widget.flight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightBookingViewModelProvider);
    final viewModel = ref.read(flightBookingViewModelProvider.notifier);
    final dateFormat = DateFormat('MMM d, hh:mm a');

    ref.listen<FlightBookingState>(flightBookingViewModelProvider, (
      prev,
      next,
    ) {
      if (prev?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearError();
      }

      if (prev?.createdBooking?.bookingId != next.createdBooking?.bookingId &&
          next.createdBooking != null) {
        SnackbarUtil.showSuccess(context, 'Booking created successfully.');
      }

      if (prev?.paymentResult?.transactionId !=
              next.paymentResult?.transactionId &&
          next.paymentResult != null) {
        ref.read(profileViewModelProvider.notifier).refreshProfile();
        SnackbarUtil.showSuccess(context, 'Booking payment successful.');
      }
    });

    final flight = state.flight ?? widget.flight;
    final totalAmount = flight.price * state.quantity;
    final bookingStatus = _resolvedBookingStatus(state);
    final isCreateLoading =
        state.status == FlightBookingViewStatus.loading &&
        state.action == FlightBookingAction.createBooking;
    final isPayLoading =
        state.status == FlightBookingViewStatus.loading &&
        state.action == FlightBookingAction.payBooking;
    final isPaid = bookingStatus == 'paid';

    return Scaffold(
      appBar: AppBar(title: const Text('Flight Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${flight.airline} (${flight.flightNumber})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${flight.from} -> ${flight.to}'),
                    const SizedBox(height: 6),
                    Text(
                      'Departure: ${dateFormat.format(flight.departure.toLocal())}',
                    ),
                    Text(
                      'Arrival: ${dateFormat.format(flight.arrival.toLocal())}',
                    ),
                    const SizedBox(height: 6),
                    Text('Class: ${flight.flightClass}'),
                    Text('Available seats: ${flight.seatsAvailable}'),
                    const SizedBox(height: 10),
                    Text(
                      'Price per seat: ${formatNpr(flight.price)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Passengers',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: state.quantity > 1
                              ? viewModel.decrementQuantity
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${state.quantity}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: state.quantity < flight.seatsAvailable
                              ? viewModel.incrementQuantity
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${formatNpr(totalAmount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (state.createdBooking == null)
              PrimaryButtonWidget(
                onPressed: viewModel.createBooking,
                isLoading: isCreateLoading,
                text: 'Create Booking',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking ID: ${state.createdBooking!.bookingId}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status: ${bookingStatus.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Amount: ${formatNpr(state.createdBooking!.price)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: ((isPaid || state.payLocked) && !isPayLoading)
                        ? 0.6
                        : 1,
                    child: IgnorePointer(
                      ignoring: (isPaid || state.payLocked) && !isPayLoading,
                      child: PrimaryButtonWidget(
                        onPressed: viewModel.payBooking,
                        isLoading: isPayLoading,
                        text: isPaid ? 'Paid' : 'Pay Booking',
                      ),
                    ),
                  ),
                  if (state.payLocked && !isPayLoading && !isPaid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Payment request is in progress. Please wait.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _resolvedBookingStatus(FlightBookingState state) {
    final paymentStatus = state.paymentResult?.booking.status.trim();
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      return paymentStatus.toLowerCase();
    }

    final createStatus = state.createdBooking?.status.trim();
    if (createStatus == null || createStatus.isEmpty) {
      return 'created';
    }
    return createStatus.toLowerCase();
  }
}
