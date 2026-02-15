import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_amount_page.dart';
import 'package:payhive/features/send_money/presentation/state/send_money_state.dart';
import 'package:payhive/features/send_money/presentation/view_model/send_money_view_model.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';

class SendMoneyInitialPage extends ConsumerStatefulWidget {
  const SendMoneyInitialPage({super.key});

  static const double tabletBreakpoint = 600;
  static const double wideBreakpoint = 900;
  static const double tabletContentMaxWidth = 820;

  @override
  ConsumerState<SendMoneyInitialPage> createState() =>
      _SendMoneyInitialPageState();
}

class _SendMoneyInitialPageState extends ConsumerState<SendMoneyInitialPage> {
  final TextEditingController _phoneController = TextEditingController();

  num get tabletBreakpoint => SendMoneyInitialPage.tabletBreakpoint;

  num get wideBreakpoint => SendMoneyInitialPage.wideBreakpoint;

  get tabletContentMaxWidth => SendMoneyInitialPage.tabletContentMaxWidth;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(sendMoneyViewModelProvider.notifier).resetFlow();
    });

    _phoneController.text = '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= tabletBreakpoint;
    final isPhone = width < tabletBreakpoint;
    final isTabletNarrow = width >= tabletBreakpoint && width < wideBreakpoint;
    final double scale = isPhone ? 1.0 : 1.5;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final state = ref.watch(sendMoneyViewModelProvider);
    final viewModel = ref.read(sendMoneyViewModelProvider.notifier);
    final profileState = ref.watch(profileViewModelProvider);
    final balanceText = formatNpr(profileState.balance ?? 0);

    ref.listen<SendMoneyState>(sendMoneyViewModelProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;

      if (next.status == SendMoneyStatus.error && next.errorMessage != null) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearStatus();
      }

      if (next.status == SendMoneyStatus.lookupSuccess) {
        viewModel.clearStatus();
        AppRoutes.push(context, const SendMoneyAmountPage());
      }
    });

    final double horizontalPadding = isPhone ? 20 : (isTabletNarrow ? 40 : 52);
    final double sectionSpacing = isPhone ? 20 : (isTabletNarrow ? 28 : 32);

    return Scaffold(
      appBar: AppBar(title: const Text("Send Money")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isPhone ? 600 : tabletContentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sectionSpacing),
                  BalanceCardWidget(balance: balanceText),
                  SizedBox(height: sectionSpacing),
                  Text(
                    "PayHive ID",
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 6),
                  TextField(
                    controller: _phoneController,
                    style: TextStyle(fontSize: 14 * scale),
                    decoration: InputDecoration(
                      hintText: "Mobile Number",
                      hintStyle: TextStyle(
                        fontSize: 14 * scale,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                        horizontal: 12,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: viewModel.setPhoneNumber,
                  ),
                  SizedBox(height: sectionSpacing),
                  PrimaryButtonWidget(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      viewModel.lookupBeneficiary();
                    },
                    isLoading: state.action == SendMoneyAction.lookup,
                    text: "PROCEED",
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
