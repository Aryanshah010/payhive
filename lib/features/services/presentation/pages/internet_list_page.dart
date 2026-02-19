import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/presentation/pages/internet_detail_page.dart';
import 'package:payhive/features/services/presentation/state/internet_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/internet_list_view_model.dart';

class InternetListPage extends ConsumerStatefulWidget {
  const InternetListPage({super.key});

  @override
  ConsumerState<InternetListPage> createState() => _InternetListPageState();
}

class _InternetListPageState extends ConsumerState<InternetListPage> {
  static const double _loadMoreThreshold = 220;

  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      final viewModel = ref.read(internetListViewModelProvider.notifier);
      final currentState = ref.read(internetListViewModelProvider);
      _providerController.text = currentState.provider;
      _searchController.text = currentState.search;
      viewModel.loadInitial();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _providerController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _loadMoreThreshold) {
      ref.read(internetListViewModelProvider.notifier).loadMore();
    }
  }

  void _applyFilters() {
    ref
        .read(internetListViewModelProvider.notifier)
        .applyFilters(
          provider: _providerController.text,
          search: _searchController.text,
        );
  }

  void _clearFilters() {
    _providerController.clear();
    _searchController.clear();
    ref.read(internetListViewModelProvider.notifier).clearFilters();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(internetListViewModelProvider);
    final viewModel = ref.read(internetListViewModelProvider.notifier);

    ref.listen<InternetListState>(internetListViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;

      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;

      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Internet Services')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _providerController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Provider',
              hintText: 'Airtel Xstream',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applyFilters(),
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Fiber 100 Mbps',
              prefixIcon: Icon(Icons.search_outlined),
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

  Widget _buildBody(InternetListState state) {
    if ((state.status == InternetListViewStatus.initial ||
            state.status == InternetListViewStatus.loading) &&
        state.services.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == InternetListViewStatus.error &&
        state.services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('Unable to load internet services.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(internetListViewModelProvider.notifier)
                      .loadInitial();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.services.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(internetListViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 52),
            SizedBox(height: 16),
            Center(child: Text('No internet services found.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(internetListViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.services.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.services.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final service = state.services[index];
          return _InternetServiceCard(
            service: service,
            onPayTap: () {
              AppRoutes.push(context, InternetDetailPage(service: service));
            },
          );
        },
      ),
    );
  }
}

class _InternetServiceCard extends StatelessWidget {
  const _InternetServiceCard({required this.service, required this.onPayTap});

  final InternetServiceEntity service;
  final VoidCallback onPayTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(service.provider),
            if (service.packageLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Package: ${service.packageLabel}'),
            ],
            const SizedBox(height: 8),
            Text(
              formatNpr(service.amount),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPayTap,
                child: const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
