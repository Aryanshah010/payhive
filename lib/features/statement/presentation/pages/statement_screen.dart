import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_view_model.dart';
import 'package:payhive/features/statement/presentation/widgets/statement_item_tile.dart';

class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  static const Duration _searchDebounce = Duration(milliseconds: 350);
  static const double _loadMoreThreshold = 240;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(statementViewModelProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
      ref.read(statementViewModelProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      ref.read(statementViewModelProvider.notifier).applySearch(value);
    });
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    StatementDirectionFilter selected,
  ) async {
    final nextFilter = await showModalBottomSheet<StatementDirectionFilter>(
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
              _filterOption(
                context: context,
                value: StatementDirectionFilter.all,
                groupValue: selected,
                label: 'All',
              ),
              _filterOption(
                context: context,
                value: StatementDirectionFilter.debit,
                groupValue: selected,
                label: 'Debit',
              ),
              _filterOption(
                context: context,
                value: StatementDirectionFilter.credit,
                groupValue: selected,
                label: 'Credit',
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (nextFilter == null || nextFilter == selected) return;
    await ref
        .read(statementViewModelProvider.notifier)
        .applyDirection(nextFilter);
  }

  Widget _filterOption({
    required BuildContext context,
    required StatementDirectionFilter value,
    required StatementDirectionFilter groupValue,
    required String label,
  }) {
    return RadioListTile<StatementDirectionFilter>(
      value: value,
      groupValue: groupValue,
      title: Text(label),
      onChanged: (next) {
        if (next == null) return;
        Navigator.pop(context, next);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statementViewModelProvider);
    final viewModel = ref.read(statementViewModelProvider.notifier);
    final currentUserId = ref.read(userSessionServiceProvider).getUserId();

    ref.listen<StatementState>(statementViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Statement'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                      _onSearchChanged(value);
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by remark or phone',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _openFilterSheet(context, state.direction),
                  icon: const Icon(Icons.filter_alt_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(
              context: context,
              state: state,
              currentUserId: currentUserId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required StatementState state,
    required String? currentUserId,
  }) {
    if (state.status == StatementViewStatus.loading &&
        state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == StatementViewStatus.error &&
        state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 42),
              const SizedBox(height: 10),
              const Text('Could not load statements.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    ref.read(statementViewModelProvider.notifier).loadInitial(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(statementViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 52),
            SizedBox(height: 16),
            Center(child: Text('No transactions found for this filter.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(statementViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.transactions.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.transactions.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final transaction = state.transactions[index];

          return StatementItemTile(
            transaction: transaction,
            currentUserId: currentUserId,
            onTap: () {
              AppRoutes.push(
                context,
                StatementDetailPage(
                  txId: transaction.txId,
                  initialReceipt: transaction,
                ),
              );
            },
            onUndoTap: () {
              SnackbarUtil.showInfo(
                context,
                'Undo request flow will be added in the next step.',
              );
            },
          );
        },
      ),
    );
  }
}
