import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/services/data/repositories/hotel_repositories.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/repositories/hotel_repositories.dart';

class GetHotelsParams extends Equatable {
  final int page;
  final int limit;
  final String city;

  const GetHotelsParams({
    required this.page,
    required this.limit,
    this.city = '',
  });

  @override
  List<Object?> get props => [page, limit, city];
}

class CreateHotelBookingParams extends Equatable {
  final String hotelId;
  final int rooms;
  final int nights;
  final String checkin;

  const CreateHotelBookingParams({
    required this.hotelId,
    required this.rooms,
    required this.nights,
    required this.checkin,
  });

  @override
  List<Object?> get props => [hotelId, rooms, nights, checkin];
}

class PayHotelBookingParams extends Equatable {
  final String bookingId;
  final String? idempotencyKey;

  const PayHotelBookingParams({required this.bookingId, this.idempotencyKey});

  @override
  List<Object?> get props => [bookingId, idempotencyKey];
}

class GetHotelBookingsParams extends Equatable {
  final int page;
  final int limit;
  final String? status;

  const GetHotelBookingsParams({
    required this.page,
    required this.limit,
    this.status,
  });

  @override
  List<Object?> get props => [page, limit, status];
}

final getHotelsUsecaseProvider = Provider<GetHotelsUsecase>((ref) {
  return GetHotelsUsecase(repository: ref.read(hotelRepositoryProvider));
});

final createHotelBookingUsecaseProvider = Provider<CreateHotelBookingUsecase>((
  ref,
) {
  return CreateHotelBookingUsecase(
    repository: ref.read(hotelRepositoryProvider),
  );
});

final payHotelBookingUsecaseProvider = Provider<PayHotelBookingUsecase>((ref) {
  return PayHotelBookingUsecase(repository: ref.read(hotelRepositoryProvider));
});

final getHotelBookingsUsecaseProvider = Provider<GetHotelBookingsUsecase>((
  ref,
) {
  return GetHotelBookingsUsecase(repository: ref.read(hotelRepositoryProvider));
});

class GetHotelsUsecase
    implements
        UsecaseWithParams<PagedResultEntity<HotelEntity>, GetHotelsParams> {
  final IHotelRepository _repository;

  GetHotelsUsecase({required IHotelRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PagedResultEntity<HotelEntity>>> call(
    GetHotelsParams params,
  ) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid page/limit values')),
      );
    }

    return _repository.getHotels(
      page: params.page,
      limit: params.limit,
      city: params.city.trim(),
    );
  }
}

class CreateHotelBookingUsecase
    implements
        UsecaseWithParams<
          CreateHotelBookingResultEntity,
          CreateHotelBookingParams
        > {
  final IHotelRepository _repository;

  CreateHotelBookingUsecase({required IHotelRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, CreateHotelBookingResultEntity>> call(
    CreateHotelBookingParams params,
  ) {
    final hotelId = params.hotelId.trim();
    if (hotelId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Hotel id is required')),
      );
    }

    if (params.rooms <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Rooms must be positive')),
      );
    }

    if (params.nights <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Nights must be positive')),
      );
    }

    final checkin = params.checkin.trim();
    if (checkin.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Checkin date is required')),
      );
    }

    if (!_isValidDateOnly(checkin)) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Checkin must be in YYYY-MM-DD format'),
        ),
      );
    }

    return _repository.createHotelBooking(
      hotelId: hotelId,
      rooms: params.rooms,
      nights: params.nights,
      checkin: checkin,
    );
  }
}

class PayHotelBookingUsecase
    implements
        UsecaseWithParams<PayHotelBookingResultEntity, PayHotelBookingParams> {
  final IHotelRepository _repository;

  PayHotelBookingUsecase({required IHotelRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PayHotelBookingResultEntity>> call(
    PayHotelBookingParams params,
  ) {
    final bookingId = params.bookingId.trim();
    if (bookingId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Booking id is required')),
      );
    }

    final idempotencyKey = params.idempotencyKey?.trim();

    return _repository.payHotelBooking(
      bookingId: bookingId,
      idempotencyKey: idempotencyKey == null || idempotencyKey.isEmpty
          ? null
          : idempotencyKey,
    );
  }
}

class GetHotelBookingsUsecase
    implements
        UsecaseWithParams<
          PagedResultEntity<HotelBookingItemEntity>,
          GetHotelBookingsParams
        > {
  final IHotelRepository _repository;

  GetHotelBookingsUsecase({required IHotelRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PagedResultEntity<HotelBookingItemEntity>>> call(
    GetHotelBookingsParams params,
  ) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid page/limit values')),
      );
    }

    final status = params.status?.trim().toLowerCase();
    if (status != null && status.isNotEmpty) {
      const allowed = {'created', 'paid', 'cancelled', 'refunded'};
      if (!allowed.contains(status)) {
        return Future.value(
          const Left(ValidationFailure(message: 'Invalid booking status')),
        );
      }
    }

    return _repository.getHotelBookings(
      page: params.page,
      limit: params.limit,
      status: status == null || status.isEmpty ? null : status,
    );
  }
}

bool _isValidDateOnly(String value) {
  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!regex.hasMatch(value)) {
    return false;
  }

  final parsed = DateTime.tryParse('${value}T00:00:00');
  return parsed != null;
}
