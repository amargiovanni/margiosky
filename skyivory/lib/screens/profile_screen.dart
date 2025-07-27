import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:skyivory/providers/auth_provider.dart';
import 'package:skyivory/providers/profile_provider.dart';
import 'package:skyivory/widgets/post_card.dart';

class ProfileScreen extends ConsumerWidget {
  final String? handle;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    this.handle,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final userHandle = handle ?? session?.handle ?? '';
    
    if (userHandle.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No user specified')),
      );
    }

    final profileAsync = ref.watch(profileProvider(userHandle));
    final userFeedAsync = ref.watch(userFeedProvider(userHandle));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider(userHandle));
          ref.invalidate(userFeedProvider(userHandle));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              title: profileAsync.when(
                data: (profile) => Text(
                  profile.displayName ?? profile.handle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                loading: () => const Text('Profile'),
                error: (_, __) => const Text('Profile'),
              ),
              actions: [
                if (isCurrentUser || handle == session?.handle)
                  IconButton(
                    icon: const Icon(CupertinoIcons.gear),
                    onPressed: () {
                      // TODO: Navigate to settings
                    },
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) => _ProfileHeader(
                  profile: profile,
                  isCurrentUser: isCurrentUser || handle == session?.handle,
                  userHandle: userHandle,
                ),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (error, _) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Failed to load profile: $error',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 1,
                color: Theme.of(context).dividerColor,
                margin: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            userFeedAsync.when(
              data: (posts) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= posts.length) {
                      // Load more trigger
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    return PostCard(post: posts[index]);
                  },
                  childCount: posts.length + (ref.read(userFeedProvider(userHandle).notifier).hasMore ? 1 : 0),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Failed to load posts: $error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final dynamic profile;
  final bool isCurrentUser;
  final String userHandle;

  const _ProfileHeader({
    required this.profile,
    required this.isCurrentUser,
    required this.userHandle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.compact();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover and Avatar section
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover image
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: profile.banner != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: profile.banner,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      )
                    : null,
              ),
              // Avatar
              Positioned(
                bottom: -35,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: profile.avatar != null
                        ? CachedNetworkImageProvider(profile.avatar)
                        : null,
                    child: profile.avatar == null
                        ? Icon(
                            CupertinoIcons.person_fill,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          
          // Profile info and follow button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display name
                    Text(
                      profile.displayName ?? profile.handle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Handle
                    Text(
                      '@${profile.handle}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Follow/Unfollow button
              if (!isCurrentUser) ...[
                const SizedBox(width: 12),
                _FollowButton(
                  profile: profile,
                  userHandle: userHandle,
                ),
              ],
            ],
          ),
          
          // Bio
          if (profile.description != null) ...[
            const SizedBox(height: 16),
            Text(
              profile.description!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          
          // Stats
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                label: 'Posts',
                count: profile.postsCount ?? 0,
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'Following',
                count: profile.followsCount ?? 0,
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'Followers',
                count: profile.followersCount ?? 0,
              ),
            ],
          ),
          
          // Logout button for current user
          if (isCurrentUser) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final dynamic profile;
  final String userHandle;

  const _FollowButton({
    required this.profile,
    required this.userHandle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFollowing = profile.viewer?.following != null;

    return ElevatedButton(
      onPressed: () async {
        final notifier = ref.read(profileProvider(userHandle).notifier);
        if (isFollowing) {
          await notifier.unfollowUser();
        } else {
          await notifier.followUser();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing 
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.primary,
        foregroundColor: isFollowing 
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;

  const _StatItem({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.compact();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numberFormat.format(count),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}