import 'package:hive/hive.dart';
import 'package:payhive/core/constants/hive_table_constants.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:uuid/uuid.dart';

part 'auth_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.authTypeId)
class AuthHiveModel extends HiveObject {
  @HiveField(0)
  final String? authId;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String? password;

  @HiveField(4)
  final String? email;

  AuthHiveModel({
    String? authId,
    required this.fullName,
    required this.phoneNumber,
    this.password,
    this.email,
  }) : authId = authId ?? Uuid().v4();

  AuthEntity toEntity() {
    return AuthEntity(
      authId: authId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    );
  }

  factory AuthHiveModel.fromEntity(AuthEntity entity) {
    return AuthHiveModel(
      authId: entity.authId,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      password: entity.password,
    );
  }

  static List<AuthEntity> toEntityList(List<AuthHiveModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
