import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

/// Firestore implementation of [NotificationRepository].
class NotificationRepositoryImpl implements NotificationRepository {
  /// Creates the repository with optional Firestore instance.
  NotificationRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _notifications
        .where('receiverId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationEntity.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid composite index requirement
          notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          return notifications;
        });
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('receiverId', isEqualTo: userId)
        .where('readAt', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> sendNotification({
    required String senderId,
    required String receiverId,
    required NotificationType type,
    required String title,
    required String message,
    String? senderName,
    Map<String, dynamic>? data,
  }) async {
    await _notifications.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'title': title,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'senderName': senderName,
      'data': data,
    });
  }

  @override
  Future<void> sendBulkNotification({
    required String senderId,
    required List<String> receiverIds,
    required NotificationType type,
    required String title,
    required String message,
    String? senderName,
    Map<String, dynamic>? data,
  }) async {
    final batch = _firestore.batch();

    for (final receiverId in receiverIds) {
      final docRef = _notifications.doc();
      batch.set(docRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'type': type.name,
        'title': title,
        'message': message,
        'sentAt': FieldValue.serverTimestamp(),
        'readAt': null,
        'senderName': senderName,
        'data': data,
      });
    }

    await batch.commit();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final unreadQuery = await _notifications
        .where('receiverId', isEqualTo: userId)
        .where('readAt', isNull: true)
        .get();

    if (unreadQuery.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadQuery.docs) {
      batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    final query = await _notifications
        .where('receiverId', isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<NotificationEntity>> getRecentNotifications(
    String userId, {
    int limit = 20,
  }) async {
    final snapshot = await _notifications
        .where('receiverId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => NotificationEntity.fromFirestore(doc))
        .toList();
  }
}
