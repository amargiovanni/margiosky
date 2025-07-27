import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/atproto.dart' as atproto;
import 'package:at_uri/at_uri.dart';
import 'package:xrpc/xrpc.dart';
import 'package:skyivory/providers/auth_provider.dart';

final postInteractionsProvider = Provider<PostInteractionsService>((ref) {
  final client = ref.watch(blueskyClientProvider);
  return PostInteractionsService(client);
});

class PostInteractionsService {
  final bsky.Bluesky? _client;
  
  PostInteractionsService(this._client);
  
  Future<atproto.StrongRef> likePost(String uri, String cid) async {
    if (_client == null) throw Exception('Not authenticated');
    
    try {
      final response = await _client.feed.like(
        uri: AtUri.parse(uri),
        cid: cid,
      );
      return response.data;
    } on UnauthorizedException catch (e) {
      throw Exception('Authentication required: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API error: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }
  
  Future<void> unlikePost(String likeUri) async {
    if (_client == null) throw Exception('Not authenticated');
    
    try {
      await _client.atproto.repo.deleteRecord(
        uri: AtUri.parse(likeUri),
      );
    } on UnauthorizedException catch (e) {
      throw Exception('Authentication required: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API error: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }
  
  Future<atproto.StrongRef> repost(String uri, String cid) async {
    if (_client == null) throw Exception('Not authenticated');
    
    try {
      final response = await _client.feed.repost(
        uri: AtUri.parse(uri),
        cid: cid,
      );
      return response.data;
    } on UnauthorizedException catch (e) {
      throw Exception('Authentication required: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API error: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to repost: $e');
    }
  }
  
  Future<void> undoRepost(String repostUri) async {
    if (_client == null) throw Exception('Not authenticated');
    
    try {
      await _client.atproto.repo.deleteRecord(
        uri: AtUri.parse(repostUri),
      );
    } on UnauthorizedException catch (e) {
      throw Exception('Authentication required: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API error: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to undo repost: $e');
    }
  }
  
  Future<void> reply({
    required String text,
    required String parentUri,
    required String parentCid,
    required String rootUri,
    required String rootCid,
  }) async {
    if (_client == null) throw Exception('Not authenticated');
    
    try {
      await _client.feed.post(
        text: text,
        reply: bsky.ReplyRef(
          parent: atproto.StrongRef(
            uri: AtUri.parse(parentUri),
            cid: parentCid,
          ),
          root: atproto.StrongRef(
            uri: AtUri.parse(rootUri),
            cid: rootCid,
          ),
        ),
      );
    } on UnauthorizedException catch (e) {
      throw Exception('Authentication required: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API error: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to reply: $e');
    }
  }
  
  Future<void> createPost({
    required String text,
    List<String>? imageUris,
    atproto.StrongRef? quotePost,
  }) async {
    if (_client == null) throw Exception('Not authenticated');
    
    try {
      bsky.Embed? embed;
      
      if (imageUris != null && imageUris.isNotEmpty) {
        // TODO: Implement proper image upload workflow
        // This is a placeholder - in reality you need to:
        // 1. Convert image URIs to bytes
        // 2. Upload each image using: await _client.atproto.repo.uploadBlob(imageBytes)
        // 3. Use the returned blob data in the Image constructor
        
        // For now, skip image embedding until proper upload is implemented
        throw UnimplementedError('Image upload not yet implemented. Please implement uploadBlob workflow.');
      } else if (quotePost != null) {
        // Create quote post embed
        embed = bsky.Embed.record(
          data: bsky.EmbedRecord(ref: quotePost),
        );
      }
      
      await _client.feed.post(
        text: text,
        embed: embed,
      );
    } on UnauthorizedException catch (e) {
      throw Exception('Authentication required: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API error: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }
  
}