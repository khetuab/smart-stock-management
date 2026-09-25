// lib/presentation/controllers/notification_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/shared_preferences_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? orderId;
  final String timestamp;
  final bool isRead;

  NotificationModel({
    this.id = '',
    required this.title,
    required this.body,
    this.type = 'general',
    this.orderId,
    this.timestamp = '',
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      orderId: map['orderId']?.toString(),
      timestamp: map['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: map['isRead'] == true,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? orderId,
    String? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  bool get hasUnread => unreadCount.value > 0;

  static const String _storageKey = 'notifications';

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  void _loadNotifications() {
    final data = _prefs.getMap(_storageKey);
    if (data != null && data['notifications'] is List) {
      final list = (data['notifications'] as List)
          .map((item) => NotificationModel.fromMap(item))
          .toList();
      notifications.value = list; // ✅ Properly assign to .value
      _updateUnreadCount();
    }
  }

  void _saveNotifications() {
    _prefs.setMap(_storageKey, {
      'notifications': notifications.map((n) => n.toMap()).toList(),
    });
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void addNotification({
    required String title,
    required String body,
    String type = 'general',
    String? orderId,
  }) {
    final notification = NotificationModel(
      id: Helpers.generateId(),
      title: title,
      body: body,
      type: type,
      orderId: orderId,
      timestamp: DateTime.now().toIso8601String(),
      isRead: false,
    );

    notifications.insert(0, notification);
    _saveNotifications();
    _updateUnreadCount();

    // Show in-app snackbar
    Get.snackbar(
      title,
      body,
      colorText: Colors.white,
      backgroundColor: type == 'order' ? Colors.blue : Colors.green,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final updated = notifications[index].copyWith(isRead: true);
      notifications[index] = updated;
      _saveNotifications();
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    // ✅ Properly assign to .value using map
    notifications.value = notifications.map((n) => n.copyWith(isRead: true)).toList();
    _saveNotifications();
    _updateUnreadCount();
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    _updateUnreadCount();
  }

  void clearAll() {
    notifications.clear();
    _saveNotifications();
    _updateUnreadCount();
  }
}