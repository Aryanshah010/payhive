import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

void main() {
  group('mapUndoLifecycleAction', () {
    test('maps REJECTED to rejected status', () {
      final status = mapUndoLifecycleAction('REJECTED');
      expect(status, rejectedUndoStatus);
    });

    test('maps UNDO_REJECTED to rejected status', () {
      final status = mapUndoLifecycleAction('UNDO_REJECTED');
      expect(status, rejectedUndoStatus);
    });
  });
}
