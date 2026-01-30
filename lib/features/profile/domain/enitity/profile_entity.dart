import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String? imageUrl;

  const ProfileEntity({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, fullName, phoneNumber, imageUrl];
}
