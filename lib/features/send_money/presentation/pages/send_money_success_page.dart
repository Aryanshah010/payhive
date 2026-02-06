import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/view_model/send_money_view_model.dart';
import 'package:payhive/features/send_money/presentation/widgets/info_row.dart';

class SendMoneySuccessPage extends ConsumerWidget {
  const SendMoneySuccessPage({super.key});

  static const double tabletBreakpoint = 600;
  static const double wideBreakpoint = 900;
  static const double tabletContentMaxWidth = 820;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= tabletBreakpoint;
    final isPhone = width < tabletBreakpoint;
    final isTabletNarrow = width >= tabletBreakpoint && width < wideBreakpoint;
    final double scale = isPhone ? 1.0 : 1.5;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;

    final state = ref.watch(sendMoneyViewModelProvider);
    final receipt = state.receipt;
    final dateText = receipt != null
        ? DateFormat('dd MMMM yyyy hh:mm a').format(receipt.createdAt)
        : '--';

    final fromName = receipt?.from.fullName ?? 'Sender';
    final toName = receipt?.to.fullName ?? 'Receiver';
    final fromPhone = receipt?.from.phoneNumber ?? '';
    final toPhone = receipt?.to.phoneNumber ?? '';
    final txId = receipt?.txId ?? '--';
    final amountText =
        receipt != null ? receipt.amount.toStringAsFixed(2) : '--';
    final remarkText =
        (receipt?.remark?.isNotEmpty ?? false) ? receipt!.remark! : '--';

    final double horizontalPadding = isPhone ? 16 : (isTabletNarrow ? 44 : 52);
    final double sectionSpacing = isPhone ? 16 : (isTabletNarrow ? 28 : 32);
    final double successBoxSize = isPhone ? 72 : 96;
    final double successIconSize = isPhone ? 36 : 52;

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
                  Center(
                    child: Container(
                      width: successBoxSize,
                      height: successBoxSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: Icon(
                        Icons.check,
                        color: colorScheme.onPrimary,
                        size: successIconSize,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 18 : 12),
                  Center(
                    child: Text(
                      "Payment Success!",
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.share, size: isTablet ? 20 : 18),
                          label: Text(
                            "Share",
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 12,
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
                          icon: Icon(Icons.download, size: isTablet ? 20 : 18),
                          label: Text(
                            "PDF",
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 12,
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
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Column(
                      children: [
                        InfoRow(label: "From", value: fromName),
                        InfoRow(label: "To", value: toName),
                        InfoRow(label: "Transaction ID", value: txId),
                        InfoRow(label: "Date&Time", value: dateText),
                        InfoRow(label: "Amount(NPR)", value: amountText),
                        InfoRow(label: "Remarks", value: remarkText),
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
                                      fontSize: 12 * scale,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    toPhone.isNotEmpty ? toPhone : "--",
                                    style: TextStyle(
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
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
                                      fontSize: 12 * scale,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromPhone.isNotEmpty ? fromPhone : "--",
                                    style: TextStyle(
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
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
                    onPressed: () {
                      ref.read(sendMoneyViewModelProvider.notifier).resetFlow();
                      AppRoutes.popToFirst(context);
                    },
                    text: "DONE",
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
