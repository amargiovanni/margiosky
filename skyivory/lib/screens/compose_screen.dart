import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/atproto.dart' as atproto;
import 'package:at_uri/at_uri.dart';
import 'package:skyivory/providers/auth_provider.dart';
import 'package:skyivory/providers/post_interactions_provider.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final String? replyToUri;
  final String? replyToCid;
  final String? replyToRootUri;
  final String? replyToRootCid;
  final String? replyToAuthor;
  final String? replyToText;
  
  // Quote post parameters
  final String? quotePostUri;
  final String? quotePostCid;
  final bsky.ActorBasic? quotePostAuthor;
  final String? quotePostText;
  
  const ComposeScreen({
    super.key,
    this.replyToUri,
    this.replyToCid,
    this.replyToRootUri,
    this.replyToRootCid,
    this.replyToAuthor,
    this.replyToText,
    this.quotePostUri,
    this.quotePostCid,
    this.quotePostAuthor,
    this.quotePostText,
  });

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;
  
  bool get _isReply => widget.replyToUri != null;
  bool get _isQuotePost => widget.quotePostUri != null;
  
  @override
  void initState() {
    super.initState();
    if (_isReply && widget.replyToAuthor != null) {
      _textController.text = '@${widget.replyToAuthor} ';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
    
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReply ? 'Reply' : _isQuotePost ? 'Quote Post' : 'New Post'),
        leading: TextButton(
          onPressed: _isPosting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        actions: [
          TextButton(
            onPressed: _canPost() && !_isPosting ? _post : null,
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isReply ? 'Reply' : _isQuotePost ? 'Quote' : 'Post',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _canPost() 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).disabledColor,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isReply) _buildReplyContext(),
          if (_isQuotePost) _buildQuotePostContext(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: session?.handle != null
                        ? const CachedNetworkImageProvider(
                            'https://avatar.placeholder.com/40x40')
                        : null,
                    child: session?.handle != null
                        ? null
                        : const Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: _isReply 
                                ? 'Tweet your reply'
                                : _isQuotePost
                                    ? 'Add a comment'
                                    : 'What\'s happening?',
                            border: InputBorder.none,
                            counterText: '${_textController.text.length}/300',
                          ),
                          style: const TextStyle(fontSize: 18),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildComposeToolbar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReplyContext() {
    if (!_isReply || widget.replyToText == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(
              'https://avatar.placeholder.com/32x32'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.replyToAuthor}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.replyToText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuotePostContext() {
    if (!_isQuotePost || widget.quotePostText == null || widget.quotePostAuthor == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.quotePostAuthor!.avatar != null
                ? CachedNetworkImageProvider(widget.quotePostAuthor!.avatar!)
                : null,
            child: widget.quotePostAuthor!.avatar == null
                ? Text(
                    (widget.quotePostAuthor!.displayName?.isNotEmpty == true 
                        ? widget.quotePostAuthor!.displayName!.substring(0, 1) 
                        : widget.quotePostAuthor!.handle.substring(0, 1)
                    ).toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.quotePostAuthor!.displayName?.isNotEmpty == true 
                          ? widget.quotePostAuthor!.displayName! 
                          : widget.quotePostAuthor!.handle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@${widget.quotePostAuthor!.handle}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.quotePostText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComposeToolbar() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            // TODO: Add image picker
          },
          icon: const Icon(CupertinoIcons.photo),
          tooltip: 'Add photo',
        ),
        IconButton(
          onPressed: () {
            // TODO: Add GIF picker
          },
          icon: const Icon(CupertinoIcons.smiley),
          tooltip: 'Add emoji',
        ),
        IconButton(
          onPressed: () {
            // TODO: Add location
          },
          icon: const Icon(CupertinoIcons.location),
          tooltip: 'Add location',
        ),
        const Spacer(),
        if (_textController.text.isNotEmpty)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getProgressColor(),
            ),
            child: CircularProgressIndicator(
              value: _textController.text.length / 300,
              strokeWidth: 2,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
          ),
      ],
    );
  }
  
  Color _getProgressColor() {
    final length = _textController.text.length;
    if (length > 280) return Colors.red;
    if (length > 260) return Colors.orange;
    return Theme.of(context).primaryColor;
  }
  
  bool _canPost() {
    final text = _textController.text.trim();
    return text.isNotEmpty && text.length <= 300;
  }
  
  Future<void> _post() async {
    if (!_canPost() || _isPosting) return;
    
    setState(() {
      _isPosting = true;
    });
    
    try {
      final postService = ref.read(postInteractionsProvider);
      final text = _textController.text.trim();
      
      if (_isReply) {
        await postService.reply(
          text: text,
          parentUri: widget.replyToUri!,
          parentCid: widget.replyToCid!,
          rootUri: widget.replyToRootUri ?? widget.replyToUri!,
          rootCid: widget.replyToRootCid ?? widget.replyToCid!,
        );
      } else if (_isQuotePost) {
        // Create quote post with embedded reference
        final quoteRef = atproto.StrongRef(
          uri: AtUri.parse(widget.quotePostUri!),
          cid: widget.quotePostCid!,
        );
        await postService.createPost(
          text: text,
          quotePost: quoteRef,
        );
      } else {
        await postService.createPost(text: text);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }
}