import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/message_provider.dart';

/// Screen displaying list of conversations.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final conversationsAsync = ref.watch(conversationsProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState(currentUser.isCoach);
          }
          return _buildConversationList(
            context,
            ref,
            conversations,
            currentUser.id,
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(bool isCoach) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Messages Yet',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isCoach
                  ? 'Start a conversation with your athletes'
                  : 'Your coach hasn\'t messaged you yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    WidgetRef ref,
    List<ConversationEntity> conversations,
    String currentUserId,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationTile(
          conversation: conversation,
          currentUserId: currentUserId,
          onTap: () {
            context.push(
              RoutePaths.chat.replaceAll(':conversationId', conversation.id),
            );
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final ConversationEntity conversation;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.getOtherParticipantName(currentUserId);
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: AppTextStyles.labelSmall.copyWith(
                color: hasUnread ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? 'No messages yet',
              style: AppTextStyles.bodySmall.copyWith(
                color: hasUnread
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
              ),
              child: Text(
                conversation.unreadCount > 9
                    ? '9+'
                    : conversation.unreadCount.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}
