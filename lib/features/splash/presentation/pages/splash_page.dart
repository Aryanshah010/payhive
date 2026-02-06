import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:payhive/features/onboarding/presentation/pages/onboarding_screen.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _startFlow();
  }

  Future<void> _startFlow() async {
    final userSessionService = ref.read(userSessionServiceProvider);

    final Future<void> animationFuture = _controller.forward().then((_) {});

    final Future<bool> sessionFuture = Future.microtask(
      () => userSessionService.isLoggedIn(),
    );

    final Future<void> minDuration = Future.delayed(
      const Duration(milliseconds: 600),
    );

    final results = await Future.wait([
      animationFuture,
      sessionFuture,
      minDuration,
    ]);

    if (!mounted) return;

    final isLoggedIn = results[1] as bool;

    if (isLoggedIn) {
      AppRoutes.pushReplacement(context, const DashboardScreen());
    } else {
      AppRoutes.pushReplacement(context, const OnboardingScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minSide = MediaQuery.of(context).size.shortestSide;

    final logoSize = minSide < 600 ? minSide * 0.75 : minSide * 0.50;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/images/payhive.png',
                width: logoSize,
                fit: BoxFit.contain,
                semanticLabel: 'Payhive logo',

                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.account_balance_wallet,
                    size: 120,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
