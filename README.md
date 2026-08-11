# YouthX — Community, Messenger & Stories

A Flutter implementation of the Figma "Community" design, built with a
GetX `controllers / views / binding` module architecture, in **light mode**.

## Features

### Community feed
- Header, live search, stories row, filter chips (All / Goals / Finance / Community)
- Post card: avatar, name, timestamp, feeling, tags, image, like + comment counts
- **Only the post owner** sees the Edit/Delete menu (`PostModel.isOwner`) — other
  users' posts are read-only
- **Create / Edit post**: caption, photo upload (`image_picker`), a feelings
  picker (😄 Happy, 🙏 Grateful, …) and a tags picker (suggested chips + free-form
  custom tag), all shown on the post card and usable as feed filters
- **Comments** open in a bottom sheet and update **in real time over a
  WebSocket** — no pull-to-refresh needed. Posting a comment also triggers a
  simulated peer reply after ~2s so you can see the live behaviour immediately
  in the mock backend
- **Stories row** with "Add Story" entry point

### Messenger
- Thread list with search-as-you-type
- Tapping a thread opens the chat; **tapping the avatar routes straight to
  that user's profile**, both from the thread list and from inside a chat
- Chat thread supports **text**, **image upload**, and **voice messages**
  (record with `record`, playback with a waveform-style progress bar via
  `audioplayers`)
- New messages stream in over the same realtime bus used by comments — open
  a thread on two devices/tabs and messages appear instantly

### Stories (Instagram-style editor)
- Pick an image from the gallery or camera
- Add any number of text layers, **drag them anywhere** on the canvas,
  double-tap to edit the text, and pick a color per layer
- "Share to Story" posts it to the stories row

### Design
- Everything is **light mode only** (`ThemeMode.light`, light+dark theme both
  point at `AppTheme.light`) — colors were remapped from the Figma dark
  palette to a light surface/background system in `core/theme/app_colors.dart`

## Architecture

```
lib/
  core/
    network/     # AppConfig (backend URLs), RealtimeSocketService (WebSocket)
    theme/       # AppColors, AppTextStyles, AppTheme (light only)
    widgets/     # UserAvatar, SelectableChip, PrimaryButton
  data/
    models/      # PostModel, CommentModel, UserModel, MessageModel, StoryModel...
    providers/   # ApiProvider (thin REST wrapper for a real backend)
    repositories/# CommunityRepository / ChatRepository (+ Mock implementations)
  modules/
    community/   controllers/ views/ binding/
    messenger/   controllers/ views/ binding/
    story/       controllers/ views/ binding/
    profile/     controllers/ views/ binding/
  routes/        # app_routes.dart, app_pages.dart
  main.dart
```

State management, dependency injection and routing all use **GetX**
(`get` package), matching the `controllers/views/binding` folders you asked
for.

## Realtime design

`RealtimeSocketService` (`core/network/socket_service.dart`) wraps a real
`WebSocketChannel`. Every event is framed as:

```json
{ "channel": "post:123:comments", "type": "comment", "data": { ... } }
```

so one physical socket connection can carry both post-comment channels
(`post:<id>:comments`) and chat channels (`chat:<threadId>`), the same way a
production backend typically multiplexes rooms over a single socket.

By default `AppConfig.useMockBackend = true`, so the app runs fully offline:
events are broadcast through an in-memory `StreamController` instead of a
real socket, which is why the app works immediately with no server. To go
live:

1. Set `AppConfig.useMockBackend = false`
2. Point `AppConfig.socketUrl` / `AppConfig.apiBaseUrl` at your backend
3. Replace `MockCommunityRepository` / `MockChatRepository` with real
   implementations of `CommunityRepository` / `ChatRepository` that call
   `ApiProvider` — the controllers and UI don't need to change since they're
   written against the repository interfaces

## Getting started

This code was authored outside of a Flutter SDK environment, so the
`android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` platform folders
only contain the hand-written config this app needs (Android manifest
permissions, iOS `Info.plist` usage strings). Generate the rest of the
platform boilerplate once with Flutter installed:

```bash
cd youthx_app
flutter create . --org com.youthx --project-name youthx_app
```

This regenerates the standard Gradle/Xcode/CMake scaffolding without
touching your `lib/`, `pubspec.yaml`, or the manifest files already in this
repo (answer "no"/keep-mine if it asks about overwriting `AndroidManifest.xml`
or `Info.plist`, since the ones here already have the permissions this app
needs).

Then:

```bash
flutter pub get
flutter run
```

### Permissions already wired in
- **Android** (`android/app/src/main/AndroidManifest.xml`): `INTERNET`,
  `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`, `CAMERA`, `RECORD_AUDIO`
- **iOS** (`ios/Runner/Info.plist`): `NSPhotoLibraryUsageDescription`,
  `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`

## Key packages

| Package | Use |
|---|---|
| `get` | State management, DI, routing (bindings) |
| `web_socket_channel` | Realtime comments & chat |
| `image_picker` | Post/story images, chat image upload |
| `record` / `audioplayers` | Voice message record + playback |
| `path_provider` | Temp storage for recorded audio |
| `http` | REST calls once you connect a real backend |
| `timeago` | "2m ago" style timestamps |
| `uuid` | Client-side ID generation for mock data |

## Notes / next steps for a production build

- Swap the two `Mock*Repository` classes for real API-backed implementations
- Add auth (the app currently assumes a single hardcoded `AppConfig.currentUserId = 'me'`)
- Persist drafts/uploads before sending (currently images are referenced by
  local file path until posted)
- Add pagination to the feed and message history
