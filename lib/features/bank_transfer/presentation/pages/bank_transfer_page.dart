import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';
import 'package:payhive/features/bank_transfer/presentation/pages/bank_transfer_success_page.dart';
import 'package:payhive/features/bank_transfer/presentation/state/bank_transfer_state.dart';
import 'package:payhive/features/bank_transfer/presentation/view_model/bank_transfer_view_model.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/send_money/presentation/widgets/amount_keypad_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';

class BankTransferPage extends ConsumerStatefulWidget {
  const BankTransferPage({super.key});

  static const double tabletBreakpoint = 600;
  static const double tabletContentMaxWidth = 820;

  @override
  ConsumerState<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends ConsumerState<BankTransferPage> {
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _pinSheetOpen = false;

  get tabletContentMaxWidth => BankTransferPage.tabletContentMaxWidth;

  num get tabletBreakpoint => BankTransferPage.tabletBreakpoint;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bankTransferViewModelProvider);
    _accountNumberController.text = state.accountNumber;
    Future.microtask(() {
      if (!mounted) return;
      ref.read(bankTransferViewModelProvider.notifier).loadBanks();
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
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
              final state = ref.watch(bankTransferViewModelProvider);
              final viewModel = ref.read(
                bankTransferViewModelProvider.notifier,
              );
              final colorScheme = Theme.of(sheetContext).colorScheme;
              final isLocked =
                  state.status == BankTransferStatus.locked &&
                  state.lockoutRemainingMs > 0;
              final isConfirming =
                  state.action == BankTransferAction.confirm &&
                  state.status == BankTransferStatus.loading;
              final isConfirmLocked = state.confirmLocked;
              final isConfirmDisabled =
                  isLocked || isConfirming || isConfirmLocked;
              final showError =
                  state.status == BankTransferStatus.error &&
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

    final state = ref.watch(bankTransferViewModelProvider);
    final viewModel = ref.read(bankTransferViewModelProvider.notifier);
    final profileState = ref.watch(profileViewModelProvider);
    final balanceText = formatNpr(profileState.balance ?? 0);
    final isConfirmLocked = state.confirmLocked;
    final isConfirming =
        state.action == BankTransferAction.confirm &&
        state.status == BankTransferStatus.loading;

    ref.listen<BankTransferState>(bankTransferViewModelProvider, (prev, next) {
      if (prev?.status == next.status) return;

      if (next.status == BankTransferStatus.error &&
          next.errorMessage != null) {
        if (!_pinSheetOpen) {
          SnackbarUtil.showError(context, next.errorMessage!);
          viewModel.clearStatus();
        }
      }

      if (next.status == BankTransferStatus.previewSuccess) {
        viewModel.clearStatus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openPinSheet();
        });
      }

      if (next.status == BankTransferStatus.confirmSuccess) {
        final receiptToPass = next.receipt;
        ref.read(profileViewModelProvider.notifier).refreshProfile();

        if (_pinSheetOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (receiptToPass == null) return;
          AppRoutes.push(
            context,
            BankTransferSuccessPage(receipt: receiptToPass),
          );
          viewModel.resetFlow();
        });
      }
    });

    final amountDisplay = state.amountInput.isEmpty ? '0' : state.amountInput;
    final banks = state.banks;
    final selectedBank = _resolveSelectedBank(state.bankName, banks);
    final hasBank = selectedBank != null;
    final canContinue = hasBank && !isConfirmLocked;

    final Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: sectionSpacing),

        BalanceCardWidget(balance: balanceText),
        SizedBox(height: sectionSpacing),

        Container(
          padding: EdgeInsets.all(isPhone ? 12 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Bank",
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (state.bankListStatus == BankListStatus.loading ||
                  state.bankListStatus == BankListStatus.idle)
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Loading banks...",
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                )
              else if (state.bankListStatus == BankListStatus.error)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.bankListError?.trim().isNotEmpty == true
                            ? state.bankListError!
                            : "Failed to load banks.",
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => viewModel.loadBanks(force: true),
                      child: const Text("Retry"),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedBank?.code,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: banks.isEmpty
                        ? "No banks available"
                        : "Select bank",
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isPhone ? 12 : 16,
                      horizontal: isPhone ? 8 : 12,
                    ),
                  ),
                  items: banks
                      .map(
                        (bank) => DropdownMenuItem<String>(
                          value: bank.code,
                          child: Text(bank.name),
                        ),
                      )
                      .toList(),
                  onChanged: banks.isEmpty
                      ? null
                      : (value) {
                          if (value == null) return;
                          viewModel.setBankName(value);
                        },
                ),
              if (selectedBank != null) ...[
                const SizedBox(height: 8),
                Text(
                  "Min ${formatNpr(selectedBank.minTransfer)} • "
                  "Max ${formatNpr(selectedBank.maxTransfer)} • "
                  "Fee ${formatNpr(selectedBank.fee)}",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: isPhone ? 12 : 16),
              Text(
                "Account Number",
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _accountNumberController,
                style: TextStyle(fontSize: 14 * scale),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "Enter account number",
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isPhone ? 12 : 16,
                    horizontal: isPhone ? 8 : 12,
                  ),
                ),
                onChanged: viewModel.setAccountNumber,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transfer Amount",
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
            opacity: canContinue ? 1 : 0.6,
            child: IgnorePointer(
              ignoring: !canContinue,
              child: PrimaryButtonWidget(
                text: "CONTINUE",
                onPressed: viewModel.previewTransfer,
                isLoading: state.action == BankTransferAction.preview,
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
        appBar: AppBar(title: const Text("Bank Transfer")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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

BankEntity? _resolveSelectedBank(String value, List<BankEntity> banks) {
  if (value.trim().isEmpty) return null;

  for (final bank in banks) {
    if (bank.code == value) return bank;
  }
  for (final bank in banks) {
    if (bank.name == value) return bank;
  }
  return null;
}
