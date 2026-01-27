import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';

class ProfileApiModel {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String? imageUrl;

  ProfileApiModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    this.imageUrl,
  });

  factory ProfileApiModel.fromJson(Map<String, dynamic> json) {
    return ProfileApiModel(
      id: json['_id']?.toString(),
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'imageUrl': imageUrl,
  };

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      imageUrl: imageUrl,
    );
  }

  factory ProfileApiModel.fromEntity(ProfileEntity entity) {
    return ProfileApiModel(
      id: entity.id,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      imageUrl: entity.imageUrl,
    );
  }
}
