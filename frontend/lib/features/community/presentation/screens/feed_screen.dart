import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/screen.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/new_discussion_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Screen(
      appBar: _CommunityAppBar(
        showMyDiscussions: feedState.showMyDiscussions,
        onTabChanged: (my) {
          ref.read(feedProvider.notifier).setTab(myDiscussions: my);
        },
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(feedProvider.notifier).search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onSubmitted: (value) =>
                  ref.read(feedProvider.notifier).search(value),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // Post list
          Expanded(
            child: feedState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                    child: feedState.posts.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 48,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(height: AppSpacing.md),
                                    Text(
                                      'No discussions yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Start a new discussion!',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification &&
                                  notification.metrics.extentAfter < 200) {
                                ref.read(feedProvider.notifier).loadMore();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              itemCount: feedState.posts.length +
                                  (feedState.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == feedState.posts.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.lg),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final post = feedState.posts[index];
                                return PostCard(
                                  post: post,
                                  onTap: () => context
                                      .push('/community/post/${post.id}'),
                                  onLike: () => ref
                                      .read(feedProvider.notifier)
                                      .toggleLike(post.id),
                                  onDelete:
                                      post.authorId == currentUser?.id
                                          ? () => _confirmDelete(
                                              context, ref, post.id)
                                          : null,
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(

        onPressed: () => _showNewDiscussion(context, ref),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(feedProvider.notifier).deletePost(postId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNewDiscussion(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewDiscussionModal(
        onSubmit: ({
          required String content,
          required String category,
        }) {
          ref.read(feedProvider.notifier).createPost(
                content: content,
                category: category,
              );
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final bool showMyDiscussions;
  final ValueChanged<bool> onTabChanged;

  const _TabBar({
    required this.showMyDiscussions,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tab(
            label: 'All Discussions',
            isSelected: !showMyDiscussions,
            onTap: () => onTabChanged(false),
          ),
        ),
        Expanded(
          child: _Tab(
            label: 'My Discussions',
            isSelected: showMyDiscussions,
            onTap: () => onTabChanged(true),
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Custom app bar that combines SpectrumAppBar styling with tab bar support.
class _CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMyDiscussions;
  final ValueChanged<bool> onTabChanged;

  const _CommunityAppBar({
    required this.showMyDiscussions,
    required this.onTabChanged,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: AppColors.textPrimary,
          onPressed: () {},
        ),
      ),
      title: const Text(
        'Community',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _TabBar(
          showMyDiscussions: showMyDiscussions,
          onTabChanged: onTabChanged,
        ),
      ),
    );
  }
}
