import 'package:payhive/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String? password;

  AuthApiModel({
    this.id,
    required this.fullName,
    this.password,
    required this.phoneNumber,
  });

  //toJSON
  Map<String, dynamic> toJson() {
    return {"fullName": fullName, "phoneNumber": phoneNumber, "password": password};
  }

  //fromJSON
  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  //toEntity
  AuthEntity toEntity() {
    return AuthEntity(authId: id, fullName: fullName, phoneNumber: phoneNumber);
  }

  //fromEntity
  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      password: entity.password,
    );
  }

  //toEnitityList
  static List<AuthEntity> toEntityList(List<AuthApiModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
