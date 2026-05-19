import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _subtitleFor(AppNotification notification) {
    if (notification.orderId != null) {
      return 'Zamówienie #${notification.orderId}';
    }
    return 'Ogólne powiadomienie';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Powiadomienia',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _notificationService.unreadCount == 0
                ? null
                : () => _notificationService.markAllAsRead(),
            child: const Text('Oznacz wszystkie'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _notificationService,
        builder: (context, _) {
          final notifications = _notificationService.notifications;
          if (notifications.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 120),
                Icon(
                  Icons.notifications_none,
                  size: 56,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 10),
                Text(
                  'Historia powiadomień jest pusta',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final unread = !notification.isRead;

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _notificationService.openNotification(notification.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unread
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: unread
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notification.type == AppNotificationType.deliveryAssignment
                                ? Icons.local_shipping_outlined
                                : Icons.shopping_bag_outlined,
                            color: unread
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: unread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (unread)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _subtitleFor(notification),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(notification.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}