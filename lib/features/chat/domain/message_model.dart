import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, audio, file }
enum MessageStatus { sent, delivered, seen }

class MessageModel extends Equatable {
  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final int? duration; // for audio/video
  final DateTime createdAt;
  final bool isEdited;
  final MessageStatus status;
  final Map<String, List<String>> reactions; // emoji: [uids]
  final List<String> deletedFor; // list of uids who deleted this message for themselves
  final bool isDeletedEveryone;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    this.duration,
    required this.createdAt,
    this.isEdited = false,
    this.status = MessageStatus.sent,
    this.reactions = const {},
    this.deletedFor = const [],
    this.isDeletedEveryone = false,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    // Parse reactions map carefully
    final reactionsMap = <String, List<String>>{};
    if (map['reactions'] != null) {
      final rawReactions = map['reactions'] as Map<String, dynamic>;
      rawReactions.forEach((key, value) {
        if (value is List) {
          reactionsMap[key] = List<String>.from(value);
        }
      });
    }

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: map['mediaUrl'],
      duration: map['duration'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: map['isEdited'] ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      reactions: reactionsMap,
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      isDeletedEveryone: map['isDeletedEveryone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type.name,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (duration != null) 'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEdited': isEdited,
      'status': status.name,
      'reactions': reactions,
      'deletedFor': deletedFor,
      'isDeletedEveryone': isDeletedEveryone,
    };
  }

  MessageModel copyWith({
    String? text,
    bool? isEdited,
    MessageStatus? status,
    Map<String, List<String>>? reactions,
    List<String>? deletedFor,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      text: text ?? this.text,
      type: type,
      mediaUrl: mediaUrl,
      duration: duration,
      createdAt: createdAt,
      isEdited: isEdited ?? this.isEdited,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      deletedFor: deletedFor ?? this.deletedFor,
      isDeletedEveryone: isDeletedEveryone ?? this.isDeletedEveryone,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        text,
        type,
        mediaUrl,
        duration,
        createdAt,
        isEdited,
        status,
        reactions,
        deletedFor,
        isDeletedEveryone,
      ];
}
