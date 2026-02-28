import 'package:payhive/features/statement/data/models/statement_api_model.dart';

abstract interface class IStatementRemoteDatasource {
  Future<TransactionHistoryApiModel> getHistory({
    required int page,
    required int limit,
    String search,
    String direction,
  });

  Future<StatementReceiptApiModel> getDetail({required String txId});

  Future<UndoRequestApiModel> createUndoRequest({required String txId});

  Future<AcceptUndoResultApiModel> acceptUndoRequest({
    required String requestId,
    required String pin,
  });

  Future<UndoRequestApiModel> rejectUndoRequest({required String requestId});
}
