import 'package:equatable/equatable.dart';

class FlightEntity extends Equatable {
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

  const FlightEntity({
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

  @override
  List<Object?> get props => [
    id,
    airline,
    flightNumber,
    from,
    to,
    departure,
    arrival,
    durationMinutes,
    flightClass,
    price,
    seatsTotal,
    seatsAvailable,
  ];
}

class FlightBookingItemEntity extends Equatable {
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

  const FlightBookingItemEntity({
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

  FlightBookingItemEntity copyWith({
    String? id,
    String? status,
    Object? userId = _unset,
    Object? itemId = _unset,
    Object? quantity = _unset,
    Object? price = _unset,
    Object? paymentTxnId = _unset,
    Object? paidAt = _unset,
    Object? createdAt = _unset,
    Object? airline = _unset,
    Object? flightNumber = _unset,
    Object? from = _unset,
    Object? to = _unset,
    Object? departure = _unset,
    Object? arrival = _unset,
    Object? flightClass = _unset,
    Object? unitPrice = _unset,
  }) {
    return FlightBookingItemEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      userId: userId == _unset ? this.userId : userId as String?,
      itemId: itemId == _unset ? this.itemId : itemId as String?,
      quantity: quantity == _unset ? this.quantity : quantity as int?,
      price: price == _unset ? this.price : price as double?,
      paymentTxnId: paymentTxnId == _unset
          ? this.paymentTxnId
          : paymentTxnId as String?,
      paidAt: paidAt == _unset ? this.paidAt : paidAt as DateTime?,
      createdAt: createdAt == _unset ? this.createdAt : createdAt as DateTime?,
      airline: airline == _unset ? this.airline : airline as String?,
      flightNumber: flightNumber == _unset
          ? this.flightNumber
          : flightNumber as String?,
      from: from == _unset ? this.from : from as String?,
      to: to == _unset ? this.to : to as String?,
      departure: departure == _unset ? this.departure : departure as DateTime?,
      arrival: arrival == _unset ? this.arrival : arrival as DateTime?,
      flightClass: flightClass == _unset
          ? this.flightClass
          : flightClass as String?,
      unitPrice: unitPrice == _unset ? this.unitPrice : unitPrice as double?,
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => [
    id,
    status,
    userId,
    itemId,
    quantity,
    price,
    paymentTxnId,
    paidAt,
    createdAt,
    airline,
    flightNumber,
    from,
    to,
    departure,
    arrival,
    flightClass,
    unitPrice,
  ];
}

class CreateBookingResultEntity extends Equatable {
  final String bookingId;
  final String status;
  final double price;
  final String payUrl;

  const CreateBookingResultEntity({
    required this.bookingId,
    required this.status,
    required this.price,
    required this.payUrl,
  });

  @override
  List<Object?> get props => [bookingId, status, price, payUrl];
}

class PayBookingResultEntity extends Equatable {
  final FlightBookingItemEntity booking;
  final String transactionId;
  final bool idempotentReplay;

  const PayBookingResultEntity({
    required this.booking,
    required this.transactionId,
    required this.idempotentReplay,
  });

  @override
  List<Object?> get props => [booking, transactionId, idempotentReplay];
}
