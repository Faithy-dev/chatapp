import 'package:flutter/material.dart';
import 'package:flutter_chat_starter/core/core.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMyStatus(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text('Recent Updates', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            Expanded(child: _buildUpdatesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Text('Updates', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMyStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(radius: 30, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=you')),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Tap to add status update', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesList() {
    final updates = [
      {'name': 'Lisa', 'time': '10 mins ago', 'image': 'https://i.pravatar.cc/150?u=lisa'},
      {'name': 'Joe', 'time': '1 hour ago', 'image': 'https://i.pravatar.cc/150?u=joe'},
      {'name': 'Nya', 'time': '2 hours ago', 'image': 'https://i.pravatar.cc/150?u=nya'},
    ];

    return ListView.builder(
      itemCount: updates.length,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemBuilder: (context, index) {
        final update = updates[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue, width: 2),
            ),
            child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(update['image']!)),
          ),
          title: Text(update['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(update['time']!),
        );
      },
    );
  }
}
