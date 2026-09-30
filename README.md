# YOUTHX

YOUTHX is a Flutter mobile application built for the **ACLEDA GenZ mobile app competition**.

It is a social-and-growth platform for Gen Z users: personal growth goals and habits, a community feed with posts, comments and likes, a finance tracker for expenses and saving goals, and profile management. The app is backed by a Java Spring Boot REST API with a PostgreSQL database.

## Tech Stack

| Technology | Where |
|---|---|
| Flutter 3.44.8 (stable) | UI toolkit |
| Dart 3.12.2 | language (`pubspec.yaml` → `sdk: ^3.12.2`) |
| GetX 4.6.6 | state management, dependency injection, routing |
| Dio 5.7.0 + http 1.2.1 | REST networking |
| SharedPreferences 2.5.3 | local persistence (profile data) |
| flutter_secure_storage 9.2.4 | secure JWT storage |
| image_picker 1.1.2 | picking images for posts, stories, avatar |
| cached_network_image 3.4.1 | remote image loading |
| google_fonts 6.2.1 | typography |
| web_socket_channel 3.0.3 | realtime channel |
| crypto 3.0.6, encrypt 5.0.3 | client-side crypto |
| intl, uuid, timeago, path_provider | utilities |
| **Java 21 + Spring Boot 3.5.16** | backend REST API |
| **PostgreSQL** | backend database |

## Main Modules

- **Auth** — register, login, session restore, logout
- **Home** — dashboard with goal, finance and social summaries
- **Community** — post feed, post detail, comments, likes, photo upload
- **Growth** — goals, tasks/steps, habits, progress tracking
- **Finance** — expenses, categories, transaction history, saving goals
- **Profile / Settings** — profile view and edit, followers/following, settings, privacy, notifications, help & support
- **Story** — story creation and viewer
- **Messenger** — chat threads

## Architecture

```
Figma
  → Flutter UI (views / widgets)
    → GetX controllers
      → repositories (interface + REST implementation)
        → REST API (Dio / ApiProvider)
          → Spring Boot
            → PostgreSQL
```

- **Views** render state and forward intent to controllers. They hold no networking logic.
- **Controllers** are registered through GetX `Bindings` and expose reactive state via `Rx`.
- **Repositories** are the single data-access layer. Each module defines an abstract repository and a `Rest*Repository` implementation bound in that module's binding file, so the app depends on the interface rather than the transport.
- **`ApiProvider`** wraps Dio and attaches the JWT from secure storage to outgoing requests.
- **Local persistence**: features with no backend support use `SharedPreferences` via `LocalProfileStore` (profile data, goal steps). The messenger module uses a `MockChatRepository` and the realtime layer falls back to an in-memory bus when `AppConfig.useMockBackend` is `true`.

## Requirements

Verified from the current repository:

| Requirement | Value |
|---|---|
| Flutter | **3.44.8** (stable) — verified with `flutter --version` |
| Dart | **3.12.2** (pubspec constraint `^3.12.2`) |
| Android Gradle Plugin | Gradle wrapper **9.1.0** (`android/gradle/wrapper/gradle-wrapper.properties`) |
| Android compile/target/min SDK | inherited from Flutter defaults (`flutter.compileSdkVersion`, `flutter.targetSdkVersion`, `flutter.minSdkVersion`) |
| Android Java level | **Java 17** (`sourceCompatibility` / `targetCompatibility` / `jvmTarget` = `17` in `android/app/build.gradle.kts`) |
| Backend JDK | **Java 21** (`<java.version>21</java.version>` in backend `pom.xml`) |

Note the split: the Android build targets Java 17, while the backend requires Java 21. Installing JDK 21 satisfies both, since Gradle compiles the Android sources down to the 17 bytecode target.

## Project Structure

```
youthx_app/
├── lib/
│   ├── auth/              # auth controllers + views
│   ├── core/
│   │   ├── network/       # ApiProvider, ApiClient, AppConfig, token store, socket
│   │   ├── shell/         # bottom-nav shell
│   │   ├── storage/       # SharedPreferences-backed local stores
│   │   ├── theme/         # light/dark theme + theme controller
│   │   └── widgets/       # shared widgets
│   ├── data/
│   │   ├── models/        # DTOs
│   │   ├── providers/     # ApiProvider
│   │   └── repositories/  # repository interfaces + REST implementations
│   ├── modules/
│   │   ├── community/     # feed, posts, comments, likes
│   │   ├── finance/       # expenses, categories, saving goals
│   │   ├── growth_center/ # goals, steps, habits
│   │   ├── messenger/     # chat
│   │   ├── profile/       # profile, settings, privacy, help, notifications
│   │   └── story/         # stories
│   ├── routes/            # AppRoutes + AppPages (GetX pages)
│   └── main.dart
├── test/                  # 22 test files
├── android/  ios/  web/  linux/  macos/  windows/
├── pubspec.yaml
└── README.md
```

## Configuration

The API endpoint is supplied at build time via `--dart-define`:

```bash
--dart-define=API_BASE_URL=https://your-backend-host
```

Defaults live in `lib/core/network/app_config.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.youthx.app',
);

static const String socketUrl = String.fromEnvironment(
  'SOCKET_URL',
  defaultValue: 'wss://echo.websocket.events',
);
```

A second flag, `SOCKET_URL`, points the realtime channel at a backend. When `AppConfig.useMockBackend` is `true` (the current committed value), the app uses the in-memory realtime bus instead of opening a socket.

