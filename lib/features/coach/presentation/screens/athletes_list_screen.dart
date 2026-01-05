import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/coach_provider.dart';

/// Screen displaying all athletes assigned to a coach.
///
/// Provides search, filtering, and navigation to athlete details.
class AthletesListScreen extends ConsumerStatefulWidget {
  /// Creates an athletes list screen.
  const AthletesListScreen({super.key});

  @override
  ConsumerState<AthletesListScreen> createState() => _AthletesListScreenState();
}

class _AthletesListScreenState extends ConsumerState<AthletesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final athletesAsync = ref.watch(athletesStreamProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Athletes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _showAddAthleteDialog,
            tooltip: 'Add Athlete',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: athletesAsync.when(
              data: (athletes) => _buildAthletesList(athletes),
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => _buildErrorState(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search athletes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildAthletesList(List<UserEntity> athletes) {
    final filteredAthletes = athletes.where((athlete) {
      if (_searchQuery.isEmpty) return true;
      return athlete.displayName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    if (filteredAthletes.isEmpty) {
      return _buildEmptyState(athletes.isEmpty);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          ref.invalidate(athletesStreamProvider(currentUser.id));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: filteredAthletes.length,
        itemBuilder: (context, index) {
          final athlete = filteredAthletes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AthleteCard(
              athlete: athlete,
              onTap: () => _navigateToAthleteDetail(athlete.id),
              onAssignPlan: () => _showAssignPlanDialog(athlete),
              onRemove: () => _confirmRemoveAthlete(athlete),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool noAthletes) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noAthletes ? Icons.people_outline : Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            noAthletes ? 'No athletes yet' : 'No athletes found',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            noAthletes
                ? 'Add athletes to start managing their training'
                : 'Try a different search term',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (noAthletes) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'Add Athlete',
              onPressed: _showAddAthleteDialog,
              width: 180,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text('Error loading athletes', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            text: 'Retry',
            onPressed: () {
              final currentUser = ref.read(currentUserProvider);
              if (currentUser != null) {
                ref.invalidate(athletesStreamProvider(currentUser.id));
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToAthleteDetail(String athleteId) {
    context.push(
      RoutePaths.coachAthleteDetail.replaceFirst(':athleteId', athleteId),
    );
  }

  void _showAddAthleteDialog() {
    final emailController = TextEditingController();
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Athlete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the email of an existing athlete to add them to your team.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'athlete@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an email')),
                );
                return;
              }

              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Searching for athlete...')),
              );

              try {
                // Search for user by email
                final usersSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .where('role', isEqualTo: 'athlete')
                    .limit(1)
                    .get();

                if (usersSnapshot.docs.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Athlete not found with that email'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  return;
                }

                final athleteId = usersSnapshot.docs.first.id;
                final athleteData = usersSnapshot.docs.first.data();
                final existingCoachId = athleteData['coachId'] as String?;

                if (existingCoachId == currentUser.id) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This athlete is already in your team'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                  return;
                }

                if (existingCoachId != null && existingCoachId.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This athlete already has a coach. They need to be removed first.',
                        ),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                  return;
                }

                // Assign athlete to coach
                final success = await ref
                    .read(athleteNotifierProvider.notifier)
                    .assignAthleteToCoach(
                      athleteId: athleteId,
                      coachId: currentUser.id,
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Athlete added successfully!'
                            : 'Failed to add athlete',
                      ),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAssignPlanDialog(UserEntity athlete) {
    // Navigate to plan selection for this athlete
    // TODO: Implement plan assignment screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assign plan to ${athlete.displayName} - Coming soon!'),
      ),
    );
  }

  void _confirmRemoveAthlete(UserEntity athlete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Athlete'),
        content: Text(
          'Are you sure you want to remove ${athlete.displayName} from your team? '
          'They will still have access to their data but won\'t receive new plans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(athleteNotifierProvider.notifier)
                  .removeAthleteFromCoach(athlete.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying athlete information.
///
/// Shows athlete name, status, and provides action buttons.
class AthleteCard extends StatelessWidget {
  /// Creates an athlete card.
  const AthleteCard({
    super.key,
    required this.athlete,
    required this.onTap,
    this.onAssignPlan,
    this.onRemove,
  });

  /// The athlete to display.
  final UserEntity athlete;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Called when assign plan is tapped.
  final VoidCallback? onAssignPlan;

  /// Called when remove is tapped.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BaseCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.displayName,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    athlete.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildStatusIndicator(),
                ],
              ),
            ),
            _buildActionMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = athlete.displayName.isNotEmpty
        ? athlete.displayName
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'A';

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: athlete.profilePicture != null
          ? ClipOval(
              child: Image.network(
                athlete.profilePicture!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initials,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          : Text(
              initials,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
    );
  }

  Widget _buildStatusIndicator() {
    // Calculate status based on last activity
    final lastActive = athlete.lastActive;
    String status;
    Color statusColor;

    if (lastActive == null) {
      status = 'Never active';
      statusColor = AppColors.textSecondary;
    } else {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inMinutes < 5) {
        status = 'Active now';
        statusColor = AppColors.success;
      } else if (difference.inHours < 1) {
        status = 'Active ${difference.inMinutes}m ago';
        statusColor = AppColors.success;
      } else if (difference.inHours < 24) {
        status = 'Active ${difference.inHours}h ago';
        statusColor = AppColors.warning;
      } else if (difference.inDays < 7) {
        status = 'Active ${difference.inDays}d ago';
        statusColor = AppColors.warning;
      } else {
        status = 'Inactive';
        statusColor = AppColors.textSecondary;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          status,
          style: AppTextStyles.labelSmall.copyWith(color: statusColor),
        ),
      ],
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      onSelected: (value) {
        switch (value) {
          case 'assign':
            onAssignPlan?.call();
            break;
          case 'remove':
            onRemove?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'assign',
          child: Row(
            children: [
              Icon(Icons.assignment_add, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text('Assign Plan'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.person_remove, size: 20, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text('Remove', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
