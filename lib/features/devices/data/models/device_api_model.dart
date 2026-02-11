import 'package:payhive/features/devices/domain/entity/device_entity.dart';

class DeviceApiModel {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String? userAgent;
  final String status;
  final DateTime? lastSeenAt;
  final DateTime? allowedAt;
  final DateTime? blockedAt;
  final DateTime? createdAt;

  DeviceApiModel({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.userAgent,
    required this.status,
    this.lastSeenAt,
    this.allowedAt,
    this.blockedAt,
    this.createdAt,
  });

  factory DeviceApiModel.fromJson(Map<String, dynamic> json) {
    return DeviceApiModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: json['deviceName']?.toString(),
      userAgent: json['userAgent']?.toString(),
      status: (json['status'] ?? '').toString(),
      lastSeenAt: _parseDate(json['lastSeenAt']),
      allowedAt: _parseDate(json['allowedAt']),
      blockedAt: _parseDate(json['blockedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  DeviceEntity toEntity() {
    return DeviceEntity(
      id: id,
      deviceId: deviceId,
      deviceName: deviceName,
      userAgent: userAgent,
      status: deviceStatusFromString(status),
      lastSeenAt: lastSeenAt,
      allowedAt: allowedAt,
      blockedAt: blockedAt,
      createdAt: createdAt,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
