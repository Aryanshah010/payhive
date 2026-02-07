import 'package:payhive/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? password;

  AuthApiModel({
    this.id,
    required this.fullName,
    this.password,
    required this.phoneNumber,
    this.email,
  });

  //toJSON
  Map<String, dynamic> toJson() {
    return {
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "password": password,
    };
  }

  //fromJSON
  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
    );
  }

  //toEntity
  AuthEntity toEntity() {
    return AuthEntity(
      authId: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );
  }

  //fromEntity
  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      password: entity.password,
      email: entity.email,
    );
  }

  //toEnitityList
  static List<AuthEntity> toEntityList(List<AuthApiModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
