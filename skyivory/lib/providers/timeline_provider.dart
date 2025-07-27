import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:xrpc/xrpc.dart';
import 'package:skyivory/providers/auth_provider.dart';

final timelineProvider = StateNotifierProvider.autoDispose<TimelineNotifier, AsyncValue<List<bsky.FeedView>>>((ref) {
  final client = ref.watch(blueskyClientProvider);
  return TimelineNotifier(client, ref);
});

class TimelineNotifier extends StateNotifier<AsyncValue<List<bsky.FeedView>>> {
  final bsky.Bluesky? _client;
  final Ref _ref;
  String? _cursor;
  bool _hasMore = true;
  List<bsky.FeedView> _posts = [];
  
  TimelineNotifier(this._client, this._ref) : super(const AsyncValue.loading()) {
    if (_client != null) {
      loadTimeline();
    } else {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
    }
  }
  
  Future<void> loadTimeline() async {
    if (_client == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return;
    }
    
    try {
      // Fetch real timeline data
      final response = await _client.feed.getTimeline(
        limit: 30, // Number of posts per page
      );
      
      _posts = response.data.feed;
      _cursor = response.data.cursor;
      _hasMore = response.data.cursor != null;
      
      state = AsyncValue.data(_posts);
    } on UnauthorizedException catch (e) {
      // Try to refresh session
      await _tryRefreshSession();
      state = AsyncValue.error('Authentication required: ${e.toString()}', StackTrace.current);
    } on XRPCException catch (e) {
      state = AsyncValue.error('API error: ${e.toString()}', StackTrace.current);
    } catch (e, stack) {
      state = AsyncValue.error('Failed to load timeline: $e', stack);
    }
  }
  
  Future<void> loadMore() async {
    if (!_hasMore || _cursor == null || _client == null) return;
    if (state.isLoading) return;
    
    try {
      // Fetch next page using cursor
      final response = await _client.feed.getTimeline(
        cursor: _cursor,
        limit: 30,
      );
      
      _posts.addAll(response.data.feed);
      _cursor = response.data.cursor;
      _hasMore = response.data.cursor != null;
      
      state = AsyncValue.data(_posts);
    } on UnauthorizedException catch (e) {
      await _tryRefreshSession();
      state = AsyncValue.error('Authentication required: ${e.toString()}', StackTrace.current);
    } catch (e, stack) {
      // Don't override existing posts on error, just show error message
      state = AsyncValue.error('Failed to load more posts: $e', stack);
    }
  }
  
  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    _posts.clear();
    state = const AsyncValue.loading();
    await loadTimeline();
  }
  
  Future<void> _tryRefreshSession() async {
    try {
      await _ref.read(sessionProvider.notifier).refreshSession();
    } catch (e) {
      // Session refresh failed, user will be logged out
    }
  }
}