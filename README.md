# NOTI

**A Flutter-based Android application for reliable in-app alerts and notifications.**

NOTI aims to help users manage important alerts through a notification system designed with reliability, duplicate prevention, and error handling in mind.

## Features

* **Alert Management:** Manage alerts through a repository-based architecture.
* **Notification Handling:** Organize and deliver app notifications.
* **Retry Mechanism:** Improve alert reliability by retrying eligible operations after failures.
* **Alert History:** Maintain alert-related records where supported by the configured repository.
* **Duplicate Prevention:** Reduce duplicate alert processing and repeated notifications.
* **Firebase Integration:** Firebase Cloud Messaging and Firebase-backed alert functionality.
* **Terminal Commands:** Support for the commands implemented in the application.
* **Testing:** Flutter tests for validating application behavior.

*Features may depend on the active repository implementation and Firebase configuration.*

## Tech Stack

* [Flutter](https://flutter.dev/)
* [Dart](https://dart.dev/)
* [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
* Firebase services used by the project

## Getting Started

### Prerequisites

Install the following tools:

* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Android Studio](https://developer.android.com/studio) or another configured Android development environment
* Android SDK and platform tools
* A Firebase project if you want to use Firebase-backed functionality

### Installation

Clone the repository and switch to the Flutter application branch:

```bash
git clone --branch flutter-app https://github.com/ilkedenizz/Noti.git
cd Noti
```

Install dependencies:

```bash
flutter pub get
```

Check the development environment:

```bash
flutter doctor
```

Run the application on a connected Android device or emulator:

```bash
flutter run
```

## Firebase Configuration

Some functionality may require Firebase configuration.

1. Create or select a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Configure the Android application using the package ID defined in the project.
3. Follow the official Firebase setup instructions for Flutter.
4. Configure the Firebase services required by the application.

See the [Firebase Flutter setup guide](https://firebase.google.com/docs/flutter/setup) and the [FCM Flutter guide](https://firebase.google.com/docs/cloud-messaging/flutter/client).

**Security:** Do not commit service account private keys, passwords, access tokens, or other secrets. Firebase client configuration is not a substitute for server-side access controls.

## Testing

Run the Flutter test suite:

```bash
flutter test
```

Analyze the project for potential issues:

```bash
flutter analyze
```

## Building the APK

Build a debug APK for local testing:

```bash
flutter build apk --debug
```

Build a release APK when the release configuration is ready:

```bash
flutter build apk --release
```

The generated APK is typically available at:

```text
build/app/outputs/flutter-apk/
```

Release builds may require additional signing and production configuration.

## Architecture and Reliability

NOTI uses an alert repository architecture with mock and Firebase-backed implementations. Its alert-handling code includes retry and duplicate-prevention mechanisms intended to improve reliability.

Actual delivery behavior depends on the selected backend, device notification permissions, Android background-execution restrictions, and Firebase configuration. No notification system can guarantee delivery in every device or network condition.

## Contributing

Contributions and suggestions are welcome.

1. Fork the repository or create a feature branch.
2. Make focused changes.
3. Run `flutter test` and `flutter analyze`.
4. Submit a pull request describing the changes.

## License

No license has been specified yet. Until a license is added to the repository, reuse and redistribution permissions should not be assumed.
