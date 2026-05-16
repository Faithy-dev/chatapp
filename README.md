# 🚀 Premium Flutter Chat Application

A high-performance, feature-rich chat application built with Flutter, Riverpod, and Firebase. This project focuses on real-time responsiveness, clean architecture, and a premium user experience with a modern glassmorphic UI.

---

## ✨ Key Features

### 💬 Messaging & Real-time Sync
- **Real-time Synchronization**: Messages sync in under 2 seconds across all devices.
- **Typing Indicators**: Dynamic visual cues when the other user is composing a message.
- **Read Receipts**: Sophisticated status tracking (**Sent** → **Delivered** → **Seen**).
- **In-Chat Search**: Lightning-fast search within conversations with highlighted results and easy navigation.

### 📁 Media & Rich Content
- **Audio Messages**: High-quality voice recording and playback with adjustable speeds (1x, 1.5x, 2x).
- **Media Attachments**: Seamless sending of images, videos, and documents.
- **Client-Side Compression**: Mandatory compression of media before upload to optimize bandwidth and storage.
- **Full-Screen Viewers**: Integrated immersive viewers for images and videos.

### 🛠 Message Controls
- **Edit/Delete**: Full control over your sent messages, including "Delete for Everyone" enforced by server-side rules.
- **Emoji Reactions**: Express yourself with instant reactions, synced in real-time.

### 🎨 Design & UX
- **Glassmorphic UI**: A modern, premium aesthetic with blur effects and sleek transitions.
- **Dynamic Themes**: Support for system Light/Dark modes and custom primary color switching (Blue/Red).
- **Optimized Performance**: Shimmer loading states and smooth animations for a fluid experience.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore)
- **Media Storage**: [Cloudinary](https://cloudinary.com)
- **Navigation**: Imperative & Declarative hybrid with standard Flutter Navigator
- **Architecture**: **Feature-First Architecture** with Clean Domain/Data/Presentation separation.

---

## 🏗 Project Structure

```text
lib/
├── core/               # Shared utilities, constants, and themes
├── features/
│   ├── auth/           # Authentication logic (Login, Signup, User Model)
│   └── chat/           # Core messaging, search, and media features
│       ├── domain/     # Business logic & Data Models
│       ├── data/       # Repositories & API sources
│       └── presentation/# UI components, Screens, and Controllers
└── main.dart           # Application entry point
```

---

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK installed
- Firebase CLI installed
- A Cloudinary account for media storage

### Installation Steps

1.  **Clone the Repository**:
    ```bash
    git clone <repository-url>
    cd chatapp
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**:
    - Create a new project in the [Firebase Console](https://console.firebase.google.com).
    - Enable **Email/Password** Authentication and **Cloud Firestore**.
    - Run `flutterfire configure` to generate `lib/firebase_options.dart`.

4.  **Cloudinary Setup**:
    - Add your Cloudinary credentials in `lib/core/constants/cloudinary_config.dart`.

5.  **Deploy Security Rules**:
    - Copy the contents of `firestore.rules` to your Firebase Console under the Rules tab.

6.  **Run the App**:
    ```bash
    flutter run
    ```

---

## 🛡 Security & Performance

- **Firestore Rules**: Security is enforced at the database level. Users can only delete their own messages for everyone, and read access is restricted to authenticated conversation participants.
- **Bandwidth Optimization**: 
    - Images are compressed to JPEG format with a maximum width of 1080px.
    - Video uploads are limited to 30 seconds to maintain high performance.
- **Offline Readiness**: Messaging queues ensure messages are delivered as soon as connectivity is restored.

---

## 📱 Troubleshooting

### iOS Code Signing Issues
If you encounter `MIInstallerErrorDomain Code: 13` when deploying to a physical device:
1. Run `flutter clean`.
2. Delete `ios/Pods` and `ios/Podfile.lock`.
3. Run `flutter pub get` and `cd ios && pod install`.
4. Open the project in Xcode and ensure your **Development Team** is correctly set for the Runner target.

---

## 📄 License
This project is for demonstration purposes. Refer to the project's license file for more details.
