import 'package:hive/hive.dart';
import 'package:payhive/core/constants/hive_table_constants.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';

part 'profile_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.profileTypeId)
class ProfileHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final double balance;

  @HiveField(6)
  final DateTime updatedAt;

  ProfileHiveModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.imageUrl,
    required this.balance,
    required this.updatedAt,
  });

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      imageUrl: imageUrl,
      balance: balance,
    );
  }

  factory ProfileHiveModel.fromEntity(ProfileEntity entity) {
    return ProfileHiveModel(
      userId: entity.id ?? '',
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      imageUrl: entity.imageUrl,
      balance: entity.balance,
      updatedAt: DateTime.now(),
    );
  }
}
