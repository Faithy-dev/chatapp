import 'package:intl/intl.dart';

class DateFormatters {
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime); // e.g., 9:17 AM
  }

  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final aDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (aDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (aDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  static String formatHeaderDate(DateTime dateTime) {
    return 'Today, ${DateFormat('d MMMM').format(dateTime)}'; // Simplified header formatting
  }
}
