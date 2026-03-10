import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/services/data/repositories/flight_repositories.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/repositories/flight_repositories.dart';

class GetFlightsParams extends Equatable {
  final int page;
  final int limit;
  final String from;
  final String to;
  final String? date;

  const GetFlightsParams({
    required this.page,
    required this.limit,
    this.from = '',
    this.to = '',
    this.date,
  });

  @override
  List<Object?> get props => [page, limit, from, to, date];
}

class CreateFlightBookingParams extends Equatable {
  final String flightId;
  final int quantity;

  const CreateFlightBookingParams({
    required this.flightId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [flightId, quantity];
}

class PayBookingParams extends Equatable {
  final String bookingId;
  final String? idempotencyKey;

  const PayBookingParams({required this.bookingId, this.idempotencyKey});

  @override
  List<Object?> get props => [bookingId, idempotencyKey];
}

class GetFlightBookingsParams extends Equatable {
  final int page;
  final int limit;
  final String? status;

  const GetFlightBookingsParams({
    required this.page,
    required this.limit,
    this.status,
  });

  @override
  List<Object?> get props => [page, limit, status];
}

final getFlightsUsecaseProvider = Provider<GetFlightsUsecase>((ref) {
  return GetFlightsUsecase(repository: ref.read(flightRepositoryProvider));
});

final createFlightBookingUsecaseProvider = Provider<CreateFlightBookingUsecase>(
  (ref) {
    return CreateFlightBookingUsecase(
      repository: ref.read(flightRepositoryProvider),
    );
  },
);

final payBookingUsecaseProvider = Provider<PayBookingUsecase>((ref) {
  return PayBookingUsecase(repository: ref.read(flightRepositoryProvider));
});

final getFlightBookingsUsecaseProvider = Provider<GetFlightBookingsUsecase>((
  ref,
) {
  return GetFlightBookingsUsecase(
    repository: ref.read(flightRepositoryProvider),
  );
});

class GetFlightsUsecase
    implements
        UsecaseWithParams<PagedResultEntity<FlightEntity>, GetFlightsParams> {
  final IFlightRepository _repository;

  GetFlightsUsecase({required IFlightRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PagedResultEntity<FlightEntity>>> call(
    GetFlightsParams params,
  ) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid page/limit values')),
      );
    }

    final date = params.date?.trim();
    if (date != null && date.isNotEmpty && !_isValidDateOnly(date)) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Date must be in YYYY-MM-DD format'),
        ),
      );
    }

    return _repository.getFlights(
      page: params.page,
      limit: params.limit,
      from: params.from.trim(),
      to: params.to.trim(),
      date: date == null || date.isEmpty ? null : date,
    );
  }
}

class CreateFlightBookingUsecase
    implements
        UsecaseWithParams<
          CreateBookingResultEntity,
          CreateFlightBookingParams
        > {
  final IFlightRepository _repository;

  CreateFlightBookingUsecase({required IFlightRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, CreateBookingResultEntity>> call(
    CreateFlightBookingParams params,
  ) {
    final flightId = params.flightId.trim();
    if (flightId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Flight id is required')),
      );
    }

    if (params.quantity <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Quantity must be positive')),
      );
    }

    return _repository.createFlightBooking(
      flightId: flightId,
      quantity: params.quantity,
    );
  }
}

class PayBookingUsecase
    implements UsecaseWithParams<PayBookingResultEntity, PayBookingParams> {
  final IFlightRepository _repository;

  PayBookingUsecase({required IFlightRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PayBookingResultEntity>> call(
    PayBookingParams params,
  ) {
    final bookingId = params.bookingId.trim();
    if (bookingId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Booking id is required')),
      );
    }

    final idempotencyKey = params.idempotencyKey?.trim();

    return _repository.payBooking(
      bookingId: bookingId,
      idempotencyKey: idempotencyKey == null || idempotencyKey.isEmpty
          ? null
          : idempotencyKey,
    );
  }
}

class GetFlightBookingsUsecase
    implements
        UsecaseWithParams<
          PagedResultEntity<FlightBookingItemEntity>,
          GetFlightBookingsParams
        > {
  final IFlightRepository _repository;

  GetFlightBookingsUsecase({required IFlightRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PagedResultEntity<FlightBookingItemEntity>>> call(
    GetFlightBookingsParams params,
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

    return _repository.getFlightBookings(
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
