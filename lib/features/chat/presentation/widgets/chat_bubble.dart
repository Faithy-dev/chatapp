import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter_chat_starter/core/core.dart';
import 'package:flutter_chat_starter/features/auth/auth.dart';
import 'package:flutter_chat_starter/features/chat/chat.dart';
import 'chat_input.dart';
import 'fullscreen_video_viewer.dart';

class ChatBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final String conversationId;
  final String searchQuery;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.conversationId,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showReactionPicker(context, ref),
      onDoubleTap: () => _showOptions(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) _buildAvatar(context),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isMe 
                          ? AppColors.primaryBlue 
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: Radius.circular(isMe ? 24 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 24),
                      ),
                      boxShadow: isMe ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isDeletedEveryone)
                          Text(
                            'This message was deleted',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: isMe ? Colors.white70 : Colors.grey,
                            ),
                          )
                        else ...[
                          _buildMessageContent(context),
                          if (message.isEdited)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Edited',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isMe ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormatters.formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildStatusIcon(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMe) const SizedBox(width: 8),
                if (isMe) _buildAvatar(context),
              ],
            ),
            if (message.reactions.isNotEmpty) _buildReactionsRow(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundImage: const NetworkImage('https://i.pravatar.cc/150'), // Placeholder
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildHighlightedText(context, message.text, searchQuery);
      case MessageType.image:
        return _buildImageMedia(context);
      case MessageType.video:
        return _VideoBubble(url: message.mediaUrl!, isMe: isMe);
      case MessageType.audio:
        return _AudioBubble(url: message.mediaUrl!, isMe: isMe);
      case MessageType.file:
        return _buildFileMedia(context);
      default:
        return const Text('Unsupported message');
    }
  }

  Widget _buildImageMedia(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreenImage(context, message.mediaUrl!),
      child: Hero(
        tag: message.mediaUrl!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            width: 220,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(height: 150, width: 220, child: Center(child: CircularProgressIndicator())),
          ),
        ),
      ),
    );
  }

  Widget _buildFileMedia(BuildContext context) {
    final color = isMe ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Document',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = Colors.white70;
    
    switch (message.status) {
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = Colors.blue[300]!;
        break;
    }
    return Icon(icon, size: 12, color: color);
  }

  // Helper methods for reactions, options, etc. (kept similar but styled)
  void _showOptions(BuildContext context, WidgetRef ref) {
    final uid = ref.read(authStateProvider).value!.uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              if (isMe && message.type == MessageType.text)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, ref);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for me'),
                onTap: () {
                  ref.read(chatRepositoryProvider).deleteMessageForMe(conversationId, message.id, uid);
                  Navigator.pop(context);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete for everyone', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    ref.read(chatRepositoryProvider).deleteMessageForEveryone(conversationId, message.id, uid);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: message.text);
    final uid = ref.read(authStateProvider).value!.uid;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: controller, autofocus: true, maxLines: null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && controller.text.trim() != message.text) {
                ref.read(chatRepositoryProvider).editMessage(conversationId, message.id, controller.text.trim(), uid);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((emoji) {
            final uid = ref.read(authStateProvider).value!.uid;
            final hasReacted = message.reactions[emoji]?.contains(uid) ?? false;
            return GestureDetector(
              onTap: () {
                ref.read(chatRepositoryProvider).updateMessageReaction(conversationId, message.id, emoji, uid, !hasReacted);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasReacted ? AppColors.primaryBlue.withOpacity(0.1) : null,
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String query) {
    final textColor = isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text, style: TextStyle(color: textColor, fontSize: 16));
    }
    final matchIndex = text.toLowerCase().indexOf(query.toLowerCase());
    return RichText(
      text: TextSpan(
        style: TextStyle(color: textColor, fontSize: 16),
        children: [
          TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(text: text.substring(matchIndex, matchIndex + query.length), style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black)),
          TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  Widget _buildReactionsRow(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 40, right: isMe ? 40 : 0),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((e) {
          final uid = ref.read(authStateProvider).value!.uid;
          final hasReacted = e.value.contains(uid);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted ? AppColors.primaryBlue.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasReacted ? AppColors.primaryBlue : Colors.transparent),
            ),
            child: Text('${e.key} ${e.value.length}', style: const TextStyle(fontSize: 12)),
          );
        }).toList(),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Hero(
            tag: url,
            child: CachedNetworkImage(imageUrl: url),
          ),
        ),
      ),
    )));
  }
}

// Sub-widgets for Video and Audio
class _AudioBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  const _AudioBubble({required this.url, required this.isMe});
  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  void _toggleSpeed() {
    setState(() {
      if (_speed == 1.0) _speed = 1.5;
      else if (_speed == 1.5) _speed = 2.0;
      else _speed = 1.0;
      _player.setPlaybackRate(_speed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : AppColors.primaryBlue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: color),
          onPressed: () async {
            if (_isPlaying) { await _player.pause(); } else { await _player.play(UrlSource(widget.url)); }
            setState(() => _isPlaying = !_isPlaying);
          },
        ),
        Expanded(
          child: Column(
            children: [
              Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                onChanged: (val) => _player.seek(Duration(seconds: val.toInt())),
                activeColor: color,
                inactiveColor: color.withOpacity(0.3),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: TextStyle(fontSize: 10, color: color)),
                    Text(_formatDuration(_duration), style: TextStyle(fontSize: 10, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _toggleSpeed,
          child: Text('${_speed}x', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _VideoBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  const _VideoBubble({required this.url, required this.isMe});

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() => _isInitialized = true));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenVideoViewer(url: widget.url))),
      child: Container(
        width: 220,
        height: 150,
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: VideoPlayer(_controller),
              ),
            const Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
