import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/presentation/widgets/statement_item_tile.dart';

void main() {
  ReceiptEntity makeReceipt({
    required String direction,
    String fromId = 'me-id',
    String toId = 'to-id',
    String fromName = 'Me',
    String toName = 'Receiver',
    String fromPhone = '9800000001',
    String toPhone = '9800000002',
    String? paymentType,
    String? remark = 'Lunch',
  }) {
    return ReceiptEntity(
      txId: 'tx-1',
      status: 'SUCCESS',
      amount: 150,
      remark: remark,
      paymentType: paymentType,
      from: RecipientEntity(
        id: fromId,
        fullName: fromName,
        phoneNumber: fromPhone,
      ),
      to: RecipientEntity(id: toId, fullName: toName, phoneNumber: toPhone),
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

  testWidgets('service self-transfer debit shows Service Payment and no undo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatementItemTile(
            transaction: makeReceipt(
              direction: 'DEBIT',
              fromId: 'self-id',
              toId: 'self-id',
            ),
            currentUserId: 'self-id',
            onUndoTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Service Payment'), findsOneWidget);
    expect(find.text('UNDO'), findsNothing);
  });

  testWidgets('service paymentType debit shows Service Payment and no undo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatementItemTile(
            transaction: makeReceipt(
              direction: 'DEBIT',
              paymentType: 'BOOKING_PAYMENT',
            ),
            currentUserId: 'me-id',
            onUndoTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Service Payment'), findsOneWidget);
    expect(find.text('UNDO'), findsNothing);
  });

  testWidgets('service remark debit shows Service Payment and no undo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatementItemTile(
            transaction: makeReceipt(
              direction: 'DEBIT',
              remark: 'Booking payment',
            ),
            currentUserId: 'me-id',
            onUndoTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Service Payment'), findsOneWidget);
    expect(find.text('UNDO'), findsNothing);
  });

  testWidgets('normal debit keeps transfer title and undo action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatementItemTile(
            transaction: makeReceipt(direction: 'DEBIT'),
            currentUserId: 'me-id',
            onUndoTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Fund transferred to Receiver'), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
  });
}
