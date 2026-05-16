import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCounts;
  final Map<String, bool> typingStatus;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCounts = const {},
    this.typingStatus = const {},
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      typingStatus: Map<String, bool>.from(map['typingStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCounts': unreadCounts,
      'typingStatus': typingStatus,
    };
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        lastMessage,
        lastMessageAt,
        unreadCounts,
        typingStatus,
      ];
}
