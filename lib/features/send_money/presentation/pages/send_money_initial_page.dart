import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_amount_page.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/receiver_chip.dart';
import 'package:payhive/features/send_money/presentation/widgets/send_money_header.dart';

class SendMoneyInitialPage extends StatelessWidget {
  const SendMoneyInitialPage({super.key});

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
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Frequent fund receiver",
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: isTablet ? 18 : 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Wrap(
                      spacing: isTablet ? 16 : 12,
                      runSpacing: isTablet ? 12 : 8,
                      children: const [
                        ReceiverChip(name: "John Doe"),
                        ReceiverChip(name: "Jane"),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              Text(
                "PayHive ID",
                style: textTheme.titleSmall?.copyWith(
                  fontSize: isTablet ? 18 : 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: isTablet ? 10 : 6),
              TextField(
                decoration: InputDecoration(
                  hintText: "Mobile Number",
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              SizedBox(height: sectionSpacing),
              PrimaryButtonWidget(
                onPressed: () {
                  AppRoutes.push(context, const SendMoneyAmountPage());
                },
                text: "PROCEED",
              ),
              SizedBox(height: isTablet ? 24 : 16),
            ],
          ),
        ),
      ),
    );
  }
}
