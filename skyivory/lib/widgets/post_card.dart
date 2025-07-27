import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final bsky.FeedView post;
  
  const PostCard({
    super.key,
    required this.post,
  });
  
  @override
  Widget build(BuildContext context) {
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
            _buildActions(context),
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
          onTap: () {
            // TODO: Navigate to profile
          },
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
    // Handle different types of embeds
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildEmbedContent(context, embed),
    );
  }
  
  Widget _buildEmbedContent(BuildContext context, bsky.EmbedView embed) {
    // Simplified embed handling for now
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Embed content (${embed.runtimeType})',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
  
  
  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: CupertinoIcons.bubble_left,
          count: post.post.replyCount,
          onPressed: () {
            // TODO: Reply
          },
        ),
        const SizedBox(width: 32),
        _ActionButton(
          icon: CupertinoIcons.arrow_2_squarepath,
          count: post.post.repostCount,
          onPressed: () {
            // TODO: Repost
          },
        ),
        const SizedBox(width: 32),
        _ActionButton(
          icon: CupertinoIcons.heart,
          count: post.post.likeCount,
          isActive: post.post.viewer.like != null,
          activeIcon: CupertinoIcons.heart_fill,
          activeColor: Colors.red,
          onPressed: () {
            // TODO: Like/unlike
          },
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(CupertinoIcons.share),
          iconSize: 18,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () {
            // TODO: Share
          },
        ),
      ],
    );
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