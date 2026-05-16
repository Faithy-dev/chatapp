import 'package:flutter/material.dart';
import 'package:flutter_chat_starter/core/core.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildCallList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Text('Calls', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_call, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildCallList() {
    final calls = [
      {'name': 'Lisa', 'time': 'Today, 10:30 AM', 'type': Icons.call_made, 'color': Colors.green},
      {'name': 'Joe', 'time': 'Yesterday, 8:45 PM', 'type': Icons.call_received, 'color': Colors.red},
      {'name': 'Lucas', 'time': 'May 12, 2:15 PM', 'type': Icons.call_made, 'color': Colors.green},
    ];

    return ListView.builder(
      itemCount: calls.length,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemBuilder: (context, index) {
        final call = calls[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Text((call['name'] as String)[0], style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(call['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(call['type'] as IconData, size: 14, color: call['color'] as Color),
                        const SizedBox(width: 4),
                        Text(call['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.call_outlined, color: AppColors.primaryBlue), onPressed: () {}),
            ],
          ),
        );
      },
    );
  }
}
