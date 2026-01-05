import 'package:equatable/equatable.dart';

/// Entity representing a chat message between coach and athlete.
class MessageEntity extends Equatable {
  /// Creates a new [MessageEntity].
  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.readAt,
    this.senderName,
  });

  /// Unique message identifier.
  final String id;

  /// ID of the user who sent the message.
  final String senderId;

  /// ID of the user who receives the message.
  final String receiverId;

  /// Message content.
  final String content;

  /// When the message was sent.
  final DateTime sentAt;

  /// When the message was read (null if unread).
  final DateTime? readAt;

  /// Display name of the sender.
  final String? senderName;

  /// Whether the message has been read.
  bool get isRead => readAt != null;

  /// Creates a copy with modified fields.
  MessageEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? sentAt,
    DateTime? readAt,
    String? senderName,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    sentAt,
    readAt,
  ];
}

/// Entity representing a conversation between two users.
class ConversationEntity extends Equatable {
  /// Creates a new [ConversationEntity].
  const ConversationEntity({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  /// Unique conversation identifier.
  final String id;

  /// IDs of participants.
  final List<String> participantIds;

  /// Names of participants mapped by ID.
  final Map<String, String> participantNames;

  /// Preview of the last message.
  final String? lastMessage;

  /// When the last message was sent.
  final DateTime? lastMessageAt;

  /// Number of unread messages.
  final int unreadCount;

  /// Gets the other participant's name given the current user's ID.
  String getOtherParticipantName(String currentUserId) {
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Gets the other participant's ID given the current user's ID.
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
  }

  @override
  List<Object?> get props => [
    id,
    participantIds,
    lastMessage,
    lastMessageAt,
    unreadCount,
  ];
}
