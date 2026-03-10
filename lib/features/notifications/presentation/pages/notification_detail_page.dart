import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
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
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.1 : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveLayout.constrainedContent(
            context,
            child: Padding(
              padding: ResponsiveLayout.pagePadding(
                context,
                top: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedTitle.isEmpty ? 'Notification' : resolvedTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24 * scale,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    resolvedBody.isEmpty ? '--' : resolvedBody,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontSize: 16 * scale),
                  ),
                  SizedBox(height: 16 * scale),
                  _infoCard(
                    context,
                    children: [
                      _row(
                        context,
                        'Type',
                        resolvedType.isEmpty ? '--' : resolvedType,
                      ),
                      _row(context, 'Date', dateText),
                    ],
                  ),
                  if (resolvedData != null && resolvedData.isNotEmpty) ...[
                    SizedBox(height: 16 * scale),
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18 * scale,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    _infoCard(
                      context,
                      children: resolvedData.entries
                          .map(
                            (entry) => _row(
                              context,
                              entry.key,
                              _stringify(entry.value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required List<Widget> children}) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.1 : 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 146 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5 * scale,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 10 : 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13.5 * scale)),
          ),
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
