import 'package:payhive/features/services/domain/entity/flight_entity.dart';

class PagedResultApiModel<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PagedResultApiModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PagedResultApiModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems = json['items'];
    final items = (rawItems is List ? rawItems : const <dynamic>[])
        .whereType<Map>()
        .map((item) => itemParser(Map<String, dynamic>.from(item)))
        .toList();

    final page = _asInt(json['page'], fallback: 1);
    final limit = _asInt(json['limit'], fallback: 10);
    final total = _asInt(json['total'], fallback: items.length);
    final totalPages = _asInt(
      json['totalPages'],
      fallback: total == 0 ? 1 : ((total / limit).ceil()),
    );

    return PagedResultApiModel(
      items: items,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }
}

class FlightApiModel {
  final String id;
  final String airline;
  final String flightNumber;
  final String from;
  final String to;
  final DateTime departure;
  final DateTime arrival;
  final int durationMinutes;
  final String flightClass;
  final double price;
  final int seatsTotal;
  final int seatsAvailable;

  const FlightApiModel({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.durationMinutes,
    required this.flightClass,
    required this.price,
    required this.seatsTotal,
    required this.seatsAvailable,
  });

  factory FlightApiModel.fromJson(Map<String, dynamic> json) {
    return FlightApiModel(
      id: _extractId(json),
      airline: _asString(json['airline']),
      flightNumber: _asString(json['flightNumber']),
      from: _asString(json['from']),
      to: _asString(json['to']),
      departure:
          _asDateTime(json['departure']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      arrival:
          _asDateTime(json['arrival']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationMinutes: _asInt(json['durationMinutes']),
      flightClass: _asString(json['class']),
      price: _asDouble(json['price']),
      seatsTotal: _asInt(json['seatsTotal']),
      seatsAvailable: _asInt(json['seatsAvailable']),
    );
  }

  FlightEntity toEntity() {
    return FlightEntity(
      id: id,
      airline: airline,
      flightNumber: flightNumber,
      from: from,
      to: to,
      departure: departure,
      arrival: arrival,
      durationMinutes: durationMinutes,
      flightClass: flightClass,
      price: price,
      seatsTotal: seatsTotal,
      seatsAvailable: seatsAvailable,
    );
  }
}

class FlightBookingItemApiModel {
  final String id;
  final String status;
  final String? userId;
  final String? itemId;
  final int? quantity;
  final double? price;
  final String? paymentTxnId;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String? airline;
  final String? flightNumber;
  final String? from;
  final String? to;
  final DateTime? departure;
  final DateTime? arrival;
  final String? flightClass;
  final double? unitPrice;

  const FlightBookingItemApiModel({
    required this.id,
    required this.status,
    this.userId,
    this.itemId,
    this.quantity,
    this.price,
    this.paymentTxnId,
    this.paidAt,
    this.createdAt,
    this.airline,
    this.flightNumber,
    this.from,
    this.to,
    this.departure,
    this.arrival,
    this.flightClass,
    this.unitPrice,
  });

  factory FlightBookingItemApiModel.fromJson(Map<String, dynamic> json) {
    final snapshot = _asMap(json['snapshot']);
    return FlightBookingItemApiModel(
      id: _extractId(json),
      status: _asString(json['status']),
      userId: _extractIdOrNull(json['userId']),
      itemId: _extractIdOrNull(json['itemId']),
      quantity: _asNullableInt(json['quantity']),
      price: _asNullableDouble(json['price']),
      paymentTxnId: _extractIdOrNull(json['paymentTxnId']),
      paidAt: _asDateTime(json['paidAt']),
      createdAt: _asDateTime(json['createdAt']),
      airline: _asNullableString(snapshot['airline']),
      flightNumber: _asNullableString(snapshot['flightNumber']),
      from: _asNullableString(snapshot['from']),
      to: _asNullableString(snapshot['to']),
      departure: _asDateTime(snapshot['departure']),
      arrival: _asDateTime(snapshot['arrival']),
      flightClass: _asNullableString(snapshot['class']),
      unitPrice: _asNullableDouble(snapshot['unitPrice']),
    );
  }

  FlightBookingItemEntity toEntity() {
    return FlightBookingItemEntity(
      id: id,
      status: status,
      userId: userId,
      itemId: itemId,
      quantity: quantity,
      price: price,
      paymentTxnId: paymentTxnId,
      paidAt: paidAt,
      createdAt: createdAt,
      airline: airline,
      flightNumber: flightNumber,
      from: from,
      to: to,
      departure: departure,
      arrival: arrival,
      flightClass: flightClass,
      unitPrice: unitPrice,
    );
  }
}

class CreateBookingResultApiModel {
  final String bookingId;
  final String status;
  final double price;
  final String payUrl;

  const CreateBookingResultApiModel({
    required this.bookingId,
    required this.status,
    required this.price,
    required this.payUrl,
  });

  factory CreateBookingResultApiModel.fromJson(Map<String, dynamic> json) {
    return CreateBookingResultApiModel(
      bookingId: _asString(json['bookingId']),
      status: _asString(json['status']),
      price: _asDouble(json['price']),
      payUrl: _asString(json['payUrl']),
    );
  }

  CreateBookingResultEntity toEntity() {
    return CreateBookingResultEntity(
      bookingId: bookingId,
      status: status,
      price: price,
      payUrl: payUrl,
    );
  }
}

class PayBookingResultApiModel {
  final FlightBookingItemApiModel booking;
  final String transactionId;
  final bool idempotentReplay;

  const PayBookingResultApiModel({
    required this.booking,
    required this.transactionId,
    required this.idempotentReplay,
  });

  factory PayBookingResultApiModel.fromJson(Map<String, dynamic> json) {
    return PayBookingResultApiModel(
      booking: FlightBookingItemApiModel.fromJson(_asMap(json['booking'])),
      transactionId: _asString(json['transactionId']),
      idempotentReplay: _asBool(json['idempotentReplay']),
    );
  }

  PayBookingResultEntity toEntity() {
    return PayBookingResultEntity(
      booking: booking.toEntity(),
      transactionId: transactionId,
      idempotentReplay: idempotentReplay,
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

String _extractId(Map<String, dynamic> json) {
  return _asString(json['_id'] ?? json['id']);
}

String? _extractIdOrNull(dynamic value) {
  final id = _extractIdFromValue(value);
  return id.isEmpty ? null : id;
}

String _extractIdFromValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    return _asString(value['_id'] ?? value['id']);
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return _asString(map['_id'] ?? map['id']);
  }
  return value.toString();
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

String? _asNullableString(dynamic value) {
  final str = _asString(value).trim();
  if (str.isEmpty) return null;
  return str;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  return _asInt(value);
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  return _asDouble(value);
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  if (value is num) return value != 0;
  return false;
}
