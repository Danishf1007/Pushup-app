import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';

/// Provider for the message repository.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl();
});

/// Stream provider for conversations.
final conversationsProvider =
    StreamProvider.family<List<ConversationEntity>, String>((ref, userId) {
      final repository = ref.watch(messageRepositoryProvider);
      return repository.watchConversations(userId);
    });

/// Stream provider for messages in a conversation.
final messagesProvider = StreamProvider.family<List<MessageEntity>, String>((
  ref,
  conversationId,
) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessages(conversationId);
});

/// Stream provider for unread message count.
final unreadMessageCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchUnreadCount(userId);
});

/// State for message operations.
sealed class MessageOperationState {
  const MessageOperationState();
}

class MessageOperationInitial extends MessageOperationState {
  const MessageOperationInitial();
}

class MessageOperationLoading extends MessageOperationState {
  const MessageOperationLoading();
}

class MessageOperationSuccess extends MessageOperationState {
  const MessageOperationSuccess({this.message});
  final MessageEntity? message;
}

class MessageOperationError extends MessageOperationState {
  const MessageOperationError(this.error);
  final String error;
}

/// Notifier for message operations.
class MessageNotifier extends StateNotifier<MessageOperationState> {
  MessageNotifier(this._repository) : super(const MessageOperationInitial());

  final MessageRepository _repository;

  /// Sends a message.
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? senderName,
  }) async {
    state = const MessageOperationLoading();
    try {
      final message = await _repository.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        senderName: senderName,
      );
      state = MessageOperationSuccess(message: message);
      return true;
    } catch (e) {
      state = MessageOperationError(e.toString());
      return false;
    }
  }

  /// Gets or creates a conversation.
  Future<ConversationEntity?> getOrCreateConversation({
    required String userId1,
    required String userId2,
    required String userName1,
    required String userName2,
  }) async {
    try {
      return await _repository.getOrCreateConversation(
        userId1: userId1,
        userId2: userId2,
        userName1: userName1,
        userName2: userName2,
      );
    } catch (e) {
      state = MessageOperationError(e.toString());
      return null;
    }
  }

  /// Marks messages as read.
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _repository.markMessagesAsRead(conversationId, userId);
    } catch (e) {
      // Silent fail for marking read
    }
  }
}

/// Provider for the message notifier.
final messageProvider =
    StateNotifierProvider<MessageNotifier, MessageOperationState>((ref) {
      final repository = ref.watch(messageRepositoryProvider);
      return MessageNotifier(repository);
    });
