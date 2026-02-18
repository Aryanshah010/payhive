import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/presentation/state/recharge_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_payment_view_model.dart';

class RechargeDetailPage extends ConsumerStatefulWidget {
  const RechargeDetailPage({super.key, required this.service});

  final RechargeServiceEntity service;

  @override
  ConsumerState<RechargeDetailPage> createState() => _RechargeDetailPageState();
}

class _RechargeDetailPageState extends ConsumerState<RechargeDetailPage> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(rechargePaymentViewModelProvider.notifier)
          .setService(widget.service);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rechargePaymentViewModelProvider);
    final viewModel = ref.read(rechargePaymentViewModelProvider.notifier);

    if (_phoneController.text != state.phoneNumber) {
      _phoneController.text = state.phoneNumber;
    }

    ref.listen<RechargePaymentState>(rechargePaymentViewModelProvider, (
      prev,
      next,
    ) {
      if (prev?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearError();
      }

      if (prev?.paymentResult?.transactionId !=
              next.paymentResult?.transactionId &&
          next.paymentResult != null) {
        ref.read(profileViewModelProvider.notifier).refreshProfile();
        SnackbarUtil.showSuccess(context, 'Recharge payment successful.');
      }
    });

    final service = state.service ?? widget.service;
    final isPayLoading =
        state.status == RechargePaymentViewStatus.loading &&
        state.action == RechargePaymentAction.pay;

    return Scaffold(
      appBar: AppBar(title: const Text('Recharge Payment')),
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
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Provider: ${service.provider}'),
                    if (service.packageLabel.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Package: ${service.packageLabel}'),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Amount: ${formatNpr(service.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              onChanged: viewModel.setPhoneNumber,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '98XXXXXXXX',
                prefixIcon: Icon(Icons.phone_android_outlined),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButtonWidget(
              onPressed: viewModel.payService,
              isLoading: isPayLoading,
              text: 'Pay Recharge',
            ),
            if (state.paymentResult != null) ...[
              const SizedBox(height: 16),
              _ReceiptCard(result: state.paymentResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.result});

  final PayRechargeResultEntity result;

  @override
  Widget build(BuildContext context) {
    final receipt = result.receipt;
    final createdAtText = receipt.createdAt == null
        ? null
        : DateFormat('yyyy-MM-dd hh:mm a').format(receipt.createdAt!.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Receipt',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Transaction ID: ${result.transactionId}'),
            if (receipt.receiptNo.trim().isNotEmpty)
              Text('Receipt No: ${receipt.receiptNo}'),
            if (receipt.phoneMasked.trim().isNotEmpty)
              Text('Phone: ${receipt.phoneMasked}'),
            if (receipt.carrier.trim().isNotEmpty)
              Text('Carrier: ${receipt.carrier}'),
            if (receipt.packageLabel.trim().isNotEmpty)
              Text('Package: ${receipt.packageLabel}'),
            Text('Amount: ${formatNpr(receipt.amount)}'),
            if (createdAtText != null) Text('Paid At: $createdAtText'),
            if (result.idempotentReplay)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Idempotent replay response',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
