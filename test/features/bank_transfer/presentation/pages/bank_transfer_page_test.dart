import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';
import 'package:payhive/features/bank_transfer/domain/usecases/bank_transfer_usecase.dart';
import 'package:payhive/features/bank_transfer/presentation/pages/bank_transfer_page.dart';
import 'package:payhive/features/bank_transfer/presentation/pages/bank_transfer_success_page.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class MockPreviewBankTransferUsecase extends Mock
    implements PreviewBankTransferUsecase {}

class MockConfirmBankTransferUsecase extends Mock
    implements ConfirmBankTransferUsecase {}

class MockGetBanksUsecase extends Mock implements GetBanksUsecase {}

class FakeProfileViewModel extends ProfileViewModel {
  @override
  ProfileState build() {
    return const ProfileState(
      status: ProfileStatus.loaded,
      fullName: 'Test User',
      phoneNumber: '9800000000',
      email: 'test@payhive.com',
      balance: 5000,
    );
  }

  @override
  Future<void> refreshProfile() async {}
}

const List<BankEntity> sampleBanks = [
  BankEntity(
    id: 'bank-1',
    name: 'Nabil Bank',
    code: 'NABIL',
    minTransfer: 10,
    maxTransfer: 50000,
    fee: 10,
  ),
];

void main() {
  late MockPreviewBankTransferUsecase mockPreviewUsecase;
  late MockConfirmBankTransferUsecase mockConfirmUsecase;
  late MockGetBanksUsecase mockGetBanksUsecase;

  setUpAll(() {
    registerFallbackValue(
      const PreviewBankTransferParams(
        bankName: 'NABIL',
        accountNumber: '1234567890',
        amount: 100,
      ),
    );
    registerFallbackValue(
      const ConfirmBankTransferParams(
        bankName: 'NABIL',
        accountNumber: '1234567890',
        amount: 100,
        pin: '1234',
      ),
    );
  });

  setUp(() {
    mockPreviewUsecase = MockPreviewBankTransferUsecase();
    mockConfirmUsecase = MockConfirmBankTransferUsecase();
    mockGetBanksUsecase = MockGetBanksUsecase();
    when(
      () => mockGetBanksUsecase(),
    ).thenAnswer((_) async => const Right(sampleBanks));
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(() => FakeProfileViewModel()),
          previewBankTransferUsecaseProvider.overrideWithValue(
            mockPreviewUsecase,
          ),
          confirmBankTransferUsecaseProvider.overrideWithValue(
            mockConfirmUsecase,
          ),
          getBanksUsecaseProvider.overrideWithValue(mockGetBanksUsecase),
        ],
        child: const MaterialApp(home: BankTransferPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  PreviewEntity makePreview({String? warning}) {
    return PreviewEntity(
      recipient: const RecipientEntity(
        id: 'preview',
        fullName: 'Beneficiary',
        phoneNumber: '',
      ),
      warning: warning,
    );
  }

  ReceiptEntity makeReceipt() {
    return ReceiptEntity(
      txId: 'txn-1',
      status: 'SUCCESS',
      amount: 100,
      remark: 'Bank transfer',
      paymentType: 'BANK_TRANSFER',
      meta: const {'bankName': 'Nabil Bank', 'accountNumber': '1234567890'},
      from: const RecipientEntity(
        id: 'sender',
        fullName: 'Sender',
        phoneNumber: '9800000000',
      ),
      to: const RecipientEntity(
        id: 'receiver',
        fullName: 'Receiver',
        phoneNumber: '',
      ),
      createdAt: DateTime(2026, 1, 1, 12, 0),
      direction: 'DEBIT',
    );
  }

  testWidgets('renders fields and continue button', (tester) async {
    await pumpPage(tester);

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('shows validation feedback from preview failure', (tester) async {
    when(() => mockPreviewUsecase(any())).thenAnswer(
      (_) async => const Left(
        ValidationFailure(message: 'Bank name must be at least 2 characters.'),
      ),
    );

    await pumpPage(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nabil Bank').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bank name must be at least 2 characters.'),
      findsOneWidget,
    );
    verify(() => mockPreviewUsecase(any())).called(1);
  });

  testWidgets('completes success transition to receipt page', (tester) async {
    when(
      () => mockPreviewUsecase(any()),
    ).thenAnswer((_) async => Right(makePreview()));
    when(
      () => mockConfirmUsecase(any()),
    ).thenAnswer((_) async => Right(makeReceipt()));

    await pumpPage(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nabil Bank').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.ensureVisible(find.text('1').first);
    await tester.tap(find.text('1').first);
    await tester.pump();

    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Enter PIN'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();

    expect(find.byType(BankTransferSuccessPage), findsOneWidget);
    expect(find.text('Bank Transfer Success!'), findsOneWidget);
    verify(() => mockPreviewUsecase(any())).called(1);
    verify(() => mockConfirmUsecase(any())).called(1);
  });
}
