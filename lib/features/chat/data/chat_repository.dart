import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_starter/features/auth/auth.dart';
import 'package:flutter_chat_starter/features/chat/chat.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: FirebaseFirestore.instance);
});

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({required FirebaseFirestore firestore}) : _firestore = firestore {
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  // --- Conversations ---

  Stream<List<ConversationModel>> getConversations(String currentUserId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> createConversation(String currentUserId, String otherUserId) async {
    // Check if conversation already exists
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new
    final docRef = await _firestore.collection('conversations').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {
        currentUserId: 0,
        otherUserId: 0,
      },
      'typingStatus': {
        currentUserId: false,
        otherUserId: false,
      },
    });
    return docRef.id;
  }

  Future<void> updateTypingStatus(String conversationId, String userId, bool isTyping) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  Future<void> markConversationAsRead(String conversationId, String userId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });
  }

  // --- Messages ---

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> sendMessage(String conversationId, MessageModel message, List<String> otherUserIds) async {
    final batch = _firestore.batch();
    
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();
        
    final messageData = message.toMap();
    // Initially, serverTimestamp isn't generated until it hits the server, 
    // but we can let Firestore handle offline mode gracefully.
    batch.set(messageRef, messageData);

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final updates = {
      'lastMessage': message.type == MessageType.text ? message.text : message.type.name,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    for (var uid in otherUserIds) {
      updates['unreadCounts.$uid'] = FieldValue.increment(1);
    }
    batch.update(convRef, updates);

    await batch.commit();
  }

  Stream<List<MessageModel>> searchMessages(String conversationId, String query) {
    if (query.isEmpty) return Stream.value([]);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('type', isEqualTo: MessageType.text.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .where((m) => m.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> updateMessageStatus(String conversationId, String messageId, MessageStatus status) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status.name});
  }

  Future<void> updateMessageReaction(
      String conversationId, String messageId, String emoji, String userId, bool isAdding) async {
    final docRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final reactions = Map<String, dynamic>.from(snapshot.data()?['reactions'] ?? {});
      
      // Clean up previous reactions by this user (so they only have one per message)
      reactions.forEach((key, value) {
        if (value is List) {
          value.remove(userId);
        }
      });

      if (isAdding) {
        if (!reactions.containsKey(emoji)) {
          reactions[emoji] = [];
        }
        (reactions[emoji] as List).add(userId);
      }

      // Cleanup empty reaction arrays
      reactions.removeWhere((key, value) => (value as List).isEmpty);

      transaction.update(docRef, {'reactions': reactions});
    });
  }

  Future<void> editMessage(String conversationId, String messageId, String newText, String userId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();
    
    if (doc.data()?['senderId'] != userId) {
      throw Exception('Not authorized to edit this message');
    }

    await doc.reference.update({
      'text': newText,
      'isEdited': true,
    });
  }

  Future<void> deleteMessageForMe(String conversationId, String messageId, String userId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> deleteMessageForEveryone(String conversationId, String messageId, String userId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (doc.data()?['senderId'] != userId) {
      throw Exception('Not authorized to delete this message');
    }

    await doc.reference.update({
      'text': 'This message was deleted',
      'isDeletedEveryone': true,
      'type': MessageType.text.name,
      'mediaUrl': null,
    });
  }

  // --- Users ---

  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) return [];
    
    // Firestore doesn't support 'OR' for prefixes, so we do two queries and merge
    final emailQuery = _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final nameQuery = _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final results = await Future.wait([emailQuery, nameQuery]);
    
    final Map<String, UserModel> uniqueUsers = {};
    for (var snapshot in results) {
      for (var doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data());
        if (user.uid != currentUserId) {
          uniqueUsers[user.uid] = user;
        }
      }
    }

    return uniqueUsers.values.toList();
  }
}
