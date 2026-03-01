import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';
import 'package:payhive/features/statement/presentation/state/undo_request_action_state.dart';
import 'package:payhive/features/statement/presentation/view_model/undo_request_action_view_model.dart';

class UndoRequestActionPage extends ConsumerStatefulWidget {
  final UndoRequestActionFallbackData fallbackData;

  const UndoRequestActionPage({
    super.key,
    this.fallbackData = const UndoRequestActionFallbackData(),
  });

  @override
  ConsumerState<UndoRequestActionPage> createState() =>
      _UndoRequestActionPageState();
}

class _UndoRequestActionPageState extends ConsumerState<UndoRequestActionPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _pinSheetOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(undoRequestActionViewModelProvider.notifier)
          .initialize(fallbackData: widget.fallbackData);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(undoRequestActionViewModelProvider);
    final viewModel = ref.read(undoRequestActionViewModelProvider.notifier);

    ref.listen<UndoRequestActionState>(undoRequestActionViewModelProvider, (
      prev,
      next,
    ) {
      final nextError = next.errorMessage;
      if (prev?.errorMessage != nextError &&
          nextError != null &&
          nextError.isNotEmpty) {
        SnackbarUtil.showError(context, nextError);
        viewModel.clearError();
      }

      final nextAction = next.actionMessage;
      if (prev?.actionMessage != nextAction &&
          nextAction != null &&
          nextAction.isNotEmpty) {
        SnackbarUtil.showSuccess(context, nextAction);
        viewModel.clearActionMessage();
      }

      if (_pinSheetOpen && next.status?.label == 'Accepted') {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    });

    final status = state.status;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = status?.color ?? colorScheme.onSurfaceVariant;
    final statusLabel = status?.label ?? 'Unknown';

    final requesterName = _firstNonEmpty(
      state.request?.requester.fullName,
      state.fallbackData.requesterName,
      '--',
    )!;
    final requesterPhone = _firstNonEmpty(
      state.request?.requester.phoneNumber,
      state.fallbackData.requesterPhoneNumber,
      '--',
    )!;
    final receiverName = _firstNonEmpty(
      state.request?.receiver.fullName,
      state.fallbackData.receiverName,
      '--',
    )!;
    final receiverPhone = _firstNonEmpty(
      state.request?.receiver.phoneNumber,
      state.fallbackData.receiverPhoneNumber,
      '--',
    )!;

    final amountValue = state.request?.amount ?? state.fallbackData.amount;
    final amountText = amountValue == null ? '--' : formatNpr(amountValue);

    final createdAt = state.request?.createdAt ?? state.fallbackData.createdAt;

    final resolvedTxId = state.resolvedRefundTxId ?? state.resolvedOriginalTxId;

    return Scaffold(
      appBar: AppBar(title: const Text('Undo Request')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _infoCard(
              context,
              children: [
                _row('Amount', amountText),
                _row('Requester', requesterName),
                _row('Requester Phone', requesterPhone),
                _row('Receiver', receiverName),
                _row('Receiver Phone', receiverPhone),
                _row('Original Tx ID', state.resolvedOriginalTxId ?? '--'),
                _row('Refund Tx ID', state.resolvedRefundTxId ?? '--'),
                _row(
                  'Created',
                  createdAt == null
                      ? '--'
                      : DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(createdAt.toLocal()),
                ),
                _row('Undo Request ID', state.requestId ?? '--'),
              ],
            ),
            const SizedBox(height: 14),
            if (!state.canTakeAction)
              Text(
                _readOnlyMessage(state),
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            const SizedBox(height: 20),
            if (state.canTakeAction)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isRejecting
                          ? null
                          : () => ref
                                .read(
                                  undoRequestActionViewModelProvider.notifier,
                                )
                                .rejectRequest(),
                      child: state.isRejecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButtonWidget(
                      onPressed: _openPinSheet,
                      text: 'ACCEPT',
                    ),
                  ),
                ],
              ),
            if (!state.canTakeAction && resolvedTxId != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  AppRoutes.push(
                    context,
                    StatementDetailPage(
                      txId: resolvedTxId,
                      initialUndoStatus: state.status,
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('VIEW TRANSACTION'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openPinSheet() async {
    if (_pinSheetOpen || !mounted) return;
    _pinSheetOpen = true;
    _pinController.clear();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return Consumer(
            builder: (sheetContext, ref, _) {
              final state = ref.watch(undoRequestActionViewModelProvider);
              final viewModel = ref.read(
                undoRequestActionViewModelProvider.notifier,
              );
              final colorScheme = Theme.of(sheetContext).colorScheme;

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.outline.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          'Enter PIN',
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '4-digit PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButtonWidget(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            viewModel.acceptRequest(_pinController.text);
                          },
                          isLoading: state.isAccepting,
                          text: 'CONFIRM',
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: state.isAccepting
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      _pinController.clear();
      _pinSheetOpen = false;
    }
  }

  Widget _infoCard(BuildContext context, {required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _readOnlyMessage(UndoRequestActionState state) {
    if (!state.hasRequestId) {
      return 'Undo request ID is unavailable. Actions are disabled for this notification.';
    }

    if (state.status?.label == 'Accepted') {
      return 'This undo request was already accepted.';
    }

    if (state.status?.label == 'Rejected') {
      return 'This undo request was already rejected.';
    }

    return 'Actions are unavailable for this undo request.';
  }

  String? _firstNonEmpty(String? a, String? b, String fallback) {
    final aTrim = a?.trim();
    if (aTrim != null && aTrim.isNotEmpty) return aTrim;

    final bTrim = b?.trim();
    if (bTrim != null && bTrim.isNotEmpty) return bTrim;

    return fallback;
  }
}
