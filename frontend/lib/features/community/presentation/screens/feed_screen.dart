import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/post.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_filter_sheet.dart';
import '../widgets/new_discussion_modal.dart';
import '../widgets/post_card.dart';

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

  void _openFilters() {
    final feedState = ref.read(feedProvider);
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: 0.7,
      builder: (sheetContext) => FeedFilterSheet(
        selectedCategory: feedState.categoryFilter,
        selectedState: feedState.stateFilter,
        selectedCity: feedState.cityFilter,
        onApply: ({String? category, String? state, String? city}) {
          ref.read(feedProvider.notifier).setFilters(
                category: () => category,
                usState: () => state,
                city: () => city,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Screen(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: FTabs(
                expands: true,
                style: FTabsStyle(
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  labelTextStyle: FVariants.from(
                    context.theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.theme.colors.mutedForeground,
                    ),
                    variants: {
                      [.selected]: TextStyleDelta.delta(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    },
                  ),
                  indicatorDecoration: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.primary, width: 3),
                  ),
                  indicatorSize: FTabBarIndicatorSize.label,
                  height: context.theme.tabsStyle.height,
                  spacing: 0,
                  focusedOutlineStyle:
                      context.theme.tabsStyle.focusedOutlineStyle,
                ),
                control: FTabControl.lifted(
                  index: feedState.showMyDiscussions ? 1 : 0,
                  onChange: (index) {
                    ref
                        .read(feedProvider.notifier)
                        .setTab(myDiscussions: index == 1);
                  },
                ),
                children: [
                  FTabEntry(
                    label: const Text('All Discussions'),
                    child: _FeedTabView(
                      searchController: _searchController,
                      isLoading: feedState.isLoading,
                      isLoadingMore: feedState.isLoadingMore,
                      posts: feedState.posts,
                      showSearch: true,
                      hasActiveFilters: feedState.hasActiveFilters,
                      currentUserId: currentUser?.id,
                      onRefresh: () =>
                          ref.read(feedProvider.notifier).refresh(),
                      onSearchChanged: (query) {
                        ref.read(feedProvider.notifier).searchDebounced(query);
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        ref.read(feedProvider.notifier).search('');
                      },
                      onFilterTap: _openFilters,
                      onLoadMore: () =>
                          ref.read(feedProvider.notifier).loadMore(),
                      onPostTap: (postId) =>
                          context.push('/community/post/$postId'),
                      onLike: (postId) =>
                          ref.read(feedProvider.notifier).toggleLike(postId),
                      onDelete: (postId) =>
                          _confirmDelete(context, ref, postId),
                      emptyTitle: 'No discussions yet',
                      emptyDescription:
                          'Start a conversation with the community.',
                    ),
                  ),
                  FTabEntry(
                    label: const Text('My Discussions'),
                    child: _FeedTabView(
                      searchController: _searchController,
                      isLoading: feedState.isLoading,
                      isLoadingMore: feedState.isLoadingMore,
                      posts: feedState.posts,
                      showSearch: false,
                      hasActiveFilters: false,
                      currentUserId: currentUser?.id,
                      onRefresh: () =>
                          ref.read(feedProvider.notifier).refresh(),
                      onSearchChanged: (_) {},
                      onClearSearch: () {},
                      onFilterTap: () {},
                      onLoadMore: () =>
                          ref.read(feedProvider.notifier).loadMore(),
                      onPostTap: (postId) =>
                          context.push('/community/post/$postId'),
                      onLike: (postId) =>
                          ref.read(feedProvider.notifier).toggleLike(postId),
                      onDelete: (postId) =>
                          _confirmDelete(context, ref, postId),
                      emptyTitle: 'No discussions from you yet',
                      emptyDescription:
                          'Use the compose button to start your first post.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_compose',
        onPressed: () => _showNewDiscussion(context, ref),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String postId) {
    showFDialog<void>(
      context: context,
      builder: (dialogContext, _, animation) => FDialog.adaptive(
        animation: animation,
        title: const Text('Delete discussion?'),
        body: const Text('This action cannot be undone.'),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () {
              ref.read(feedProvider.notifier).deletePost(postId);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNewDiscussion(BuildContext context, WidgetRef ref) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: 0.88,
      builder: (sheetContext) => NewDiscussionModal(
        onSubmit: ({
          required String title,
          required String content,
          String? imageUrl,
          required String category,
        }) {
          ref.read(feedProvider.notifier).createPost(
                title: title,
                content: content,
                imageUrl: imageUrl,
                category: category,
              );
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _FeedTabView extends StatelessWidget {
  final TextEditingController searchController;
  final bool isLoading;
  final bool isLoadingMore;
  final List<Post> posts;
  final bool showSearch;
  final bool hasActiveFilters;
  final String? currentUserId;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onPostTap;
  final ValueChanged<String> onLike;
  final ValueChanged<String> onDelete;
  final String emptyTitle;
  final String emptyDescription;

  const _FeedTabView({
    required this.searchController,
    required this.isLoading,
    required this.isLoadingMore,
    required this.posts,
    required this.showSearch,
    required this.hasActiveFilters,
    required this.currentUserId,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.onLoadMore,
    required this.onPostTap,
    required this.onLike,
    required this.onDelete,
    required this.emptyTitle,
    required this.emptyDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSearch)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FTextField(
                    control: FTextFieldControl.managed(
                      controller: searchController,
                      onChange: (value) => onSearchChanged(value.text),
                    ),
                    hint: 'Search discussions...',
                    prefixBuilder: (context, style, variants) => Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: IconTheme(
                        data: style.iconStyle.resolve(variants),
                        child: const Icon(Icons.search_rounded),
                      ),
                    ),
                    suffixBuilder: searchController.text.isEmpty
                        ? null
                        : (context, style, variants) => IconButton(
                            onPressed: onClearSearch,
                            icon: Icon(
                              Icons.close_rounded,
                              color: style.iconStyle.resolve(variants).color,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Stack(
                  children: [
                    FButton.icon(
                      variant: FButtonVariant.outline,
                      onPress: onFilterTap,
                      child: const Icon(Icons.tune_rounded),
                    ),
                    if (hasActiveFilters)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: isLoading
              ? const Center(child: FCircularProgress())
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: posts.isEmpty
                      ? _EmptyFeedState(
                          title: emptyTitle,
                          description: emptyDescription,
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification &&
                                notification.metrics.extentAfter < 200) {
                              onLoadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              AppSpacing.sm,
                              0,
                              96,
                            ),
                            itemCount: posts.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == posts.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Center(child: FCircularProgress()),
                                );
                              }

                              final post = posts[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: PostCard(
                                  post: post,
                                  onTap: () => onPostTap(post.id),
                                  onLike: () => onLike(post.id),
                                  onCommentTap: () => onPostTap(post.id),
                                  onDelete: post.authorId == currentUserId
                                      ? () => onDelete(post.id)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyFeedState({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 96),
        Icon(Icons.forum_outlined, size: 48, color: colors.mutedForeground),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: typography.lg.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          textAlign: TextAlign.center,
          style: typography.sm.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}
