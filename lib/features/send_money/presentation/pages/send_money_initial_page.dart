import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_amount_page.dart';
import 'package:payhive/features/send_money/presentation/widgets/balance_card_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/send_money_header.dart';

class SendMoneyInitialPage extends StatelessWidget {
  const SendMoneyInitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

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
              SizedBox(height: sectionSpacing),
              Text(
                "PayHive ID",
                style: TextStyle(
                  fontSize: isTablet ? 18 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isTablet ? 10 : 6),
              TextField(
                decoration: InputDecoration(
                  hintText: "Mobile Number",
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.greyText),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
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
