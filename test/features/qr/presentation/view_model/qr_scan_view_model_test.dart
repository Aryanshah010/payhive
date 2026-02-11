import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/qr/presentation/view_model/qr_scan_view_model.dart';

void main() {
  group('QrScanViewModel', () {
    test('parses 10 digit number directly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewModel = container.read(qrScanViewModelProvider.notifier);
      expect(viewModel.parsePhoneNumber('9815905635'), '9815905635');
    });

    test('parses number from payhive URI', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewModel = container.read(qrScanViewModelProvider.notifier);
      expect(
        viewModel.parsePhoneNumber('payhive://user?id=9815905635'),
        '9815905635',
      );
    });

    test('does not parse non-payhive URLs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewModel = container.read(qrScanViewModelProvider.notifier);
      expect(
        viewModel.parsePhoneNumber('https://example.com/?phoneNumber=9815905635'),
        isNull,
      );
    });

    test('returns null for invalid QR payload', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewModel = container.read(qrScanViewModelProvider.notifier);
      expect(viewModel.parsePhoneNumber('hello-world'), isNull);
    });

    test('does not parse 10-digit substring from random text', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewModel = container.read(qrScanViewModelProvider.notifier);
      expect(
        viewModel.parsePhoneNumber('hello 9815905635 world'),
        isNull,
      );
    });

    test('throttles repeated invalid scans', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewModel = container.read(qrScanViewModelProvider.notifier);

      final first = viewModel.handleScan('invalid-qr');
      expect(first.invalid, isTrue);

      final second = viewModel.handleScan('invalid-qr');
      expect(second.ignored, isTrue);
    });
  });
}
