import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';

class MoneyRequestRecipientApiModel {
  final String id;
  final String fullName;
  final String phoneNumber;

  MoneyRequestRecipientApiModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  factory MoneyRequestRecipientApiModel.fromJson(Map<String, dynamic> json) {
    return MoneyRequestRecipientApiModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
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

class MoneyRequestApiModel {
  final String id;
  final MoneyRequestRecipientApiModel requester;
  final MoneyRequestRecipientApiModel receiver;
  final double amount;
  final String remark;
  final String status;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoneyRequestApiModel({
    required this.id,
    required this.requester,
    required this.receiver,
    required this.amount,
    required this.remark,
    required this.status,
    required this.expiresAt,
    this.respondedAt,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoneyRequestApiModel.fromJson(Map<String, dynamic> json) {
    final requesterMap = _asMap(json['requester']);
    final receiverMap = _asMap(json['receiver']);

    return MoneyRequestApiModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      requester: MoneyRequestRecipientApiModel.fromJson(requesterMap),
      receiver: MoneyRequestRecipientApiModel.fromJson(receiverMap),
      amount: _toDouble(json['amount']),
      remark: (json['remark'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      expiresAt: _toDate(json['expiresAt']),
      respondedAt: _toNullableDate(json['respondedAt']),
      transactionId: _toNullableString(json['transactionId']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  MoneyRequestEntity toEntity() {
    return MoneyRequestEntity(
      id: id,
      requester: requester.toEntity(),
      receiver: receiver.toEntity(),
      amount: amount,
      remark: remark,
      status: status,
      expiresAt: expiresAt,
      respondedAt: respondedAt,
      transactionId: transactionId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class MoneyRequestPageApiModel {
  final List<MoneyRequestApiModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  MoneyRequestPageApiModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory MoneyRequestPageApiModel.fromJson(dynamic json) {
    if (json is List) {
      final rawItems = json.whereType<Map>();
      final parsedItems = rawItems
          .map((item) => MoneyRequestApiModel.fromJson(_asMap(item)))
          .toList();
      return MoneyRequestPageApiModel(
        items: parsedItems,
        total: parsedItems.length,
        page: 1,
        limit: parsedItems.length,
        totalPages: 1,
      );
    }

    if (json is! Map<String, dynamic>) {
      return MoneyRequestPageApiModel(
        items: const [],
        total: 0,
        page: 1,
        limit: 10,
        totalPages: 1,
      );
    }

    final items = _asList(json['items'])
        .whereType<Map>()
        .map((item) => MoneyRequestApiModel.fromJson(_asMap(item)))
        .toList();

    final page = _toInt(json['page']) ?? 1;
    final limit = _toInt(json['limit']) ?? 10;
    final total = _toInt(json['total']) ?? items.length;
    final totalPages = _toInt(json['totalPages']) ?? 1;

    return MoneyRequestPageApiModel(
      items: items,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }

  MoneyRequestPageEntity toEntity() {
    return MoneyRequestPageEntity(
      items: items.map((e) => e.toEntity()).toList(),
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const [];
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _toDate(dynamic value) {
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

DateTime? _toNullableDate(dynamic value) {
  if (value == null) return null;

  if (value is String && value.trim().isEmpty) {
    return null;
  }

  return _toDate(value);
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final result = value.toString().trim();
  if (result.isEmpty || result == 'null') {
    return null;
  }
  return result;
}
