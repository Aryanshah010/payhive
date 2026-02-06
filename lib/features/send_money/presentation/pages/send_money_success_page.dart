import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/info_row.dart';
import 'package:payhive/features/send_money/presentation/widgets/send_money_header.dart';

class SendMoneySuccessPage extends StatelessWidget {
  const SendMoneySuccessPage({super.key});

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
            children: [
              SizedBox(height: isTablet ? 12 : 6),
              const SendMoneyHeader(title: "Send Money"),
              SizedBox(height: sectionSpacing),
              Container(
                width: isTablet ? 90 : 72,
                height: isTablet ? 90 : 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: isTablet ? 48 : 36,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                "Payment Success!",
                style: TextStyle(
                  fontSize: isTablet ? 26 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: sectionSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("Share"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkText,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("PDF"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkText,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  children: [
                    const InfoRow(label: "From", value: "John Doe"),
                    const InfoRow(label: "To", value: "Jane"),
                    const InfoRow(label: "Transaction ID", value: "16A579HYC"),
                    const InfoRow(
                      label: "Date&Time",
                      value: "12 November 2025 04:26 pm",
                    ),
                    const InfoRow(label: "Amount(NPR)", value: "4934.08"),
                    const InfoRow(label: "Remarks", value: "Paid"),
                    Divider(height: isTablet ? 28 : 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Receiver Payhive Id:",
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "9871000000",
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Sender Payhive Id:",
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "9872300011",
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              PrimaryButtonWidget(
                // Send-money flow is pushed from Home; popping to the first route returns to Home/Dashboard.
                onPressed: () => AppRoutes.popToFirst(context),
                text: "DONE",
              ),
              SizedBox(height: isTablet ? 24 : 16),
            ],
          ),
        ),
      ),
    );
  }
}
