import 'package:equatable/equatable.dart';

class HotelEntity extends Equatable {
  final String id;
  final String name;
  final String city;
  final String roomType;
  final int roomsTotal;
  final int roomsAvailable;
  final double pricePerNight;
  final List<String> amenities;
  final List<String> images;

  const HotelEntity({
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

  @override
  List<Object?> get props => [
    id,
    name,
    city,
    roomType,
    roomsTotal,
    roomsAvailable,
    pricePerNight,
    amenities,
    images,
  ];
}

class HotelBookingItemEntity extends Equatable {
  static const Object _unset = Object();

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

  const HotelBookingItemEntity({
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

  HotelBookingItemEntity copyWith({
    String? id,
    String? status,
    Object? userId = _unset,
    Object? itemId = _unset,
    Object? quantity = _unset,
    Object? nights = _unset,
    Object? checkin = _unset,
    Object? price = _unset,
    Object? paymentTxnId = _unset,
    Object? paidAt = _unset,
    Object? createdAt = _unset,
    Object? name = _unset,
    Object? city = _unset,
    Object? roomType = _unset,
    Object? unitPrice = _unset,
  }) {
    return HotelBookingItemEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      userId: userId == _unset ? this.userId : userId as String?,
      itemId: itemId == _unset ? this.itemId : itemId as String?,
      quantity: quantity == _unset ? this.quantity : quantity as int?,
      nights: nights == _unset ? this.nights : nights as int?,
      checkin: checkin == _unset ? this.checkin : checkin as DateTime?,
      price: price == _unset ? this.price : price as double?,
      paymentTxnId: paymentTxnId == _unset
          ? this.paymentTxnId
          : paymentTxnId as String?,
      paidAt: paidAt == _unset ? this.paidAt : paidAt as DateTime?,
      createdAt: createdAt == _unset ? this.createdAt : createdAt as DateTime?,
      name: name == _unset ? this.name : name as String?,
      city: city == _unset ? this.city : city as String?,
      roomType: roomType == _unset ? this.roomType : roomType as String?,
      unitPrice: unitPrice == _unset ? this.unitPrice : unitPrice as double?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    userId,
    itemId,
    quantity,
    nights,
    checkin,
    price,
    paymentTxnId,
    paidAt,
    createdAt,
    name,
    city,
    roomType,
    unitPrice,
  ];
}

class CreateHotelBookingResultEntity extends Equatable {
  final String bookingId;
  final String status;
  final double price;
  final String payUrl;

  const CreateHotelBookingResultEntity({
    required this.bookingId,
    required this.status,
    required this.price,
    required this.payUrl,
  });

  @override
  List<Object?> get props => [bookingId, status, price, payUrl];
}

class PayHotelBookingResultEntity extends Equatable {
  final HotelBookingItemEntity booking;
  final String transactionId;
  final bool idempotentReplay;

  const PayHotelBookingResultEntity({
    required this.booking,
    required this.transactionId,
    required this.idempotentReplay,
  });

  @override
  List<Object?> get props => [booking, transactionId, idempotentReplay];
}
