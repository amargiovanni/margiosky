import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:skyivory/providers/post_interactions_provider.dart';
import 'package:skyivory/providers/timeline_provider.dart';
import 'package:skyivory/screens/compose_screen.dart';
import 'package:skyivory/screens/profile_screen.dart';

class PostCard extends ConsumerWidget {
  final bsky.FeedView post;
  
  const PostCard({
    super.key,
    required this.post,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = post.post.author;
    
    return InkWell(
      onTap: () {
        // TODO: Navigate to post detail
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, author),
            const SizedBox(height: 8),
            _buildContent(context, post.post),
            if (post.post.embed != null) ...[
              const SizedBox(height: 12),
              _buildEmbed(context, post.post.embed!),
            ],
            const SizedBox(height: 12),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, bsky.ActorBasic author) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _navigateToProfile(context, author.handle),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: author.avatar != null
                ? CachedNetworkImageProvider(author.avatar!)
                : null,
            child: author.avatar == null
                ? Text(
                    (author.displayName?.isNotEmpty == true 
                        ? author.displayName!.substring(0, 1) 
                        : author.handle.substring(0, 1)
                    ).toUpperCase()
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () => _navigateToProfile(context, author.handle),
                      child: Text(
                        author.displayName?.isNotEmpty == true 
                            ? author.displayName! 
                            : author.handle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '@${author.handle}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                timeago.format(post.post.indexedAt),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.ellipsis),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () {
            // TODO: Show post options
          },
        ),
      ],
    );
  }
  
  Widget _buildContent(BuildContext context, bsky.Post post) {
    String text = '';
    
    try {
      // Get text from post record
      if (post.record is bsky.PostRecord) {
        final record = post.record as bsky.PostRecord;
        text = record.text;
      } else {
        text = 'Unable to display post content';
      }
    } catch (e) {
      text = 'Unable to display post content';
    }
    
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
  
  Widget _buildEmbed(BuildContext context, bsky.EmbedView embed) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildEmbedContent(context, embed),
    );
  }
  
  Widget _buildEmbedContent(BuildContext context, bsky.EmbedView embed) {
    return embed.when(
      images: (data) => _buildImageEmbed(context, data),
      external: (data) => _buildExternalEmbed(context, data),
      record: (data) => _buildSimpleQuoteEmbed(context),
      recordWithMedia: (data) => _buildSimpleRecordWithMedia(context),
      video: (data) => _buildSimpleVideoEmbed(context),
      unknown: (data) => _buildUnknownEmbed(context),
    );
  }
  
  Widget _buildImageEmbed(BuildContext context, bsky.EmbedViewImages imageEmbed) {
    final images = imageEmbed.images;
    if (images.isEmpty) return const SizedBox.shrink();
    
    if (images.length == 1) {
      return _buildSingleImage(context, images.first);
    } else {
      return _buildImageGrid(context, images);
    }
  }
  
  Widget _buildSingleImage(BuildContext context, bsky.EmbedViewImagesView image) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, image.fullsize, image.alt),
      child: CachedNetworkImage(
        imageUrl: image.fullsize,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          height: 200,
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: Icon(Icons.error_outline),
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageGrid(BuildContext context, List<bsky.EmbedViewImagesView> images) {
    final int count = images.length;
    final int crossAxisCount = count == 2 ? 2 : 2;
    final double aspectRatio = count == 2 ? 1.5 : 1.0;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: aspectRatio,
      ),
      itemCount: count > 4 ? 4 : count,
      itemBuilder: (context, index) {
        final image = images[index];
        final isLastItem = index == 3 && count > 4;
        
        return GestureDetector(
          onTap: () => _openImageViewer(context, image.fullsize, image.alt),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: image.thumbnail,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.error_outline),
                ),
              ),
              if (isLastItem)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${count - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildExternalEmbed(BuildContext context, bsky.EmbedViewExternal externalEmbed) {
    final external = externalEmbed.external;
    
    return InkWell(
      onTap: () => _launchUrl(external.uri),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (external.thumbnail != null) ...[
            CachedNetworkImage(
              imageUrl: external.thumbnail!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Theme.of(context).colorScheme.surface,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.error_outline),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  external.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (external.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    external.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        Uri.parse(external.uri).host,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleQuoteEmbed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            'Quote post',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleRecordWithMedia(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.featured_play_list,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            'Quote post with media',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleVideoEmbed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            'Video content',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotFoundCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            'Post not found',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBlockedCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.block,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            'Post from blocked user',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildUnknownEmbed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            'Unsupported content type',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _ActionButton(
          icon: CupertinoIcons.bubble_left,
          count: post.post.replyCount,
          onPressed: () => _reply(context),
        ),
        const SizedBox(width: 32),
        _ActionButton(
          icon: CupertinoIcons.arrow_2_squarepath,
          count: post.post.repostCount,
          isActive: post.post.viewer.repost != null,
          activeColor: Colors.green,
          onPressed: () => _showRepostOptions(context, ref),
        ),
        const SizedBox(width: 32),
        _ActionButton(
          icon: CupertinoIcons.heart,
          count: post.post.likeCount,
          isActive: post.post.viewer.like != null,
          activeIcon: CupertinoIcons.heart_fill,
          activeColor: Colors.red,
          onPressed: () => _like(context, ref),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(CupertinoIcons.share),
          iconSize: 18,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () => _share(context),
        ),
      ],
    );
  }
  
  void _openImageViewer(BuildContext context, String imageUrl, String alt) {
    // TODO: Implement full-screen image viewer with pinch-to-zoom
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  void _reply(BuildContext context) {
    // Get post text for context
    String postText = '';
    try {
      if (post.post.record is bsky.PostRecord) {
        final record = post.post.record as bsky.PostRecord;
        postText = record.text;
      }
    } catch (e) {
      postText = '';
    }
    
    // Determine root URI and CID for proper thread handling
    String rootUri;
    String rootCid;
    
    try {
      if (post.post.record is bsky.PostRecord) {
        final record = post.post.record as bsky.PostRecord;
        if (record.reply != null && record.reply!.root != null) {
          // This is already a reply, use the existing root
          rootUri = record.reply!.root!.uri.toString();
          rootCid = record.reply!.root!.cid;
        } else {
          // This is the original post, it becomes the root
          rootUri = post.post.uri.toString();
          rootCid = post.post.cid;
        }
      } else {
        // Fallback: treat current post as root
        rootUri = post.post.uri.toString();
        rootCid = post.post.cid;
      }
    } catch (e) {
      // Fallback: treat current post as root
      rootUri = post.post.uri.toString();
      rootCid = post.post.cid;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyToUri: post.post.uri.toString(),
          replyToCid: post.post.cid,
          replyToRootUri: rootUri,
          replyToRootCid: rootCid,
          replyToAuthor: post.post.author.handle,
          replyToText: postText,
        ),
      ),
    );
  }
  
  void _like(BuildContext context, WidgetRef ref) async {
    final postService = ref.read(postInteractionsProvider);
    final isLiked = post.post.viewer.like != null;
    
    try {
      if (isLiked) {
        await postService.unlikePost(post.post.viewer.like!.toString());
        // Update local state
        ref.read(timelineProvider.notifier).updatePostInteraction(
          post.post.uri.toString(),
          liked: false,
        );
      } else {
        final likeRef = await postService.likePost(
          post.post.uri.toString(),
          post.post.cid,
        );
        // Update local state with the returned like URI
        ref.read(timelineProvider.notifier).updatePostInteraction(
          post.post.uri.toString(),
          liked: true,
          likeUri: likeRef.uri.toString(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isLiked ? 'unlike' : 'like'} post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _repost(BuildContext context, WidgetRef ref) async {
    final postService = ref.read(postInteractionsProvider);
    final isReposted = post.post.viewer.repost != null;
    
    try {
      if (isReposted) {
        await postService.undoRepost(post.post.viewer.repost!.toString());
        // Update local state
        ref.read(timelineProvider.notifier).updatePostInteraction(
          post.post.uri.toString(),
          reposted: false,
        );
      } else {
        final repostRef = await postService.repost(
          post.post.uri.toString(),
          post.post.cid,
        );
        // Update local state with the returned repost URI
        ref.read(timelineProvider.notifier).updatePostInteraction(
          post.post.uri.toString(),
          reposted: true,
          repostUri: repostRef.uri.toString(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isReposted ? 'undo repost' : 'repost'}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _share(BuildContext context) {
    // TODO: Implement native share
    final postUrl = 'https://bsky.app/profile/${post.post.author.handle}/post/${post.post.uri.toString().split('/').last}';
    _launchUrl(postUrl);
  }
  
  void _navigateToProfile(BuildContext context, String handle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          handle: handle,
          isCurrentUser: false,
        ),
      ),
    );
  }

  void _showRepostOptions(BuildContext context, WidgetRef ref) {
    final isReposted = post.post.viewer.repost != null;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isReposted) ...[
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_2_squarepath),
                title: const Text('Repost'),
                onTap: () {
                  Navigator.pop(context);
                  _repost(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.quote_bubble),
                title: const Text('Quote Post'),
                onTap: () {
                  Navigator.pop(context);
                  _quotePost(context);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_2_squarepath, color: Colors.red),
                title: const Text('Undo Repost', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _repost(context, ref);
                },
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _quotePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          quotePostUri: post.post.uri.toString(),
          quotePostCid: post.post.cid,
          quotePostAuthor: post.post.author,
          quotePostText: _getPostText(),
        ),
      ),
    );
  }

  String _getPostText() {
    try {
      if (post.post.record is bsky.PostRecord) {
        final record = post.post.record as bsky.PostRecord;
        return record.text;
      }
    } catch (e) {
      // Ignore
    }
    return '';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final int count;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onPressed;
  
  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onPressed,
    this.activeIcon,
    this.isActive = false,
    this.activeColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Icon(
              isActive ? (activeIcon ?? icon) : icon,
              size: 18,
              color: isActive ? activeColor : null,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? activeColor : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}