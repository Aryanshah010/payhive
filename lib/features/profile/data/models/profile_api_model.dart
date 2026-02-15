import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';

class ProfileApiModel {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String? imageUrl;
  final bool hasPin;
  final double balance;

  ProfileApiModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.imageUrl,
    this.hasPin = false,
    this.balance = 0,
  });

  factory ProfileApiModel.fromJson(Map<String, dynamic> json) {
    return ProfileApiModel(
      id: json['_id']?.toString(),
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'],
      hasPin: json['hasPin'] == true,
      balance: _parseBalance(json['balance']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'email': email,
    'imageUrl': imageUrl,
    'hasPin': hasPin,
    'balance': balance,
  };

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      imageUrl: imageUrl,
      hasPin: hasPin,
      balance: balance,
    );
  }

  factory ProfileApiModel.fromEntity(ProfileEntity entity) {
    return ProfileApiModel(
      id: entity.id,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      imageUrl: entity.imageUrl,
      hasPin: entity.hasPin,
      balance: entity.balance,
    );
  }

  static double _parseBalance(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
