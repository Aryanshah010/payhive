import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationEntity? notification;
  final String? title;
  final String? body;
  final String? type;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;

  const NotificationDetailPage({
    super.key,
    this.notification,
    this.title,
    this.body,
    this.type,
    this.data,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final model = notification;
    final resolvedTitle = (model?.title ?? title ?? 'Notification').trim();
    final resolvedBody = (model?.body ?? body ?? '--').trim();
    final resolvedType = (model?.type ?? type ?? '--').trim();
    final resolvedData = model?.data ?? data;
    final resolvedDate = model?.createdAt ?? createdAt;

    final dateText = resolvedDate == null
        ? '--'
        : DateFormat('dd MMM yyyy, hh:mm a').format(resolvedDate.toLocal());

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedTitle.isEmpty ? 'Notification' : resolvedTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                resolvedBody.isEmpty ? '--' : resolvedBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _infoCard(
                context,
                children: [
                  _row('Type', resolvedType.isEmpty ? '--' : resolvedType),
                  _row('Date', dateText),
                ],
              ),
              if (resolvedData != null && resolvedData.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _infoCard(
                  context,
                  children: resolvedData.entries
                      .map((entry) => _row(entry.key, _stringify(entry.value)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _stringify(dynamic value) {
    if (value == null) return '--';
    if (value is DateTime) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value.toLocal());
    }
    return value.toString();
  }
}
