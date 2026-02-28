import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_info_state.dart';
import 'package:payhive/features/request_money/presentation/view_model/request_money_info_view_model.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_initial_page.dart';

class RequestMoneyInfoPage extends ConsumerStatefulWidget {
  final String? requestId;
  final RequestMoneyInfoFallbackData fallbackData;

  const RequestMoneyInfoPage({
    super.key,
    this.requestId,
    this.fallbackData = const RequestMoneyInfoFallbackData(),
  });

  @override
  ConsumerState<RequestMoneyInfoPage> createState() =>
      _RequestMoneyInfoPageState();
}

class _RequestMoneyInfoPageState extends ConsumerState<RequestMoneyInfoPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(requestMoneyInfoViewModelProvider.notifier)
          .initialize(
            requestId: widget.requestId,
            fallbackData: widget.fallbackData,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestMoneyInfoViewModelProvider);
    final viewModel = ref.read(requestMoneyInfoViewModelProvider.notifier);

    ref.listen<RequestMoneyInfoState>(requestMoneyInfoViewModelProvider, (
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

      final nextActionMessage = next.actionMessage;
      if (prev?.actionMessage != nextActionMessage &&
          nextActionMessage != null &&
          nextActionMessage.isNotEmpty) {
        SnackbarUtil.showSuccess(context, nextActionMessage);
        viewModel.clearActionMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Request Money Info')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.loadRequestDetail(showLoader: false),
          child: _buildBody(context, state, viewModel),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RequestMoneyInfoState state,
    RequestMoneyInfoViewModel viewModel,
  ) {
    if (state.isLoading && state.request == null && state.hasRequestId) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.request == null &&
        state.hasRequestId &&
        state.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.error_outline, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Unable to load this request right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => viewModel.loadRequestDetail(showLoader: true),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    final request = state.request;
    final requesterName = request?.requester.fullName.trim();
    final requesterPhone = request?.requester.phoneNumber.trim();
    final receiverName = request?.receiver.fullName.trim();
    final receiverPhone = request?.receiver.phoneNumber.trim();
    final amount = request?.amount;
    final remark = request?.remark;
    final createdAt = request?.createdAt ?? state.fallbackData.createdAt;

    final resolvedRequesterPhone = _firstNonEmpty(
      requesterPhone,
      state.fallbackData.phoneNumber,
    );
    final resolvedRemark = _firstNonEmpty(remark, state.fallbackData.remark);
    final amountText = amount != null
        ? formatNpr(amount)
        : (state.fallbackData.amountInput == null
              ? '--'
              : 'NPR ${state.fallbackData.amountInput}');

    final statusLabel = _statusLabel(state.resolvedStatus);
    final canTakeAction = state.canTakeAction;
    final readOnlyMessage = _readOnlyMessage(state);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(
              context,
              state.resolvedStatus,
            ).withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _statusColor(context, state.resolvedStatus),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoCard(
          context,
          children: [
            _row('Amount', amountText),
            _row('Requester', _firstNonEmpty(requesterName, '--')!),
            _row(
              'Requester Phone',
              _firstNonEmpty(resolvedRequesterPhone, '--')!,
            ),
            _row('Receiver', _firstNonEmpty(receiverName, '--')!),
            _row('Receiver Phone', _firstNonEmpty(receiverPhone, '--')!),
            _row('Remark', _firstNonEmpty(resolvedRemark, '--')!),
            _row(
              'Created',
              createdAt == null
                  ? '--'
                  : DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(createdAt.toLocal()),
            ),
            if (state.requestId != null) _row('Request ID', state.requestId!),
          ],
        ),
        if (!canTakeAction) ...[
          const SizedBox(height: 14),
          Text(
            readOnlyMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (canTakeAction)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isRejecting
                      ? null
                      : () => viewModel.rejectRequest(),
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
                  onPressed: () => _handleAccept(context, viewModel),
                  text: 'ACCEPT',
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _handleAccept(
    BuildContext context,
    RequestMoneyInfoViewModel viewModel,
  ) {
    final prefill = viewModel.buildAcceptPrefill();
    if (prefill == null) {
      SnackbarUtil.showError(
        context,
        'Unable to open payment flow for this request.',
      );
      return;
    }

    AppRoutes.push(
      context,
      SendMoneyInitialPage(
        prefill: SendMoneyPrefillArgs(
          phoneNumber: prefill.phoneNumber,
          amountInput: prefill.amountInput,
          remark: prefill.remark,
          autoLookup: true,
          sourceMoneyRequestId: prefill.sourceMoneyRequestId,
        ),
      ),
    );
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

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'PENDING':
        return Colors.amber.shade800;
      case 'REJECTED':
      case 'CANCELED':
      case 'CANCELLED':
      case 'EXPIRED':
        return Theme.of(context).colorScheme.error;
      case 'PAID':
      case 'ACCEPTED':
        return Colors.green.shade700;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Canceled';
      case 'EXPIRED':
        return 'Expired';
      case 'PAID':
        return 'Paid';
      case 'ACCEPTED':
        return 'Accepted';
      default:
        return 'Unknown';
    }
  }

  String _readOnlyMessage(RequestMoneyInfoState state) {
    if (!state.hasRequestId) {
      return 'Request ID is unavailable. Actions are disabled for this notification.';
    }

    if (state.request == null) {
      return 'Request details are unavailable. Pull to refresh and try again.';
    }

    if (!state.isReceiver) {
      return 'Only the receiver can accept or reject this request.';
    }

    if (!state.isPending) {
      return 'This request is already ${_statusLabel(state.resolvedStatus).toLowerCase()}.';
    }

    return 'Actions are unavailable for this request.';
  }

  String? _firstNonEmpty(String? first, String? second) {
    final a = first?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = second?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
