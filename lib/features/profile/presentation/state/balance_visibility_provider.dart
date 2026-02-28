import 'package:flutter_riverpod/flutter_riverpod.dart';

final balanceVisibilityProvider =
    NotifierProvider<BalanceVisibilityNotifier, bool>(
      BalanceVisibilityNotifier.new,
    );

class BalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}
