import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_view_model.dart';
import 'package:payhive/features/statement/presentation/widgets/filter_option_widget.dart';
import 'package:payhive/features/statement/presentation/widgets/statement_body_widget.dart';

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
      constraints: ResponsiveLayout.bottomSheetConstraints(
        context,
        tabletMaxWidth: 520,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final isTablet = ResponsiveLayout.isTablet(sheetContext);
        final scale = isTablet ? 1.15 : 1.0;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12 * scale, 12, 12 * scale, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                FilterOption(
                  value: StatementDirectionFilter.all,
                  groupValue: selected,
                  label: 'All',
                ),
                FilterOption(
                  value: StatementDirectionFilter.debit,
                  groupValue: selected,
                  label: 'Debit',
                ),
                FilterOption(
                  value: StatementDirectionFilter.credit,
                  groupValue: selected,
                  label: 'Credit',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (nextFilter == null || nextFilter == selected) return;
    await ref
        .read(statementViewModelProvider.notifier)
        .applyDirection(nextFilter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statementViewModelProvider);
    final viewModel = ref.read(statementViewModelProvider.notifier);
    final currentUserId = ref.read(userSessionServiceProvider).getUserId();
    final isTablet = ResponsiveLayout.isTablet(context);

    ref.listen<StatementState>(statementViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    ref.listen<StatementState>(statementViewModelProvider, (prev, next) {
      if (prev?.actionMessage == next.actionMessage) return;
      final message = next.actionMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showSuccess(context, message);
      viewModel.clearActionMessage();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Statement'), centerTitle: true),
      body: Column(
        children: [
          ResponsiveLayout.constrainedContent(
            context,
            child: Padding(
              padding: ResponsiveLayout.pagePadding(
                context,
                top: 12,
                bottom: 12,
              ),
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
                      style: TextStyle(fontSize: isTablet ? 17 : 14),
                      decoration: InputDecoration(
                        hintText: 'Search by remark or phone',
                        hintStyle: TextStyle(fontSize: isTablet ? 17 : 14),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: isTablet ? 26 : 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: isTablet ? 24 : 20,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  IconButton(
                    tooltip: 'Filter',
                    style: IconButton.styleFrom(
                      minimumSize: Size(isTablet ? 48 : 40, isTablet ? 48 : 40),
                    ),
                    onPressed: () => _openFilterSheet(context, state.direction),
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StatementBody(
              ref: ref,
              scrollController: _scrollController,
              state: state,
              currentUserId: currentUserId,
            ),
          ),
        ],
      ),
    );
  }
}
