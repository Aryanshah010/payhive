import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/presentation/state/hotel_booking_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_booking_view_model.dart';

class HotelDetailPage extends ConsumerStatefulWidget {
  const HotelDetailPage({super.key, required this.hotel});

  final HotelEntity hotel;

  @override
  ConsumerState<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends ConsumerState<HotelDetailPage> {
  final TextEditingController _checkinController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(hotelBookingViewModelProvider.notifier).setHotel(widget.hotel);
    });
  }

  @override
  void dispose() {
    _checkinController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckinDate() async {
    final tomorrow = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    DateTime initialDate = tomorrow;

    final existing = DateTime.tryParse(_checkinController.text.trim());
    if (existing != null) {
      final existingDate = DateUtils.dateOnly(existing);
      if (!existingDate.isBefore(tomorrow)) {
        initialDate = existingDate;
      }
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 365)),
    );

    if (selected == null) return;

    final formatted = DateFormat('yyyy-MM-dd').format(selected);
    _checkinController.text = formatted;
    ref.read(hotelBookingViewModelProvider.notifier).setCheckin(formatted);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelBookingViewModelProvider);
    final viewModel = ref.read(hotelBookingViewModelProvider.notifier);

    if (_checkinController.text != state.checkin) {
      _checkinController.text = state.checkin;
    }

    ref.listen<HotelBookingState>(hotelBookingViewModelProvider, (prev, next) {
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

    final hotel = state.hotel ?? widget.hotel;
    final totalAmount = hotel.pricePerNight * state.rooms * state.nights;
    final bookingStatus = _resolvedBookingStatus(state);
    final isCreateLoading =
        state.status == HotelBookingViewStatus.loading &&
        state.action == HotelBookingAction.createBooking;
    final isPayLoading =
        state.status == HotelBookingViewStatus.loading &&
        state.action == HotelBookingAction.payBooking;
    final isPaid = bookingStatus == 'paid';

    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Detail')),
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
                      hotel.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${hotel.city} • ${hotel.roomType}'),
                    const SizedBox(height: 6),
                    Text('Available rooms: ${hotel.roomsAvailable}'),
                    const SizedBox(height: 10),
                    Text(
                      'Price per night: ${formatNpr(hotel.pricePerNight)}',
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
                      'Stay Details',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _checkinController,
                      readOnly: true,
                      onTap: _pickCheckinDate,
                      decoration: InputDecoration(
                        labelText: 'Checkin (YYYY-MM-DD)',
                        hintText: 'Select checkin date',
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        suffixIcon: _checkinController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _checkinController.clear();
                                  viewModel.setCheckin('');
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rooms',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: state.rooms > 1
                              ? viewModel.decrementRooms
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${state.rooms}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: state.rooms < hotel.roomsAvailable
                              ? viewModel.incrementRooms
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nights',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: state.nights > 1
                              ? viewModel.decrementNights
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${state.nights}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: viewModel.incrementNights,
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

  String _resolvedBookingStatus(HotelBookingState state) {
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
