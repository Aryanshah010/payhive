import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_view_model.dart';
import 'package:payhive/features/statement/presentation/widgets/statement_item_tile.dart';

class StatementBody extends StatelessWidget {
  const StatementBody({
    super.key,
    required this.ref,
    required ScrollController scrollController,
    required this.state,
    required this.currentUserId,
  }) : _scrollController = scrollController;

  final WidgetRef ref;
  final ScrollController _scrollController;
  final StatementState state;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (state.status == StatementViewStatus.loading &&
        state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == StatementViewStatus.error &&
        state.transactions.isEmpty) {
      return ResponsiveLayout.constrainedContent(
        context,
        child: Center(
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
                  onPressed: () => ref
                      .read(statementViewModelProvider.notifier)
                      .loadInitial(),
                  child: const Text('Retry'),
                ),
              ],
            ),
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
                    Text('No transactions found for this filter.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(statementViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveLayout.pagePadding(context, top: 8, bottom: 24),
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
          final txId = transaction.txId.trim();
          final undoStatus = state.undoStatusByTxId[txId];
          final isRequestingUndo = state.requestingUndoTxIds.contains(txId);

          return ResponsiveLayout.constrainedContent(
            context,
            child: StatementItemTile(
              transaction: transaction,
              currentUserId: currentUserId,
              undoStatus: undoStatus,
              isRequestingUndo: isRequestingUndo,
              onTap: () {
                AppRoutes.push(
                  context,
                  StatementDetailPage(
                    txId: transaction.txId,
                    initialReceipt: transaction,
                    initialUndoStatus: undoStatus,
                  ),
                );
              },
              onUndoTap: () {
                ref
                    .read(statementViewModelProvider.notifier)
                    .requestUndo(transaction.txId);
              },
            ),
          );
        },
      ),
    );
  }
}
