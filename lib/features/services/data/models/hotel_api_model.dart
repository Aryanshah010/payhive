import 'package:payhive/features/services/domain/entity/hotel_entity.dart';

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

class HotelApiModel {
  final String id;
  final String name;
  final String city;
  final String roomType;
  final int roomsTotal;
  final int roomsAvailable;
  final double pricePerNight;
  final List<String> amenities;
  final List<String> images;

  const HotelApiModel({
    required this.id,
    required this.name,
    required this.city,
    required this.roomType,
    required this.roomsTotal,
    required this.roomsAvailable,
    required this.pricePerNight,
    required this.amenities,
    required this.images,
  });

  factory HotelApiModel.fromJson(Map<String, dynamic> json) {
    return HotelApiModel(
      id: _extractId(json),
      name: _asString(json['name']),
      city: _asString(json['city']),
      roomType: _asString(json['roomType']),
      roomsTotal: _asInt(json['roomsTotal']),
      roomsAvailable: _asInt(json['roomsAvailable']),
      pricePerNight: _asDouble(json['pricePerNight']),
      amenities: _asStringList(json['amenities']),
      images: _asStringList(json['images']),
    );
  }

  HotelEntity toEntity() {
    return HotelEntity(
      id: id,
      name: name,
      city: city,
      roomType: roomType,
      roomsTotal: roomsTotal,
      roomsAvailable: roomsAvailable,
      pricePerNight: pricePerNight,
      amenities: amenities,
      images: images,
    );
  }
}

class HotelBookingItemApiModel {
  final String id;
  final String status;
  final String? userId;
  final String? itemId;
  final int? quantity;
  final int? nights;
  final DateTime? checkin;
  final double? price;
  final String? paymentTxnId;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String? name;
  final String? city;
  final String? roomType;
  final double? unitPrice;

  const HotelBookingItemApiModel({
    required this.id,
    required this.status,
    this.userId,
    this.itemId,
    this.quantity,
    this.nights,
    this.checkin,
    this.price,
    this.paymentTxnId,
    this.paidAt,
    this.createdAt,
    this.name,
    this.city,
    this.roomType,
    this.unitPrice,
  });

  factory HotelBookingItemApiModel.fromJson(Map<String, dynamic> json) {
    final snapshot = _asMap(json['snapshot']);
    return HotelBookingItemApiModel(
      id: _extractId(json),
      status: _asString(json['status']),
      userId: _extractIdOrNull(json['userId']),
      itemId: _extractIdOrNull(json['itemId']),
      quantity: _asNullableInt(json['quantity']),
      nights: _asNullableInt(json['nights']),
      checkin: _asDateTime(snapshot['checkin'] ?? json['checkin']),
      price: _asNullableDouble(json['price']),
      paymentTxnId: _extractIdOrNull(json['paymentTxnId']),
      paidAt: _asDateTime(json['paidAt']),
      createdAt: _asDateTime(json['createdAt']),
      name: _asNullableString(snapshot['name']),
      city: _asNullableString(snapshot['city']),
      roomType: _asNullableString(snapshot['roomType']),
      unitPrice: _asNullableDouble(snapshot['unitPrice']),
    );
  }

  HotelBookingItemEntity toEntity() {
    return HotelBookingItemEntity(
      id: id,
      status: status,
      userId: userId,
      itemId: itemId,
      quantity: quantity,
      nights: nights,
      checkin: checkin,
      price: price,
      paymentTxnId: paymentTxnId,
      paidAt: paidAt,
      createdAt: createdAt,
      name: name,
      city: city,
      roomType: roomType,
      unitPrice: unitPrice,
    );
  }
}

class CreateHotelBookingResultApiModel {
  final String bookingId;
  final String status;
  final double price;
  final String payUrl;

  const CreateHotelBookingResultApiModel({
    required this.bookingId,
    required this.status,
    required this.price,
    required this.payUrl,
  });

  factory CreateHotelBookingResultApiModel.fromJson(Map<String, dynamic> json) {
    return CreateHotelBookingResultApiModel(
      bookingId: _asString(json['bookingId']),
      status: _asString(json['status']),
      price: _asDouble(json['price']),
      payUrl: _asString(json['payUrl']),
    );
  }

  CreateHotelBookingResultEntity toEntity() {
    return CreateHotelBookingResultEntity(
      bookingId: bookingId,
      status: status,
      price: price,
      payUrl: payUrl,
    );
  }
}

class PayHotelBookingResultApiModel {
  final HotelBookingItemApiModel booking;
  final String transactionId;
  final bool idempotentReplay;

  const PayHotelBookingResultApiModel({
    required this.booking,
    required this.transactionId,
    required this.idempotentReplay,
  });

  factory PayHotelBookingResultApiModel.fromJson(Map<String, dynamic> json) {
    return PayHotelBookingResultApiModel(
      booking: HotelBookingItemApiModel.fromJson(_asMap(json['booking'])),
      transactionId: _asString(json['transactionId']),
      idempotentReplay: _asBool(json['idempotentReplay']),
    );
  }

  PayHotelBookingResultEntity toEntity() {
    return PayHotelBookingResultEntity(
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

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map(_asString)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const <String>[];
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
