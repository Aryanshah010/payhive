import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_success_page.dart';
import 'package:payhive/features/send_money/presentation/widgets/amount_keypad_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/send_money_header.dart';

class SendMoneyAmountPage extends StatelessWidget {
  const SendMoneyAmountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final double horizontalPadding = isTablet ? 32 : 20;
    final double sectionSpacing = isTablet ? 28 : 20;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isTablet ? 12 : 6),
              const SendMoneyHeader(title: "Send Money"),
              SizedBox(height: sectionSpacing),
              const BalanceCardWidget(balance: "NPR 12,800.00"),
              SizedBox(height: sectionSpacing),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "John Doe",
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 2),
                    Text(
                      "Payhive ID : 9872300011",
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 18 : 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
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
                            fontSize: isTablet ? 16 : 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Rs. 120",
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: isTablet ? 24 : 18),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Remarks (optional)",
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              const AmountKeypadWidget(),
              SizedBox(height: sectionSpacing),
              PrimaryButtonWidget(
                onPressed: () {
                  AppRoutes.push(context, const SendMoneySuccessPage());
                },
                text: "CONTINUE",
              ),
              SizedBox(height: isTablet ? 24 : 16),
            ],
          ),
        ),
      ),
    );
  }
}
