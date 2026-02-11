import 'package:equatable/equatable.dart';

enum DeviceStatus { allowed, pending, blocked }

DeviceStatus deviceStatusFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'ALLOWED':
      return DeviceStatus.allowed;
    case 'BLOCKED':
      return DeviceStatus.blocked;
    case 'PENDING':
    default:
      return DeviceStatus.pending;
  }
}

String deviceStatusToApi(DeviceStatus status) {
  switch (status) {
    case DeviceStatus.allowed:
      return 'ALLOWED';
    case DeviceStatus.blocked:
      return 'BLOCKED';
    case DeviceStatus.pending:
      return 'PENDING';
  }
}

class DeviceEntity extends Equatable {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String? userAgent;
  final DeviceStatus status;
  final DateTime? lastSeenAt;
  final DateTime? allowedAt;
  final DateTime? blockedAt;
  final DateTime? createdAt;

  const DeviceEntity({
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

  DeviceEntity copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    String? userAgent,
    DeviceStatus? status,
    DateTime? lastSeenAt,
    DateTime? allowedAt,
    DateTime? blockedAt,
    DateTime? createdAt,
  }) {
    return DeviceEntity(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      userAgent: userAgent ?? this.userAgent,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      allowedAt: allowedAt ?? this.allowedAt,
      blockedAt: blockedAt ?? this.blockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    deviceId,
    deviceName,
    userAgent,
    status,
    lastSeenAt,
    allowedAt,
    blockedAt,
    createdAt,
  ];
}
