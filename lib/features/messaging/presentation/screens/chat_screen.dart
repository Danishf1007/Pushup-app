import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/message_provider.dart';

/// Screen for chatting in a conversation.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.recipientName,
  });

  final String conversationId;
  final String? recipientName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String? _recipientId;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref
          .read(messageProvider.notifier)
          .markAsRead(widget.conversationId, currentUser.id);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || _recipientId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await ref
        .read(messageProvider.notifier)
        .sendMessage(
          senderId: currentUser.id,
          receiverId: _recipientId!,
          content: content,
          senderName: currentUser.displayName,
        );

    setState(() => _isSending = false);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversationsAsync = currentUser != null
        ? ref.watch(conversationsProvider(currentUser.id))
        : null;

    // Get recipient info from conversation
    String title = widget.recipientName ?? 'Chat';
    if (conversationsAsync != null && currentUser != null) {
      conversationsAsync.whenData((conversations) {
        final conversation = conversations
            .where((c) => c.id == widget.conversationId)
            .firstOrNull;
        if (conversation != null) {
          title = conversation.getOtherParticipantName(currentUser.id);
          _recipientId = conversation.getOtherParticipantId(currentUser.id);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessageList(messages, currentUser?.id),
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<MessageEntity> messages,
    String? currentUserId,
  ) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No messages yet',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Send a message to start the conversation',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showDate =
            index == 0 ||
            !_isSameDay(messages[index - 1].sentAt, message.sentAt);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.sentAt),
            _MessageBubble(message: message, isMe: isMe),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    String text;

    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = '${date.month}/${date.day}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
          ),
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.radiusCircular,
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final MessageEntity message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
          left: isMe ? AppSpacing.xxl : 0,
          right: isMe ? 0 : AppSpacing.xxl,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isMe ? AppSpacing.radiusMd : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusMd),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.sentAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
