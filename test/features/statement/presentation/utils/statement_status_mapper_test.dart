import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/core/utils/statement_status_mapper.dart';

void main() {
  group('mapStatementStatus', () {
    test('maps SUCCESS to Complete', () {
      final status = mapStatementStatus('SUCCESS');

      expect(status.label, 'Complete');
      expect(status.type, StatementStatusType.complete);
      expect(status.color, Colors.green);
    });

    test('maps PENDING to Pending', () {
      final status = mapStatementStatus('PENDING');

      expect(status.label, 'Pending');
      expect(status.type, StatementStatusType.pending);
      expect(status.color, Colors.amber);
    });

    test('maps rejected statuses to Payment Rejected', () {
      final rejected = mapStatementStatus('UNDO_REJECTED');
      final failed = mapStatementStatus('FAILED');

      expect(rejected.label, 'Payment Rejected');
      expect(rejected.type, StatementStatusType.paymentRejected);
      expect(failed.label, 'Payment Rejected');
      expect(failed.type, StatementStatusType.paymentRejected);
      expect(rejected.color, Colors.red);
    });

    test('defaults unknown/null status to Complete', () {
      final unknown = mapStatementStatus('SOMETHING_NEW');
      final empty = mapStatementStatus(null);

      expect(unknown.label, 'Complete');
      expect(unknown.type, StatementStatusType.complete);
      expect(empty.label, 'Complete');
      expect(empty.type, StatementStatusType.complete);
    });
  });
}
