import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:payhive/features/profile/presentation/pages/pin_management_page.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class PinSetupGatePage extends ConsumerStatefulWidget {
  const PinSetupGatePage({super.key});

  @override
  ConsumerState<PinSetupGatePage> createState() => _PinSetupGatePageState();
}

class _PinSetupGatePageState extends ConsumerState<PinSetupGatePage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  void _goToDashboard() {
    if (_navigated) return;
    _navigated = true;
    AppRoutes.pushAndRemoveUntil(context, const DashboardScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);

    if (profileState.status == ProfileStatus.loaded && profileState.hasPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToDashboard());
    }

    if (profileState.status == ProfileStatus.updated && profileState.hasPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToDashboard());
    }

    if (profileState.status == ProfileStatus.loaded && !profileState.hasPin) {
      return WillPopScope(
        onWillPop: () async => false,
        child: PinManagementPage(
          hasPin: false,
          isForced: true,
          onSuccess: _goToDashboard,
        ),
      );
    }

    if (profileState.status == ProfileStatus.error) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(
                    profileState.errorMessage ?? 'Failed to load profile.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButtonWidget(
                    onPressed: () {
                      ref.read(profileViewModelProvider.notifier).loadProfile();
                    },
                    text: 'Retry',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
