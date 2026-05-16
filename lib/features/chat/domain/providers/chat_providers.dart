import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_starter/features/auth/auth.dart';
import '../../data/chat_repository.dart';
import '../conversation_model.dart';
import '../message_model.dart';

final conversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).getConversations(user.uid);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).getMessages(conversationId);
});

final userSearchProvider = FutureProvider.family<List<UserModel>, String>((ref, query) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || query.isEmpty) return Future.value([]);
  return ref.watch(chatRepositoryProvider).searchUsers(query, user.uid);
});

// A provider to fetch a single user's details for UI representation
final userDetailsProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).getUserData(uid);
});
