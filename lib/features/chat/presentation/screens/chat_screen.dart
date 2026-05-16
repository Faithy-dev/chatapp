import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:flutter_chat_starter/core/core.dart';
import 'package:flutter_chat_starter/features/auth/auth.dart';
import 'package:flutter_chat_starter/features/chat/chat.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  List<int> _searchIndices = [];
  int _currentSearchIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(chatRepositoryProvider).markConversationAsRead(widget.conversationId, user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markAsSeen(String messageId) {
    ref.read(chatRepositoryProvider).updateMessageStatus(widget.conversationId, messageId, MessageStatus.seen);
  }

  void _markAsDeliveredIfNecessary(List<MessageModel> messages, String currentUserId) {
    final sentMessages = messages.where((m) => m.senderId != currentUserId && m.status == MessageStatus.sent);
    for (var m in sentMessages) {
      ref.read(chatRepositoryProvider).updateMessageStatus(widget.conversationId, m.id, MessageStatus.delivered);
    }
  }

  void _updateSearchIndices(List<MessageModel> messages, String query) {
    if (query.isEmpty) {
      _searchIndices = [];
      _currentSearchIndex = -1;
      return;
    }
    _searchIndices = [];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].text.toLowerCase().contains(query.toLowerCase())) {
        _searchIndices.add(i);
      }
    }
    if (_searchIndices.isNotEmpty && _currentSearchIndex == -1) {
      _currentSearchIndex = 0;
      _scrollToSearchIndex();
    }
  }

  void _scrollToSearchIndex() {
    if (_currentSearchIndex >= 0 && _currentSearchIndex < _searchIndices.length) {
      _itemScrollController.scrollTo(
        index: _searchIndices[_currentSearchIndex],
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) return const Scaffold();

    bool isOtherUserTyping = false;
    conversationsAsync.whenData((convs) {
      final conv = convs.firstWhere((c) => c.id == widget.conversationId, orElse: () => ConversationModel(id: '', participants: [], lastMessage: '', lastMessageAt: DateTime.now()));
      if (conv.id.isNotEmpty && conv.typingStatus[widget.otherUserId] == true) {
        isOtherUserTyping = true;
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? const Color(0xFFF2F4F7) 
          : Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateSearchIndices(messages, _searchQuery);
                  _markAsDeliveredIfNecessary(messages, currentUser.uid);
                });

                if (_isSearching && _searchQuery.isNotEmpty && _searchIndices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No results found', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    if (message.deletedFor.contains(currentUser.uid)) {
                      return const SizedBox.shrink();
                    }

                    return VisibilityDetector(
                      key: Key(message.id),
                      onVisibilityChanged: (info) {
                        if (info.visibleFraction > 0.5 && 
                            message.senderId != currentUser.uid && 
                            message.status != MessageStatus.seen) {
                          _markAsSeen(message.id);
                        }
                      },
                      child: ChatBubble(
                        message: message,
                        isMe: message.senderId == currentUser.uid,
                        conversationId: widget.conversationId,
                        searchQuery: _searchQuery,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          if (isOtherUserTyping) _buildTypingIndicator(),
          ChatInput(
            conversationId: widget.conversationId,
            otherUserIds: [widget.otherUserId],
            currentUserId: currentUser.uid,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          }),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search message...', border: InputBorder.none),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        actions: [
          if (_searchIndices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('${_currentSearchIndex + 1}/${_searchIndices.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => setState(() {
                _currentSearchIndex = (_currentSearchIndex - 1 + _searchIndices.length) % _searchIndices.length;
                _scrollToSearchIndex();
              }),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => setState(() {
                _currentSearchIndex = (_currentSearchIndex + 1) % _searchIndices.length;
                _scrollToSearchIndex();
              }),
            ),
          ],
        ],
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            widget.otherUserName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.green, size: 8),
              SizedBox(width: 4),
              Text(
                'Active Now',
                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)),
        IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 10, child: Text(widget.otherUserName[0])),
          const SizedBox(width: 8),
          TypingIndicator(),
        ],
      ),
    );
  }
}
