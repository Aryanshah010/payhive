import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/presentation/widgets/statement_item_tile.dart';

void main() {
  ReceiptEntity makeReceipt({required String direction}) {
    return ReceiptEntity(
      txId: 'tx-1',
      status: 'SUCCESS',
      amount: 150,
      remark: 'Lunch',
      from: const RecipientEntity(
        id: 'me-id',
        fullName: 'Me',
        phoneNumber: '9800000001',
      ),
      to: const RecipientEntity(
        id: 'to-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      createdAt: DateTime(2026, 1, 1),
      direction: direction,
    );
  }

  testWidgets('tapping tile triggers onTap callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatementItemTile(
            transaction: makeReceipt(direction: 'DEBIT'),
            currentUserId: 'me-id',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(StatementItemTile));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
