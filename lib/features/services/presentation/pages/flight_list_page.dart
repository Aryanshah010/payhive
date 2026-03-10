import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
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
    final isTablet = ResponsiveLayout.isTablet(context);

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
            icon: Icon(Icons.receipt_long_outlined, size: isTablet ? 22 : 20),
            label: Text(
              'My Bookings',
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    final isTablet = ResponsiveLayout.isTablet(context);

    return ResponsiveLayout.constrainedContent(
      context,
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context, top: 12, bottom: 10),
        child: Column(
          children: [
            TextField(
              controller: _fromController,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: isTablet ? 17 : 14),
              decoration: InputDecoration(
                labelText: 'From',
                hintText: 'Kathmandu (KTM)',
                prefixIcon: Icon(
                  Icons.flight_takeoff_rounded,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _toController,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: isTablet ? 17 : 14),
              decoration: InputDecoration(
                labelText: 'To',
                hintText: 'Pokhara (PKR)',
                prefixIcon: Icon(
                  Icons.flight_land_rounded,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              style: TextStyle(fontSize: isTablet ? 17 : 14),
              decoration: InputDecoration(
                labelText: 'Date (YYYY-MM-DD)',
                hintText: 'Select departure date',
                prefixIcon: Icon(
                  Icons.calendar_month_outlined,
                  size: isTablet ? 24 : 20,
                ),
                suffixIcon: _dateController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _dateController.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          size: isTablet ? 24 : 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: Text(
                      'Search',
                      style: TextStyle(fontSize: isTablet ? 17 : 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: isTablet ? 17 : 15),
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

  Widget _buildBody({required FlightListState state}) {
    if ((state.status == FlightListViewStatus.initial ||
            state.status == FlightListViewStatus.loading) &&
        state.flights.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FlightListViewStatus.error && state.flights.isEmpty) {
      return ResponsiveLayout.constrainedContent(
        context,
        child: Center(
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
                    ref
                        .read(flightListViewModelProvider.notifier)
                        .loadInitial();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
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
          padding: ResponsiveLayout.pagePadding(context),
          children: [
            ResponsiveLayout.constrainedContent(
              context,
              child: const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 52),
                    SizedBox(height: 16),
                    Text('No upcoming flights found.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(flightListViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveLayout.pagePadding(context, top: 8, bottom: 24),
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
          return ResponsiveLayout.constrainedContent(
            context,
            child: _FlightCard(
              flight: flight,
              onBookTap: () {
                AppRoutes.push(context, FlightDetailPage(flight: flight));
              },
            ),
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
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.1 : 1.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 14),
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
                      fontSize: 16 * scale,
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
                      fontSize: 12.5 * scale,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${flight.from} -> ${flight.to}',
              style: TextStyle(fontSize: 14 * scale),
            ),
            const SizedBox(height: 6),
            Text(
              'Departure: ${dateFormat.format(flight.departure.toLocal())}',
              style: TextStyle(fontSize: 13 * scale),
            ),
            Text(
              'Arrival: ${dateFormat.format(flight.arrival.toLocal())}',
              style: TextStyle(fontSize: 13 * scale),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seats: ${flight.seatsAvailable}/${flight.seatsTotal}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5 * scale,
                  ),
                ),
                Text(
                  formatNpr(flight.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16 * scale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: flight.seatsAvailable > 0 ? onBookTap : null,
                child: Text(
                  flight.seatsAvailable > 0 ? 'Book' : 'Sold Out',
                  style: TextStyle(fontSize: isTablet ? 16 : 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
