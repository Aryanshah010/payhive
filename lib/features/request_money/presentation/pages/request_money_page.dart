import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_state.dart';
import 'package:payhive/features/request_money/presentation/view_model/request_money_view_model.dart';

class RequestMoneyPage extends ConsumerStatefulWidget {
  const RequestMoneyPage({super.key});

  @override
  ConsumerState<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends ConsumerState<RequestMoneyPage> {
  static const double _loadMoreThreshold = 240;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(requestMoneyViewModelProvider.notifier).loadInitialPending();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _loadMoreThreshold) {
      ref.read(requestMoneyViewModelProvider.notifier).loadMorePending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestMoneyViewModelProvider);
    final viewModel = ref.read(requestMoneyViewModelProvider.notifier);

    ref.listen<RequestMoneyState>(requestMoneyViewModelProvider, (prev, next) {
      _syncControllers(next);

      if (prev?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearError();
      }

      if (prev?.status != next.status &&
          next.status == RequestMoneyStatus.success) {
        if (next.action == RequestMoneyAction.submit) {
          SnackbarUtil.showSuccess(context, 'Money request sent successfully.');
        } else if (next.action == RequestMoneyAction.cancel) {
          SnackbarUtil.showSuccess(
            context,
            'Money request canceled successfully.',
          );
        }
        viewModel.clearStatus();
      }
    });

    final isSubmitting =
        state.status == RequestMoneyStatus.loading &&
        state.action == RequestMoneyAction.submit;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Money')),
      body: RefreshIndicator(
        onRefresh: () => viewModel.refreshPending(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _buildFormCard(
                  context,
                  state,
                  isSubmitting: isSubmitting,
                  onSubmit: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    viewModel.submitRequest();
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  'Pending Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ..._buildPendingSlivers(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    RequestMoneyState state, {
    required bool isSubmitting,
    required VoidCallback onSubmit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: ref
                .read(requestMoneyViewModelProvider.notifier)
                .setPhoneNumber,
            decoration: InputDecoration(
              labelText: 'PayHive ID',
              hintText: 'Enter recipient mobile number',
              counterText: '',
              prefixIcon: const Icon(Icons.phone_outlined),
              errorText: state.showValidationErrors ? state.phoneError : null,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: ref
                .read(requestMoneyViewModelProvider.notifier)
                .setAmountInput,
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              errorText: state.showValidationErrors ? state.amountError : null,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageController,
            maxLength: 140,
            onChanged: ref
                .read(requestMoneyViewModelProvider.notifier)
                .setRemark,
            decoration: InputDecoration(
              labelText: 'Request Message (optional)',
              hintText: 'Add note for the recipient',
              alignLabelWithHint: true,
              errorText: state.showValidationErrors ? state.remarkError : null,
            ),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          PrimaryButtonWidget(
            onPressed: isSubmitting ? null : onSubmit,
            text: 'REQUEST MONEY',
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPendingSlivers(
    BuildContext context,
    RequestMoneyState state,
  ) {
    if (state.status == RequestMoneyStatus.loading &&
        state.pendingRequests.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.pendingRequests.isEmpty && state.pendingErrorMessage != null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Could not load pending requests.'),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    ref
                        .read(requestMoneyViewModelProvider.notifier)
                        .loadInitialPending();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.pendingRequests.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No pending requests yet.'),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = state.pendingRequests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _pendingRequestCard(context, state, item),
            );
          }, childCount: state.pendingRequests.length),
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 6, bottom: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ];
  }

  Widget _pendingRequestCard(
    BuildContext context,
    RequestMoneyState state,
    MoneyRequestEntity item,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final receiverName = item.receiver.fullName.trim().isEmpty
        ? 'Unknown Recipient'
        : item.receiver.fullName.trim();
    final receiverPhone = item.receiver.phoneNumber.trim();
    final isCancelling =
        state.status == RequestMoneyStatus.loading &&
        state.action == RequestMoneyAction.cancel &&
        state.activeCancelRequestId == item.id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  receiverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          if (receiverPhone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'PayHive ID: $receiverPhone',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            formatNpr(item.amount),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (item.remark.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.remark.trim(),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(item.createdAt.toLocal()),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: isCancelling
                    ? null
                    : () async {
                        final shouldCancel = await _confirmCancel(context);
                        if (shouldCancel != true || !mounted) return;
                        unawaited(
                          ref
                              .read(requestMoneyViewModelProvider.notifier)
                              .cancelRequest(item.id),
                        );
                      },
                child: isCancelling
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel request?'),
          content: const Text('This will cancel the pending money request.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _syncControllers(RequestMoneyState state) {
    _setControllerText(_phoneController, state.phoneNumber);
    _setControllerText(_amountController, state.amountInput);
    _setControllerText(_messageController, state.remark ?? '');
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
