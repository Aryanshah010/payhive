import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/profile/domain/usecases/set_pin_usecase.dart';
import 'package:payhive/features/profile/presentation/state/pin_state.dart';

final pinViewModelProvider = NotifierProvider<PinViewModel, PinState>(
  () => PinViewModel(),
);

class PinViewModel extends Notifier<PinState> {
  late final SetPinUsecase _setPinUsecase;

  @override
  PinState build() {
    _setPinUsecase = ref.read(setPinUsecaseProvider);
    return const PinState();
  }

  void clearStatus() {
    state = const PinState();
  }

  Future<void> submitPin({required String newPin, String? oldPin}) async {
    state = state.copyWith(status: PinStatus.loading, errorMessage: null);

    final params = SetPinParams(newPin: newPin, oldPin: oldPin);
    final result = await _setPinUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PinStatus.error,
          errorMessage: failure.message,
        );
      },
      (success) {
        state = state.copyWith(
          status: PinStatus.success,
          errorMessage: null,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
