qu_community

Simple Flutter app with 4 tabs (Bus, Classes, Community, Profile) using Material 3 and a maroon theme.

Prerequisites
- Flutter 3.x (stable)
- Android SDK + Platform Tools (adb)
- An Android emulator (AVD)

First-time setup (Windows / PowerShell)
1) Verify Flutter:
```
flutter --version
```
2) Get packages:
```
flutter pub get
```
3) Start your emulator (example):
```
flutter emulators --launch Pixel_9_Pro
```

If you prefer a specific already-running emulator:
- Your preferred command: `flutter run -d emulator-5554`

Run the app
From this folder:
```
flutter run -d emulator-5554
```
If you don’t know the device id:
```
flutter devices
flutter run -d android
```

Common issues
- Missing NDK during build
  - Open Android Studio > SDK Manager > SDK Tools > check "NDK (Side by side)" and install (app was built with NDK 27.x).
  - Or via sdkmanager:
```
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --install "ndk;27.0.12077973" --sdk_root="$env:LOCALAPPDATA\Android\Sdk"
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses --sdk_root="$env:LOCALAPPDATA\Android\Sdk" < NUL
```
- Emulator offline/unauthorized
```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" kill-server
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" start-server
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```
Restart the emulator if it remains offline.

Project structure
- lib/main.dart – MaterialApp + bottom navigation
- lib/pages/*.dart – 4 simple stateless pages with centered text

Notes
- Light mode only
- No backend/state management
- Material 3 enabled

# qu_community

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
