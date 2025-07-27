import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skyivory/providers/auth_provider.dart';
import 'package:skyivory/providers/post_interactions_provider.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final String? replyToUri;
  final String? replyToCid;
  final String? replyToRootUri;
  final String? replyToRootCid;
  final String? replyToAuthor;
  final String? replyToText;
  
  const ComposeScreen({
    super.key,
    this.replyToUri,
    this.replyToCid,
    this.replyToRootUri,
    this.replyToRootCid,
    this.replyToAuthor,
    this.replyToText,
  });

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;
  
  bool get _isReply => widget.replyToUri != null;
  
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
        title: Text(_isReply ? 'Reply' : 'New Post'),
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
                    _isReply ? 'Reply' : 'Post',
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