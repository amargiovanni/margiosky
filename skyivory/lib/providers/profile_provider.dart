import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:xrpc/xrpc.dart';
import 'package:skyivory/providers/auth_provider.dart';

final profileProvider = StateNotifierProvider.family<ProfileNotifier, AsyncValue<bsky.ActorProfile>, String>((ref, handle) {
  final client = ref.watch(blueskyClientProvider);
  return ProfileNotifier(client, handle);
});

final userFeedProvider = StateNotifierProvider.family<UserFeedNotifier, AsyncValue<List<bsky.FeedView>>, String>((ref, handle) {
  final client = ref.watch(blueskyClientProvider);
  return UserFeedNotifier(client, handle);
});

class ProfileNotifier extends StateNotifier<AsyncValue<bsky.ActorProfile>> {
  final bsky.Bluesky? _client;
  final String _handle;

  ProfileNotifier(this._client, this._handle) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (_client == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await _client.actor.getProfile(actor: _handle);
      state = AsyncValue.data(response.data);
    } on UnauthorizedException catch (e, stackTrace) {
      state = AsyncValue.error('Authentication required: ${e.toString()}', stackTrace);
    } on XRPCException catch (e, stackTrace) {
      state = AsyncValue.error('API error: ${e.toString()}', stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to load profile: $e', stackTrace);
    }
  }

  Future<void> followUser() async {
    if (_client == null || !state.hasValue) return;

    try {
      final profile = state.value!;
      await _client.graph.follow(did: profile.did);
      // Reload profile to get updated follower count and following status
      await loadProfile();
    } on UnauthorizedException catch (e) {
      state = AsyncValue.error('Authentication required: ${e.toString()}', StackTrace.current);
    } on XRPCException catch (e) {
      state = AsyncValue.error('API error: ${e.toString()}', StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Failed to follow user: $e', StackTrace.current);
    }
  }

  Future<void> unfollowUser() async {
    if (_client == null || !state.hasValue) return;

    try {
      final profile = state.value!;
      final followingUri = profile.viewer?.following;
      if (followingUri != null) {
        await _client.atproto.repo.deleteRecord(
          uri: followingUri,
        );
        // Reload profile to get updated follower count and following status
        await loadProfile();
      }
    } on UnauthorizedException catch (e) {
      state = AsyncValue.error('Authentication required: ${e.toString()}', StackTrace.current);
    } on XRPCException catch (e) {
      state = AsyncValue.error('API error: ${e.toString()}', StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Failed to unfollow user: $e', StackTrace.current);
    }
  }
}

class UserFeedNotifier extends StateNotifier<AsyncValue<List<bsky.FeedView>>> {
  final bsky.Bluesky? _client;
  final String _handle;
  String? _cursor;
  bool _hasMore = true;

  UserFeedNotifier(this._client, this._handle) : super(const AsyncValue.loading()) {
    loadFeed();
  }

  Future<void> loadFeed({bool refresh = false}) async {
    if (_client == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return;
    }

    if (refresh) {
      _cursor = null;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final response = await _client.feed.getAuthorFeed(
        actor: _handle,
        cursor: _cursor,
        limit: 50,
      );

      final newPosts = response.data.feed;
      _cursor = response.data.cursor;
      _hasMore = response.data.cursor != null;

      if (refresh || !state.hasValue) {
        state = AsyncValue.data(newPosts);
      } else {
        final currentPosts = state.value ?? [];
        state = AsyncValue.data([...currentPosts, ...newPosts]);
      }
    } on UnauthorizedException catch (e, stackTrace) {
      state = AsyncValue.error('Authentication required: ${e.toString()}', stackTrace);
    } on XRPCException catch (e, stackTrace) {
      state = AsyncValue.error('API error: ${e.toString()}', stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to load user feed: $e', stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && state.hasValue) {
      await loadFeed();
    }
  }

  bool get hasMore => _hasMore;
}