import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:xrpc/xrpc.dart';
import 'package:at_uri/at_uri.dart';
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
  
  void updatePostInteraction(String uri, {bool? liked, String? likeUri, bool? reposted, String? repostUri}) {
    if (!state.hasValue) return;
    
    final updatedPosts = _posts.map((feedView) {
      if (feedView.post.uri.toString() == uri) {
        // Create a new viewer object with updated state
        var updatedViewer = feedView.post.viewer;
        
        if (liked != null) {
          if (liked && likeUri != null) {
            // Convert String to AtUri
            updatedViewer = updatedViewer.copyWith(like: AtUri.parse(likeUri));
          } else if (!liked) {
            updatedViewer = updatedViewer.copyWith(like: null);
          }
        }
        
        if (reposted != null) {
          if (reposted && repostUri != null) {
            // Convert String to AtUri
            updatedViewer = updatedViewer.copyWith(repost: AtUri.parse(repostUri));
          } else if (!reposted) {
            updatedViewer = updatedViewer.copyWith(repost: null);
          }
        }
        
        // Update counts
        var likeCount = feedView.post.likeCount ?? 0;
        var repostCount = feedView.post.repostCount ?? 0;
        
        if (liked != null) {
          likeCount += liked ? 1 : -1;
        }
        
        if (reposted != null) {
          repostCount += reposted ? 1 : -1;
        }
        
        // Create updated post with new viewer state
        final updatedPost = feedView.post.copyWith(
          viewer: updatedViewer,
          likeCount: likeCount,
          repostCount: repostCount,
        );
        
        // Return updated FeedView
        return feedView.copyWith(post: updatedPost);
      }
      return feedView;
    }).toList();
    
    _posts = updatedPosts;
    state = AsyncValue.data(_posts);
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