import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';

class MockGetTransactionDetailUsecase extends Mock
    implements GetTransactionDetailUsecase {}

void main() {
  late MockGetTransactionDetailUsecase mockUsecase;

  setUpAll(() {
    registerFallbackValue(const DetailParams(txId: 'fallback'));
  });

  setUp(() {
    mockUsecase = MockGetTransactionDetailUsecase();
  });

  ReceiptEntity receipt() {
    return ReceiptEntity(
      txId: 'tx-1',
      status: 'SUCCESS',
      amount: 250,
      remark: 'Rent',
      from: const RecipientEntity(
        id: 'from-id',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      to: const RecipientEntity(
        id: 'to-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      createdAt: DateTime(2026, 1, 1, 12, 0),
      direction: 'DEBIT',
    );
  }

  testWidgets('renders detail content with status chip and actions', (
    tester,
  ) async {
    final data = receipt();
    when(() => mockUsecase(any())).thenAnswer((_) async => Right(data));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getTransactionDetailUsecaseProvider.overrideWithValue(mockUsecase),
        ],
        child: MaterialApp(
          home: StatementDetailPage(txId: data.txId, initialReceipt: data),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transaction Detail'), findsOneWidget);
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Complete'), findsWidgets);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Transaction ID'), findsOneWidget);
  });
}
