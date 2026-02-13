import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';

class StatementRecipientApiModel {
  final String id;
  final String fullName;
  final String phoneNumber;

  StatementRecipientApiModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  factory StatementRecipientApiModel.fromJson(Map<String, dynamic> json) {
    return StatementRecipientApiModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
    );
  }

  RecipientEntity toEntity() {
    return RecipientEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}

class StatementReceiptApiModel {
  final String txId;
  final String status;
  final double amount;
  final String? remark;
  final StatementRecipientApiModel from;
  final StatementRecipientApiModel to;
  final DateTime createdAt;
  final String? direction;

  StatementReceiptApiModel({
    required this.txId,
    required this.status,
    required this.amount,
    this.remark,
    required this.from,
    required this.to,
    required this.createdAt,
    this.direction,
  });

  factory StatementReceiptApiModel.fromJson(Map<String, dynamic> json) {
    return StatementReceiptApiModel(
      txId: (json['txId'] ?? json['_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: _parseAmount(json['amount']),
      remark: json['remark']?.toString(),
      from: StatementRecipientApiModel.fromJson(
        (json['from'] ?? {}) as Map<String, dynamic>,
      ),
      to: StatementRecipientApiModel.fromJson(
        (json['to'] ?? {}) as Map<String, dynamic>,
      ),
      createdAt: _parseDate(json['createdAt']),
      direction: json['direction']?.toString(),
    );
  }

  ReceiptEntity toEntity() {
    return ReceiptEntity(
      txId: txId,
      status: status,
      amount: amount,
      remark: remark,
      from: from.toEntity(),
      to: to.toEntity(),
      createdAt: createdAt,
      direction: direction,
    );
  }
}

class PaginationApiModel {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  PaginationApiModel({this.page, this.limit, this.total, this.totalPages});

  factory PaginationApiModel.fromJson(Map<String, dynamic> json) {
    return PaginationApiModel(
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      total: _parseInt(json['total']),
      totalPages: _parseInt(json['totalPages']),
    );
  }

  PaginationEntity toEntity() {
    return PaginationEntity(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }
}

class TransactionHistoryApiModel {
  final List<StatementReceiptApiModel> transactions;
  final PaginationApiModel? pagination;

  TransactionHistoryApiModel({required this.transactions, this.pagination});

  factory TransactionHistoryApiModel.fromJson(dynamic json) {
    List<dynamic> items = [];
    PaginationApiModel? pagination;

    if (json is List) {
      items = json;
    } else if (json is Map<String, dynamic>) {
      if (json['transactions'] is List) {
        items = json['transactions'] as List<dynamic>;
      } else if (json['items'] is List) {
        items = json['items'] as List<dynamic>;
      } else if (json['data'] is List) {
        items = json['data'] as List<dynamic>;
      } else if (json['data'] is Map<String, dynamic>) {
        final dataMap = json['data'] as Map<String, dynamic>;
        if (dataMap['transactions'] is List) {
          items = dataMap['transactions'] as List<dynamic>;
        } else if (dataMap['items'] is List) {
          items = dataMap['items'] as List<dynamic>;
        }
      }

      final Map<String, dynamic>? paginationSource = _extractPagination(json);
      if (paginationSource != null) {
        pagination = PaginationApiModel.fromJson(paginationSource);
      }
    }

    final transactions = items
        .whereType<Map<String, dynamic>>()
        .map(StatementReceiptApiModel.fromJson)
        .toList();

    return TransactionHistoryApiModel(
      transactions: transactions,
      pagination: pagination,
    );
  }

  TransactionHistoryEntity toEntity() {
    return TransactionHistoryEntity(
      transactions: transactions.map((e) => e.toEntity()).toList(),
      pagination: pagination?.toEntity(),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Map<String, dynamic>? _extractPagination(Map<String, dynamic> json) {
  if (json['pagination'] is Map<String, dynamic>) {
    return json['pagination'] as Map<String, dynamic>;
  }
  if (json['meta'] is Map<String, dynamic>) {
    return json['meta'] as Map<String, dynamic>;
  }

  final hasPagingFields =
      json.containsKey('page') ||
      json.containsKey('limit') ||
      json.containsKey('total') ||
      json.containsKey('totalPages');
  if (hasPagingFields) return json;

  if (json['data'] is Map<String, dynamic>) {
    final data = json['data'] as Map<String, dynamic>;
    if (data['pagination'] is Map<String, dynamic>) {
      return data['pagination'] as Map<String, dynamic>;
    }
    if (data['meta'] is Map<String, dynamic>) {
      return data['meta'] as Map<String, dynamic>;
    }
    final hasFields =
        data.containsKey('page') ||
        data.containsKey('limit') ||
        data.containsKey('total') ||
        data.containsKey('totalPages');
    if (hasFields) return data;
  }
  return null;
}

DateTime _parseDate(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
