import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_success_page.dart';
import 'package:payhive/features/send_money/presentation/state/send_money_state.dart';
import 'package:payhive/features/send_money/presentation/view_model/send_money_view_model.dart';
import 'package:payhive/features/send_money/presentation/widgets/amount_keypad_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';

class SendMoneyAmountPage extends ConsumerStatefulWidget {
  const SendMoneyAmountPage({super.key});

  static const double tabletBreakpoint = 600;
  static const double tabletContentMaxWidth = 820;

  @override
  ConsumerState<SendMoneyAmountPage> createState() =>
      _SendMoneyAmountPageState();
}

class _SendMoneyAmountPageState extends ConsumerState<SendMoneyAmountPage> {
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _pinSheetOpen = false;

  get tabletContentMaxWidth => SendMoneyAmountPage.tabletContentMaxWidth;

  num get tabletBreakpoint => SendMoneyAmountPage.tabletBreakpoint;

  @override
  void initState() {
    super.initState();
    final state = ref.read(sendMoneyViewModelProvider);
    _remarkController.text = state.remark ?? '';
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _openPinSheet() async {
    if (_pinSheetOpen || !mounted) return;
    _pinSheetOpen = true;
    _pinController.clear();

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return Consumer(
            builder: (sheetContext, ref, _) {
              final state = ref.watch(sendMoneyViewModelProvider);
              final viewModel = ref.read(sendMoneyViewModelProvider.notifier);
              final colorScheme = Theme.of(sheetContext).colorScheme;
              final isLocked =
                  state.status == SendMoneyStatus.locked &&
                  state.lockoutRemainingMs > 0;
              final isConfirming =
                  state.action == SendMoneyAction.confirm &&
                  state.status == SendMoneyStatus.loading;
              final isConfirmLocked = state.confirmLocked;
              final isConfirmDisabled =
                  isLocked || isConfirming || isConfirmLocked;
              final showError =
                  state.status == SendMoneyStatus.error &&
                  state.errorMessage != null;

              String lockoutText = '';
              if (isLocked) {
                final totalSeconds = (state.lockoutRemainingMs / 1000).ceil();
                final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
                final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
                lockoutText = 'Try again in $minutes:$seconds';
              }

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
                          "Enter PIN",
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: "4-digit PIN",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            ),
                          ),
                        if (showError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              lockoutText,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: isConfirmDisabled ? 0.6 : 1,
                          child: IgnorePointer(
                            ignoring: isConfirmDisabled,
                            child: PrimaryButtonWidget(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                viewModel.confirmTransfer(_pinController.text);
                              },
                              isLoading: isConfirming,
                              text: "CONFIRM",
                            ),
                          ),
                        ),
                        if (isConfirmLocked && !isConfirming)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "Confirmation already submitted. Start a new transfer.",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < tabletBreakpoint;
    final double scale = isPhone ? 1.0 : 1.5;

    final double horizontalPadding = isPhone ? 16 : 44;
    final double sectionSpacing = isPhone ? 16 : 32;
    final double cardRadius = isPhone ? 14 : 18;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;

    final state = ref.watch(sendMoneyViewModelProvider);
    final viewModel = ref.read(sendMoneyViewModelProvider.notifier);
    final isConfirmLocked = state.confirmLocked;
    final isConfirming =
        state.action == SendMoneyAction.confirm &&
        state.status == SendMoneyStatus.loading;

    ref.listen<SendMoneyState>(sendMoneyViewModelProvider, (prev, next) {
      if (prev?.status == next.status) return;

      if (next.status == SendMoneyStatus.error && next.errorMessage != null) {
        if (!_pinSheetOpen) {
          SnackbarUtil.showError(context, next.errorMessage!);
          viewModel.clearStatus();
        }
      }

      if (next.status == SendMoneyStatus.previewSuccess) {
        viewModel.clearStatus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openPinSheet();
        });
      }

      if (next.status == SendMoneyStatus.confirmSuccess) {
        final receiptToPass = next.receipt;

        if (_pinSheetOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          AppRoutes.push(
            context,
            SendMoneySuccessPage(receiptArg: receiptToPass),
          );
          viewModel.resetFlow();
        });

      }
    });

    final recipientName = state.recipient?.fullName.isNotEmpty == true
        ? state.recipient!.fullName
        : "Recipient";
    final recipientPhone = state.recipient?.phoneNumber.isNotEmpty == true
        ? state.recipient!.phoneNumber
        : state.phoneNumber;

    final amountDisplay = state.amountInput.isEmpty ? '0' : state.amountInput;

    final Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: sectionSpacing),

        const BalanceCardWidget(balance: "NPR 12,800.00"),
        SizedBox(height: sectionSpacing),

        Container(
          padding: EdgeInsets.all(isPhone ? 14 : 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipientName,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: isPhone ? 4 : 6),
              Text(
                "Payhive ID : $recipientPhone",
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: sectionSpacing),

        Container(
          padding: EdgeInsets.all(isPhone ? 12 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Send Amount",
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 10 : 30,
                      vertical: isPhone ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Rs. $amountDisplay",
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              Divider(height: isPhone ? 16 : 24),

              TextField(
                controller: _remarkController,
                style: TextStyle(fontSize: 14 * scale),
                decoration: InputDecoration(
                  hintText: "Remarks (optional)",
                  hintStyle: TextStyle(
                    fontSize: 14 * scale,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isPhone ? 12 : 16,
                    horizontal: isPhone ? 8 : 12,
                  ),
                ),
                onChanged: viewModel.setRemark,
              ),
            ],
          ),
        ),
        if (state.warning != null && state.warning!.trim().isNotEmpty) ...[
          SizedBox(height: isPhone ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isPhone ? 12 : 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.warning!,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    final double? keypadWidth = isPhone ? null : 440;

    final Widget keypadSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountKeypadWidget(
          maxWidth: keypadWidth,
          onKeyTap: viewModel.appendAmountKey,
          onBackspace: viewModel.backspaceAmount,
        ),
        SizedBox(height: sectionSpacing),
        SizedBox(
          width: isPhone ? double.infinity : keypadWidth,
          child: Opacity(
            opacity: isConfirmLocked ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: isConfirmLocked,
              child: PrimaryButtonWidget(
                text: "CONTINUE",
                onPressed: () {
                  viewModel.previewTransfer();
                },
                isLoading: state.action == SendMoneyAction.preview,
              ),
            ),
          ),
        ),
        if (isConfirmLocked)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Transfer already submitted. Change amount or start a new transfer.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );

    return WillPopScope(
      onWillPop: () async => !isConfirming,
      child: Scaffold(
        appBar: AppBar(title: const Text("Send Money")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              // vertical: isPhone ? 20 : 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isPhone ? 600 : tabletContentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    formContent,
                    SizedBox(height: sectionSpacing),
                    keypadSection,
                    SizedBox(height: isPhone ? 28 : 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
