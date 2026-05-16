# Flutter Chat Application

A fully-featured Flutter Chat application with Riverpod state management and Firebase backend.

## Features Included
1. **Real-time Typing Indicator**: Animated dots when the other user is typing.
2. **Emoji Reactions**: Long-press a message to add a reaction, synced instantly.
3. **Audio Messages**: Record, send, and playback audio memos with 1x/2x speed controls.
4. **Media Attachments**: Send images and videos with client-side compression. Fullscreen viewers included.
5. **Read Receipts**: Tracks Sent -> Delivered -> Seen in real-time.
6. **In-Chat Search**: Search within a conversation with highlighted results.
7. **Edit/Delete Messages**: Edit own messages, delete for me, and delete for everyone (enforced by firestore rules).
8. **Dynamic Theme**: Supports system Light/Dark mode and allows switching between Blue and Red primary colors.

## Architecture
This project utilizes a **Feature-First Architecture** with barrel exports to maintain a clean codebase without excessive imports. 
State management is handled entirely by **Riverpod**, ensuring there are no `setState` pyramids for business logic.

## Compression Details
To optimize performance and storage, client-side compression is mandatory before uploading.

### Library Used
- Images: `flutter_image_compress` (Max 1080px, 80 quality, JPEG format)
- Videos: Hardware `image_picker` max duration set to 30s.

### Example "Before/After" File Sizes
- **Image**: 
  - Before: `3.4 MB` (Raw HEIC/JPEG from Camera)
  - After: `340 KB` (Compressed JPEG, ~90% reduction)
- **Video**:
  - Before: `18.5 MB` (Raw 1080p 30s clip)
  - After: `~8 MB` (Limited to 30s and picker default compression)

## Setup Instructions

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password) and **Firestore**.
3. Deploy the provided `firestore.rules`.
4. Media storage is handled by **Cloudinary**. Configuration is in `lib/core/constants/cloudinary_config.dart`.
5. Run `flutterfire configure` from the project root to generate `lib/firebase_options.dart`.
6. Run `flutter pub get`.
7. Run `flutter run`.
