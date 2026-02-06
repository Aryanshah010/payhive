import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_amount_page.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';

class SendMoneyInitialPage extends StatelessWidget {
  const SendMoneyInitialPage({super.key});

  static const double tabletBreakpoint = 600;
  static const double wideBreakpoint = 900;
  static const double tabletContentMaxWidth = 820;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= tabletBreakpoint;
    final isPhone = width < tabletBreakpoint;
    final isTabletNarrow = width >= tabletBreakpoint && width < wideBreakpoint;
    final double scale = isPhone ? 1.0 : 1.5;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  const BalanceCardWidget(balance: "NPR 12,800.00"),
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
                  ),
                  SizedBox(height: sectionSpacing),
                  PrimaryButtonWidget(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      AppRoutes.push(context, const SendMoneyAmountPage());
                    },
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
