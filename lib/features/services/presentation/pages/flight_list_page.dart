import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/presentation/pages/flight_detail_page.dart';
import 'package:payhive/features/services/presentation/pages/my_flight_bookings_page.dart';
import 'package:payhive/features/services/presentation/state/flight_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_list_view_model.dart';

class FlightListPage extends ConsumerStatefulWidget {
  const FlightListPage({super.key});

  @override
  ConsumerState<FlightListPage> createState() => _FlightListPageState();
}

class _FlightListPageState extends ConsumerState<FlightListPage> {
  static const double _loadMoreThreshold = 220;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      final currentState = ref.read(flightListViewModelProvider);
      _fromController.text = currentState.from;
      _toController.text = currentState.to;
      _dateController.text = currentState.date;
      ref.read(flightListViewModelProvider.notifier).loadInitial();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _loadMoreThreshold) {
      ref.read(flightListViewModelProvider.notifier).loadMore();
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime initialDate = today;

    final existing = DateTime.tryParse(_dateController.text.trim());
    if (existing != null) {
      final existingDate = DateUtils.dateOnly(existing);
      if (!existingDate.isBefore(today)) {
        initialDate = existingDate;
      }
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (selected == null) return;

    final formatted = DateFormat(
      'yyyy-MM-dd',
    ).format(DateUtils.dateOnly(selected));
    _dateController.text = formatted;
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    ref
        .read(flightListViewModelProvider.notifier)
        .applyFilters(
          from: _fromController.text,
          to: _toController.text,
          date: _dateController.text,
        );
  }

  void _clearFilters() {
    _fromController.clear();
    _toController.clear();
    _dateController.clear();
    ref.read(flightListViewModelProvider.notifier).clearFilters();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightListViewModelProvider);
    final viewModel = ref.read(flightListViewModelProvider.notifier);

    ref.listen<FlightListState>(flightListViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flights'),
        actions: [
          TextButton.icon(
            onPressed: () {
              AppRoutes.push(context, const MyFlightBookingsPage());
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
            controller: _fromController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'From',
              hintText: 'Kathmandu (KTM)',
              prefixIcon: Icon(Icons.flight_takeoff_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _toController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'To',
              hintText: 'Pokhara (PKR)',
              prefixIcon: Icon(Icons.flight_land_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: InputDecoration(
              labelText: 'Date (YYYY-MM-DD)',
              hintText: 'Select departure date',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              suffixIcon: _dateController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _dateController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody({required FlightListState state}) {
    if ((state.status == FlightListViewStatus.initial ||
            state.status == FlightListViewStatus.loading) &&
        state.flights.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FlightListViewStatus.error && state.flights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flight_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('Unable to load flights.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(flightListViewModelProvider.notifier).loadInitial();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.flights.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(flightListViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 52),
            SizedBox(height: 16),
            Center(child: Text('No upcoming flights found.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(flightListViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.flights.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.flights.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final flight = state.flights[index];
          return _FlightCard(
            flight: flight,
            onBookTap: () {
              AppRoutes.push(context, FlightDetailPage(flight: flight));
            },
          );
        },
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.flight, required this.onBookTap});

  final FlightEntity flight;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${flight.airline} (${flight.flightNumber})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.12),
                  ),
                  child: Text(
                    flight.flightClass,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${flight.from} -> ${flight.to}'),
            const SizedBox(height: 6),
            Text('Departure: ${dateFormat.format(flight.departure.toLocal())}'),
            Text('Arrival: ${dateFormat.format(flight.arrival.toLocal())}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seats: ${flight.seatsAvailable}/${flight.seatsTotal}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatNpr(flight.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: flight.seatsAvailable > 0 ? onBookTap : null,
                child: Text(flight.seatsAvailable > 0 ? 'Book' : 'Sold Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
