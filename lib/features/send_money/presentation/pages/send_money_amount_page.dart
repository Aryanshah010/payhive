import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_success_page.dart';
import 'package:payhive/features/send_money/presentation/widgets/amount_keypad_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';

class SendMoneyAmountPage extends StatelessWidget {
  const SendMoneyAmountPage({super.key});

  static const double tabletBreakpoint = 600;
  static const double tabletContentMaxWidth = 820;

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
                "John Doe",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: isPhone ? 4 : 6),
              Text(
                "Payhive ID : 9872300011",
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
              // header row with badge
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
                      "Rs. 120",
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
              ),
            ],
          ),
        ),
      ],
    );

    // --- Keypad (phone-like, just larger on tablet) ---
    final double? keypadWidth = isPhone ? null : 440;

    final Widget keypadSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountKeypadWidget(maxWidth: keypadWidth),
        SizedBox(height: sectionSpacing),
        SizedBox(
          width: isPhone ? double.infinity : keypadWidth,
          child: PrimaryButtonWidget(
            text: "CONTINUE",
            onPressed: () {
              AppRoutes.push(context, const SendMoneySuccessPage());
            },
          ),
        ),
      ],
    );

    return Scaffold(
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
    );
  }
}
