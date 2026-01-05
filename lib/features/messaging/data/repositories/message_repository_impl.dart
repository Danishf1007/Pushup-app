import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';

/// Firestore implementation of [MessageRepository].
class MessageRepositoryImpl implements MessageRepository {
  /// Creates the repository with optional Firestore instance.
  MessageRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  @override
  Stream<List<ConversationEntity>> watchConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs.map((doc) {
            final data = doc.data();
            return ConversationEntity(
              id: doc.id,
              participantIds: List<String>.from(data['participantIds'] ?? []),
              participantNames: Map<String, String>.from(
                data['participantNames'] ?? {},
              ),
              lastMessage: data['lastMessage'] as String?,
              lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
              unreadCount: _getUnreadCount(data, userId),
            );
          }).toList();

          // Sort by last message time in memory
          conversations.sort((a, b) {
            if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
            if (a.lastMessageAt == null) return 1;
            if (b.lastMessageAt == null) return -1;
            return b.lastMessageAt!.compareTo(a.lastMessageAt!);
          });

          return conversations;
        });
  }

  int _getUnreadCount(Map<String, dynamic> data, String userId) {
    final unreadCounts = data['unreadCounts'] as Map<String, dynamic>?;
    if (unreadCounts == null) return 0;
    return (unreadCounts[userId] as num?)?.toInt() ?? 0;
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) {
            final data = doc.data();
            return MessageEntity(
              id: doc.id,
              senderId: data['senderId'] as String? ?? '',
              receiverId: data['receiverId'] as String? ?? '',
              content: data['content'] as String? ?? '',
              sentAt:
                  (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              readAt: (data['readAt'] as Timestamp?)?.toDate(),
              senderName: data['senderName'] as String?,
            );
          }).toList();

          // Sort by sent time in memory
          messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          return messages;
        });
  }

  @override
  Future<MessageEntity> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? senderName,
  }) async {
    // Get or create conversation
    final conversation = await _getConversationByParticipants(
      senderId,
      receiverId,
    );

    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'senderName': senderName,
    };

    final docRef = await _conversations
        .doc(conversation.id)
        .collection('messages')
        .add(messageData);

    // Update conversation with last message
    await _conversations.doc(conversation.id).update({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    return MessageEntity(
      id: docRef.id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      sentAt: DateTime.now(),
      senderName: senderName,
    );
  }

  Future<ConversationEntity?> _getConversationByParticipants(
    String userId1,
    String userId2,
  ) async {
    final snapshot = await _conversations
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in snapshot.docs) {
      final participantIds = List<String>.from(
        doc.data()['participantIds'] ?? [],
      );
      if (participantIds.contains(userId2)) {
        return ConversationEntity(
          id: doc.id,
          participantIds: participantIds,
          participantNames: Map<String, String>.from(
            doc.data()['participantNames'] ?? {},
          ),
          lastMessage: doc.data()['lastMessage'] as String?,
          lastMessageAt: (doc.data()['lastMessageAt'] as Timestamp?)?.toDate(),
        );
      }
    }
    return null;
  }

  @override
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    // Reset unread count for user
    await _conversations.doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });

    // Mark individual messages as read
    final unreadMessages = await _conversations
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('readAt', isNull: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String userId1,
    required String userId2,
    required String userName1,
    required String userName2,
  }) async {
    // Check if conversation already exists
    final existing = await _getConversationByParticipants(userId1, userId2);
    if (existing != null) return existing;

    // Create new conversation
    final participantIds = [userId1, userId2]..sort();
    final conversationData = {
      'participantIds': participantIds,
      'participantNames': {userId1: userName1, userId2: userName2},
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageAt': null,
      'unreadCounts': {userId1: 0, userId2: 0},
    };

    final docRef = await _conversations.add(conversationData);

    return ConversationEntity(
      id: docRef.id,
      participantIds: participantIds,
      participantNames: {userId1: userName1, userId2: userName2},
    );
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (final doc in snapshot.docs) {
            totalUnread += _getUnreadCount(doc.data(), userId);
          }
          return totalUnread;
        });
  }
}