**Local Android testing.** `localhost` on an Android device refers to the device itself, not your development machine. Forward the device's port 8080 to your machine's backend:

```bash
adb reverse tcp:8080 tcp:8080
```

Then run with the loopback address:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

The Android manifest already sets `android:usesCleartextTraffic="true"`, which is what allows plain `http://` during local development.

**Release builds.** A release APK installed on a reviewer's phone cannot reach `localhost` or your LAN. Build release APKs with a publicly reachable HTTPS backend URL:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-public-backend-host
```

No credentials or secrets belong in `--dart-define`; the backend holds all secrets.

## Run

```bash
# 1. install dependencies
flutter pub get

# 2. run on a connected device or emulator
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

With a physical Android device connected over USB (developer mode + USB debugging enabled), and the backend running locally:

```bash
adb devices                 # confirm the device is listed
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

To target a specific device: `flutter run -d <device-id>`.

## Testing

```bash
flutter test --concurrency=1
flutter analyze --no-pub
```

The test suite uses `flutter_test` with fake repositories and mocked API providers, so it runs without a live backend. There are 22 test files covering auth, home, growth, finance, community, profile, and shell behaviour.

**Current status (30 Sep 2026).** `flutter analyze --no-pub` reports **0 errors, 1 warning, 40 infos**. The suite has 5 pre-existing failures in `test/goal_progress_test.dart` (`pumpAndSettle timed out`), caused by uncommitted work-in-progress on `goal_detail_view.dart` that is not part of the committed history. With that work reverted, the suite passes 237/237.

**Windows note.** In this environment an external process occasionally deletes Flutter's temp directory mid-run, producing `Failed to load ... flutter_test_listener.` or a missing `output.dill`. It is intermittent and did not reproduce during the latest verification. If it occurs, re-run, or point the temp dir somewhere stable for that command:

```powershell
$env:TEMP = "C:\Users\HUAWEI~1\AppData\Local\Temp\opencode"
$env:TMP  = "C:\Users\HUAWEI~1\AppData\Local\Temp\opencode"
flutter test --concurrency=1
```

## Release APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-public-backend-host
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

For split APKs per ABI, add `--split-per-abi`; each ABI then gets its own file under the same directory.

**Signing.** The current `android/app/build.gradle.kts` signs release builds with the **debug** key so that `flutter run --release` works out of the box. That is acceptable for competition submission but must be replaced with a real upload key before any Play Store release.

## Current MVP Behavior

Confirmed in the current code:

- **Auth** — email/password registration and login against the backend, JWT persisted in secure storage, session restored on launch, logout clears the session.
- **Growth** — goals with steps, habits, and manual percentage progress editing, persisted through the REST repository (steps additionally cached locally).
- **Finance** — expenses, expense categories, transaction list and detail, and saving goals with deposits, all REST-backed.
- **Community** — post feed, post creation with image upload, comments, and likes, REST-backed. Story create/view is available.
- **Profile** — profile view and edit persisted locally via `SharedPreferences`, including avatar selection through `image_picker`.
- **Messenger** — chat threads using `MockChatRepository`; local/demo only.
- **Followers / Following** — lists rendered from `MockSocialData`, not from the backend.
- **Notifications** — an explicit empty state; the backend exposes no notification resource.
- **Help & Support** — static FAQ and support content, informational only.

Local-only behaviour is used where the backend has no persistence support, and those screens say so in the UI rather than implying server sync.

## Known Limitations

Verified against the current source:

- **No real Followers/Following backend.** Both screens read from `MockSocialData`; no follow relationship exists server-side.
- **Profile image is local-only.** The avatar chosen in Edit Profile is stored via `SharedPreferences` on the device. There is no avatar upload endpoint in the backend.
- **No notification infrastructure.** The backend has no notification entity or feed, so the notification screen shows an honest empty state with no unread badge.
- **Password reset is not implemented.** There is no reset route, screen, endpoint, reset token, or email delivery on either side. The Sign In screen states this as plain text instead of offering a dead "Forgot password?" link.
- **Privacy settings are not enforced.** The toggles on the Privacy screen are UI-only; a `TODO` in the source records that they should load from a per-user `privacy_settings` table.
- **Logout is client-side only.** The backend `POST /api/auth/logout` endpoint is a stub that returns `200 OK` and performs no server-side token invalidation.
- **Support actions are informational.** Contact/Report entries in Help & Support do not open a mail client or file a ticket.
- **Messenger is not backend-connected.** Chat uses an in-memory mock repository; messages are not persisted or synced across devices.
- **Realtime is disabled by default.** `AppConfig.useMockBackend` is `true`, so the app uses an in-memory bus rather than the configured `SOCKET_URL`.
- **Email verification is a placeholder.** `lib/auth/views/start.dart` routes to an unfinished verification screen.
- **5 failing tests** in `test/goal_progress_test.dart` from uncommitted WIP (see Testing).

## Submission Checklist

- [ ] **APK** — `build/app/outputs/flutter-apk/app-release.apk`, built with a publicly reachable `API_BASE_URL`
- [ ] **Soft Code** — this repository (Flutter app + Spring Boot backend), committed history
- [ ] **Database Design** — backend schema, owned by Flyway migrations in `src/main/resources/db/migration`
- [ ] **Figma link** — add the design file URL here