import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/services/storage/device_storage_service.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';
import 'package:payhive/features/devices/presentation/state/device_state.dart';
import 'package:payhive/features/devices/presentation/view_model/device_view_model.dart';

class ManageDevicesPage extends ConsumerStatefulWidget {
  const ManageDevicesPage({super.key});

  @override
  ConsumerState<ManageDevicesPage> createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends ConsumerState<ManageDevicesPage> {
  final Set<String> _expanded = {};
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _currentDeviceId = ref.read(deviceStorageServiceProvider).getDeviceId();
    Future.microtask(
      () => ref.read(deviceViewModelProvider.notifier).loadDevices(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceViewModelProvider);
    final viewModel = ref.read(deviceViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<DeviceState>(deviceViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        SnackbarUtil.showError(context, next.errorMessage!);
        viewModel.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Devices'),
        actions: [
          IconButton(
            onPressed: () => viewModel.loadDevices(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadDevices(),
        child: _buildBody(context, state, colorScheme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DeviceState state,
    ColorScheme colorScheme,
  ) {
    if (state.status == DeviceViewStatus.loading && state.devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.devices.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.devices_rounded, size: 56),
          SizedBox(height: 16),
          Center(child: Text('No devices found.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = state.devices[index];
        final isExpanded = _expanded.contains(device.deviceId);
        final isCurrent = _currentDeviceId == device.deviceId;
        final isActionLoading =
            state.status == DeviceViewStatus.actionLoading &&
            state.actionDeviceId == device.deviceId;

        final dismissDirection = _dismissDirectionFor(device.status);

        return Dismissible(
          key: ValueKey('device-${device.deviceId}'),
          direction: dismissDirection,
          background: _buildSwipeBackground(
            context,
            label: 'Allow',
            color: Colors.green.shade600,
            icon: Icons.check_circle_rounded,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
          ),
          secondaryBackground: _buildSwipeBackground(
            context,
            label: 'Block',
            color: Colors.red.shade600,
            icon: Icons.block_rounded,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              if (device.status == DeviceStatus.blocked ||
                  device.status == DeviceStatus.pending) {
                ref.read(deviceViewModelProvider.notifier).allowDevice(
                  device.deviceId,
                );
              }
            } else if (direction == DismissDirection.endToStart) {
              if (device.status == DeviceStatus.allowed ||
                  device.status == DeviceStatus.pending) {
                ref.read(deviceViewModelProvider.notifier).blockDevice(
                  device.deviceId,
                );
              }
            }
            return false;
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expanded.remove(device.deviceId);
                } else {
                  _expanded.add(device.deviceId);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (device.deviceName == null ||
                                      device.deviceName!.trim().isEmpty)
                                  ? 'Unknown device'
                                  : device.deviceName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _statusChip(device.status),
                                if (isCurrent)
                                  Chip(
                                    label: const Text('This device'),
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.12),
                                    labelStyle: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isActionLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    _detailRow('Device ID', device.deviceId),
                    if (device.userAgent != null &&
                        device.userAgent!.trim().isNotEmpty)
                      _detailRow('User Agent', device.userAgent!),
                    _detailRow('Status', _statusLabel(device.status)),
                    if (device.lastSeenAt != null)
                      _detailRow(
                        'Last Seen',
                        _formatDate(device.lastSeenAt!),
                      ),
                    if (device.allowedAt != null)
                      _detailRow(
                        'Allowed At',
                        _formatDate(device.allowedAt!),
                      ),
                    if (device.blockedAt != null)
                      _detailRow(
                        'Blocked At',
                        _formatDate(device.blockedAt!),
                      ),
                    if (device.createdAt != null)
                      _detailRow(
                        'Created At',
                        _formatDate(device.createdAt!),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DismissDirection _dismissDirectionFor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.pending:
        return DismissDirection.horizontal;
      case DeviceStatus.allowed:
        return DismissDirection.endToStart;
      case DeviceStatus.blocked:
        return DismissDirection.startToEnd;
    }
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required EdgeInsets padding,
  }) {
    return Container(
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());
  }

  String _statusLabel(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.allowed:
        return 'Allowed';
      case DeviceStatus.blocked:
        return 'Blocked';
      case DeviceStatus.pending:
        return 'Pending';
    }
  }

  Widget _statusChip(DeviceStatus status) {
    final color = _statusColor(status);
    return Chip(
      label: Text(
        _statusLabel(status),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color),
    );
  }

  Color _statusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.allowed:
        return Colors.green.shade700;
      case DeviceStatus.blocked:
        return Colors.red.shade700;
      case DeviceStatus.pending:
        return Colors.orange.shade700;
    }
  }
}
