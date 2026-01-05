import '../entities/message_entity.dart';

/// Repository interface for messaging operations.
abstract class MessageRepository {
  /// Gets all conversations for a user.
  Stream<List<ConversationEntity>> watchConversations(String userId);

  /// Gets messages for a specific conversation.
  Stream<List<MessageEntity>> watchMessages(String conversationId);

  /// Sends a message to another user.
  Future<MessageEntity> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? senderName,
  });

  /// Marks messages as read.
  Future<void> markMessagesAsRead(String conversationId, String userId);

  /// Gets or creates a conversation between two users.
  Future<ConversationEntity> getOrCreateConversation({
    required String userId1,
    required String userId2,
    required String userName1,
    required String userName2,
  });

  /// Gets unread message count for a user.
  Stream<int> watchUnreadCount(String userId);
}
