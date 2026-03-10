import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';

enum HotelListViewStatus { initial, loading, loaded, error }

class HotelListState extends Equatable {
  static const Object _unset = Object();

  final HotelListViewStatus status;
  final List<HotelEntity> hotels;
  final String city;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  const HotelListState({
    required this.status,
    required this.hotels,
    required this.city,
    this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
  });

  factory HotelListState.initial() {
    return const HotelListState(
      status: HotelListViewStatus.initial,
      hotels: [],
      city: '',
      errorMessage: null,
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
    );
  }

  bool get hasMore => page < totalPages;

  HotelListState copyWith({
    HotelListViewStatus? status,
    List<HotelEntity>? hotels,
    String? city,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return HotelListState(
      status: status ?? this.status,
      hotels: hotels ?? this.hotels,
      city: city ?? this.city,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hotels,
    city,
    errorMessage,
    page,
    totalPages,
    isLoadingMore,
  ];
}
