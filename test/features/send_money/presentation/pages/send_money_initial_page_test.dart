import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/send_money/domain/usecases/send_money_usecase.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_amount_page.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_initial_page.dart';
import 'package:payhive/features/send_money/presentation/view_model/send_money_view_model.dart';

class MockPreviewTransferUsecase extends Mock
    implements PreviewTransferUsecase {}

class MockConfirmTransferUsecase extends Mock
    implements ConfirmTransferUsecase {}

class MockLookupBeneficiaryUsecase extends Mock
    implements LookupBeneficiaryUsecase {}

class _FakeProfileViewModel extends ProfileViewModel {
  @override
  ProfileState build() {
    return const ProfileState(
      status: ProfileStatus.loaded,
      fullName: 'Tester',
      phoneNumber: '9800000000',
      email: 'tester@example.com',
      balance: 5000,
      hasPin: true,
    );
  }
}

void main() {
  late MockPreviewTransferUsecase mockPreviewUsecase;
  late MockConfirmTransferUsecase mockConfirmUsecase;
  late MockLookupBeneficiaryUsecase mockLookupUsecase;

  setUpAll(() {
    registerFallbackValue(
      const PreviewTransferParams(toPhoneNumber: '9800000001', amount: 100),
    );
    registerFallbackValue(
      const ConfirmTransferParams(
        toPhoneNumber: '9800000001',
        amount: 100,
        pin: '1234',
      ),
    );
    registerFallbackValue(
      const LookupBeneficiaryParams(phoneNumber: '9800000001'),
    );
  });

  setUp(() {
    mockPreviewUsecase = MockPreviewTransferUsecase();
    mockConfirmUsecase = MockConfirmTransferUsecase();
    mockLookupUsecase = MockLookupBeneficiaryUsecase();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    SendMoneyPrefillArgs? prefill,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          previewTransferUsecaseProvider.overrideWithValue(mockPreviewUsecase),
          confirmTransferUsecaseProvider.overrideWithValue(mockConfirmUsecase),
          lookupBeneficiaryUsecaseProvider.overrideWithValue(mockLookupUsecase),
          profileViewModelProvider.overrideWith(() => _FakeProfileViewModel()),
        ],
        child: MaterialApp(home: SendMoneyInitialPage(prefill: prefill)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'prefill populates values and auto-lookups when autoLookup is true',
    (tester) async {
      when(() => mockLookupUsecase(any())).thenAnswer(
        (_) async => const Right(
          RecipientEntity(
            id: 'recipient-1',
            fullName: 'Receiver',
            phoneNumber: '9800000002',
          ),
        ),
      );

      await pumpPage(
        tester,
        prefill: const SendMoneyPrefillArgs(
          phoneNumber: '9800000002',
          amountInput: '120.50',
          remark: 'Rent',
          autoLookup: true,
          sourceMoneyRequestId: 'mr-1',
        ),
      );

      verify(
        () => mockLookupUsecase(
          const LookupBeneficiaryParams(phoneNumber: '9800000002'),
        ),
      ).called(1);
      expect(find.byType(SendMoneyAmountPage), findsOneWidget);
      expect(find.text('Rs. 120.50'), findsOneWidget);
    },
  );

  testWidgets('no prefill keeps manual flow unchanged', (tester) async {
    await pumpPage(tester);

    expect(find.byType(SendMoneyInitialPage), findsOneWidget);
    verifyNever(() => mockLookupUsecase(any()));
  });

  testWidgets('prefill stores source money request id in send money state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          previewTransferUsecaseProvider.overrideWithValue(mockPreviewUsecase),
          confirmTransferUsecaseProvider.overrideWithValue(mockConfirmUsecase),
          lookupBeneficiaryUsecaseProvider.overrideWithValue(mockLookupUsecase),
          profileViewModelProvider.overrideWith(() => _FakeProfileViewModel()),
        ],
        child: const MaterialApp(
          home: SendMoneyInitialPage(
            prefill: SendMoneyPrefillArgs(
              phoneNumber: '9800000002',
              sourceMoneyRequestId: 'mr-42',
              autoLookup: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SendMoneyInitialPage)),
    );
    final state = container.read(sendMoneyViewModelProvider);
    expect(state.sourceMoneyRequestId, 'mr-42');
  });
}
