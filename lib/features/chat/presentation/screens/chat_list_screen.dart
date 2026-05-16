import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter_chat_starter/core/core.dart';
import 'package:flutter_chat_starter/features/auth/auth.dart';
import 'package:flutter_chat_starter/features/chat/chat.dart';
import 'new_chat_dialog.dart';
import 'chat_screen.dart';
import 'call_screen.dart';
import 'updates_screen.dart';
import 'profile_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int _currentIndex = 0;
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Favorites', 'Work', 'Groups', 'Communities'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? const Color(0xFFF8F9FB) 
          : Colors.black,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const NewChatDialog(),
        ),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildChatList();
      case 1: return const CallScreen();
      case 2: return const UpdatesScreen();
      case 3: return const ProfileScreen();
      default: return _buildChatList();
    }
  }

  Widget _buildChatList() {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildStories(),
          _buildTabs(),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) return _buildEmptyState();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) => _buildChatCard(conversations[index], currentUser?.uid),
                );
              },
              loading: () => _buildShimmerLoading(),
              error: (err, _) => _buildErrorState(err.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
              Text('You have 2 new messages', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const Spacer(),
          _buildCircleIconButton(Icons.search, () {}),
          const SizedBox(width: 12),
          _buildCircleIconButton(Icons.camera_alt_outlined, () {}),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }

  Widget _buildStories() {
    final stories = [
      {'name': 'You', 'image': null},
      {'name': 'Lisa', 'image': 'https://i.pravatar.cc/150?u=lisa', 'unread': 3},
      {'name': 'Nya', 'image': 'https://i.pravatar.cc/150?u=nya', 'unread': 1},
      {'name': 'Lucas', 'image': 'https://i.pravatar.cc/150?u=lucas', 'unread': 2},
      {'name': 'Joe', 'image': 'https://i.pravatar.cc/150?u=joe', 'unread': 0},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (story['unread'] as int? ?? 0) > 0 ? AppColors.primaryBlue : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: story['image'] != null ? NetworkImage(story['image'] as String) : null,
                        child: story['image'] == null ? const Icon(Icons.add, color: Colors.grey) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(story['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatCard(ConversationModel conv, String? currentUserId) {
    final otherUserId = conv.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final otherUserAsync = ref.watch(userDetailsProvider(otherUserId));

    return InkWell(
      onTap: () {
        otherUserAsync.whenData((user) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
            conversationId: conv.id,
            otherUserId: otherUserId,
            otherUserName: user?.displayName ?? 'User',
          )));
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
        ),
        child: Row(
          children: [
            otherUserAsync.when(
              data: (u) => CircleAvatar(
                radius: 30,
                backgroundImage: u?.photoUrl != null ? NetworkImage(u!.photoUrl!) : null,
                child: u?.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              loading: () => const CircleAvatar(radius: 30, child: CircularProgressIndicator()),
              error: (_, __) => const CircleAvatar(radius: 30, child: Icon(Icons.person)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  otherUserAsync.when(
                    data: (u) => Text(u?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    loading: () => const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
                    error: (_, __) => const Text('User'),
                  ),
                  const SizedBox(height: 6),
                  Text(conv.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conv.lastMessageAt != null ? DateFormatters.formatChatListTime(conv.lastMessageAt!) : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                if ((conv.unreadCounts[currentUserId] ?? 0) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(10)),
                    child: Text('${conv.unreadCounts[currentUserId]}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else
                  Icon(Icons.done_all, size: 16, color: Colors.blue[300]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network('https://assets9.lottiefiles.com/packages/lf20_m6cuL6.json', width: 200),
          const SizedBox(height: 16),
          const Text('No chats yet', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)));
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.call_outlined), activeIcon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.update_outlined), activeIcon: Icon(Icons.update), label: 'Updates'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
