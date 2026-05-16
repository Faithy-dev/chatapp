import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_chat_starter/core/core.dart';
import 'package:flutter_chat_starter/features/auth/auth.dart';
import 'package:flutter_chat_starter/features/chat/chat.dart';

class ChatInput extends ConsumerStatefulWidget {
  final String conversationId;
  final List<String> otherUserIds;
  final String currentUserId;

  const ChatInput({
    super.key,
    required this.conversationId,
    required this.otherUserIds,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _textController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isRecording = false;
  DateTime? _recordStartTime;
  String? _audioPath;

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      if (!_isTyping) {
        _isTyping = true;
        ref.read(chatRepositoryProvider).updateTypingStatus(widget.conversationId, widget.currentUserId, true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isTyping) {
          _isTyping = false;
          ref.read(chatRepositoryProvider).updateTypingStatus(widget.conversationId, widget.currentUserId, false);
        }
      });
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      ref.read(chatRepositoryProvider).updateTypingStatus(widget.conversationId, widget.currentUserId, false);
    }
    setState(() {});
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/${const Uuid().v4()}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordStartTime = DateTime.now();
          _audioPath = path;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await _sendMedia(File(path), MessageType.audio);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await (FilePicker as dynamic).platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      await _sendMedia(File(result.files.single.path!), MessageType.file);
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _onTextChanged('');

    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: widget.currentUserId,
      text: text,
      createdAt: DateTime.now(),
    );

    await ref.read(chatRepositoryProvider).sendMessage(widget.conversationId, message, widget.otherUserIds);
  }

  Future<void> _sendMedia(File file, MessageType type) async {
    setState(() => _isUploading = true);
    try {
      final url = await ref.read(mediaServiceProvider).uploadFile(
        file,
        'chat_media/${widget.conversationId}',
        onProgress: (progress) => setState(() => _uploadProgress = progress),
      );

      final message = MessageModel(
        id: const Uuid().v4(),
        senderId: widget.currentUserId,
        text: type == MessageType.text ? '' : type.name.toUpperCase(),
        type: type,
        mediaUrl: url,
        createdAt: DateTime.now(),
      );

      await ref.read(chatRepositoryProvider).sendMessage(widget.conversationId, message, widget.otherUserIds);
    } finally {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0.0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 4,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
            ),
          if (!_isRecording) _buildAttachmentBar(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _isRecording ? Colors.red.withOpacity(0.3) : Colors.transparent),
                  ),
                  child: _isRecording ? _buildRecordingUI() : TextField(
                    controller: _textController,
                    onChanged: _onTextChanged,
                    maxLines: 5,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          const Text('Recording...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const Spacer(),
          StreamBuilder<Duration>(
            stream: Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now().difference(_recordStartTime!)),
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return Text(
                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              _audioRecorder.stop();
              setState(() => _isRecording = false);
            },
            child: const Icon(Icons.delete_outline, color: Colors.grey, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final showSend = _textController.text.trim().isNotEmpty;

    if (showSend) {
      return GestureDetector(
        onTap: _sendText,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
          child: const Icon(Icons.send, color: Colors.white, size: 24),
        ),
      );
    }

    return GestureDetector(
      onLongPress: _isRecording ? null : _startRecording,
      onLongPressUp: _isRecording ? _stopRecording : null,
      onTap: _isRecording ? _stopRecording : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildAttachmentBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildAttachmentItem(Icons.insert_drive_file_outlined, 'Files', onTap: _pickFile),
          _buildAttachmentItem(Icons.camera_alt_outlined, 'Images', onTap: () => _pickMedia(MessageType.image)),
          _buildAttachmentItem(Icons.videocam_outlined, 'Video', onTap: () => _pickMedia(MessageType.video)),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(MessageType type) async {
    final mediaService = ref.read(mediaServiceProvider);
    File? file;
    if (type == MessageType.image) {
      file = await mediaService.pickImage(ImageSource.gallery);
    } else if (type == MessageType.video) {
      file = await mediaService.pickVideo();
    }
    if (file != null) {
      await _sendMedia(file, type);
    }
  }
}
