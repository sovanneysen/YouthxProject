# YouthX — Agent Guide

This file tells AI agents (and humans) how this Flutter codebase is structured and
how to work with it safely. Read it before making changes.

## What this app is

**YouthX** — "Community, Messenger & Stories", a Flutter implementation of a
social app built with **GetX** and a strict **module (controllers / views /
binding)** architecture. It is a demo/offline build: everything runs against
in-memory `Mock*Repository` classes and an in-memory realtime bus, so the app
works with **no backend**.

## Tech stack

| Layer | Choice |
|---|---|
| Language / framework | Dart / Flutter (SDK `>=3.3.0 <4.0.0`) |
| State mgmt, DI, routing | `get` (GetX) — GetMaterialApp, GetxController, Bindings, GetPage |
| Networking | `http` (REST via `ApiProvider`), `web_socket_channel` (realtime) |
| Media | `image_picker`, `record` / `audioplayers` (voice), `path_provider` |
| Utils | `intl`, `timeago`, `uuid` |

## Folder structure (lib/)

```
lib/
  main.dart                       # entry: connects socket, runs GetMaterialApp (light only)
  core/
    network/
      app_config.dart             # AppConfig: URLs + useMockBackend + currentUserId
      socket_service.dart         # RealtimeSocketService (singleton) — realtime bus
    theme/
      app_colors.dart             # AppColors (light palette remapped from Figma dark)
      app_text_styles.dart        # AppTextStyles
      app_theme.dart              # AppTheme (light + dark both == light; ThemeMode.light)
    widgets/
      primary_button.dart         # PrimaryButton
      selectable_chip.dart        # SelectableChip
      user_avatar.dart            # UserAvatar
  data/
    models/                       # PostModel, CommentModel, UserModel, MessageModel,
                                  #   ThreadModel, StoryModel, StoryTextOverlay, FeelingModel
    providers/
      api_provider.dart           # ApiProvider: thin http GET/POST/PUT/DELETE wrapper
    repositories/
      community_repository.dart   # CommunityRepository (abstract) + MockCommunityRepository
      chat_repository.dart        # ChatRepository (abstract) + MockChatRepository
  modules/
    community/                    # bindings/ controllers/ views/ (+ views/widgets/)
    messenger/                    # bindings/ controllers/ views/ (+ views/widgets/)
    profile/                      # bindings/ controllers/ views/
    story/                        # bindings/ controllers/ views/
  routes/
    app_routes.dart               # Route name constants
    app_pages.dart                # GetPage list (route -> view + binding)
```

## Architecture rules (follow these)

1. **GetX only** — no Provider/Riverpod/BLoC. Controllers extend `GetxController`,
   state is `Rx*` (`.obs`), views rebuild with `Obx` / `GetX`.
2. **Module pattern** — every feature lives in `modules/<name>/` with exactly
   `binding/`, `controllers/`, `views/`. Shared UI goes in `core/widgets/`,
   shared theme in `core/theme/`.
3. **Bindings do DI** — each module has a `Bindings` class that `Get.put` /
   `Get.lazyPut`s repositories (often `permanent: true` or `fenix: true`) and
   constructs controllers. Controllers take their dependencies via constructor
   (never call `Get.find` inside the controller for its own deps).
    - `CommunityBinding` registers `MockCommunityRepository` once with
      `permanent: true` so feed + create + comments + stories share one instance.
    - `MessengerBinding` uses `Get.lazyPut(fenix: true)`.
    - `ProfileBinding` falls back to putting its own `MockCommunityRepository`
      if none is registered (profile is reachable from messenger, where the
      community binding never ran), so the story ring always has data.
   - Controllers that need per-screen data read `Get.arguments` **in the
     binding** (see `ProfileBinding`, which defaults to the current user when no
     `UserModel` argument is passed). Chat thread is a controller argument
     (`ChatController(repository:..., thread:...)`) constructed in the view when
     opening `chat_thread_view.dart` — not via a named route binding.
4. **Views are dumb** — no logic beyond calling controller methods and
   rendering. Keep network/media code in controllers.
5. **Data access is behind repository interfaces** — UI/controllers depend on
   `CommunityRepository` / `ChatRepository` (abstract), never on the `Mock*`
   classes directly (except where bindings must construct them). Going live =
   add real implementations and swap them in the bindings; controllers/views
   don't change.

## Data flow

- View -> Controller (method call, e.g. `communityController.loadFeed()`)
- Controller -> Repository interface -> `Mock*Repository` (in-memory lists)
  or (future) real repo -> `ApiProvider` -> backend
- Realtime events flow through `RealtimeSocketService` (see below), and
  controllers subscribe with `.listen` in `onInit` and cancel in `onClose`.

## Realtime design (important)

`RealtimeSocketService` is a **singleton** (`RealtimeSocketService.instance`).
Every event is a JSON frame:

```json
{ "channel": "post:123:comments", "type": "comment", "data": { ... } }
```

- Channels: `post:<postId>:comments` (helper `commentsChannel()` in
  community_repository.dart) and `chat:<threadId>` (helper `chatChannel()` in
  chat_repository.dart).
- Subscribe via `RealtimeSocketService.instance.on(channel)` and filter on
  `event['type']`; payload is in `event['data']`.
- When `AppConfig.useMockBackend = true` (the default), a real socket is never
  opened — a broadcast `StreamController` (`_localBus`) is used instead.
- `emit()` always fans events back into the local bus **and** the real socket,
  so the sender's own UI updates instantly (optimistic + realtime).
- Controllers that listen must call `RealtimeSocketService.instance.connect()`
  in `onInit` and cancel subscriptions in `onClose`.

## Where to look for common changes

| Task | Files |
|---|---|
| Feed post cards, stories row, create/edit post, comments sheet (threaded replies) | `modules/community/` (controllers: `community_controller`, `comments_controller`, `create_post_controller`; views incl. `views/widgets/post_card.dart`, `views/widgets/stories_row.dart`, `views/widgets/comment_tile.dart`) |
| Thread list, chat (text/image/voice), voice bubble | `modules/messenger/` (`messenger_controller`, `chat_controller`, `views/widgets/voice_message_bubble.dart`) |
| Story editor (bg colors, drag text, text-only) + Instagram-style viewer (5s auto-advance, tap zones, long-press pause) | `modules/story/` (`story_editor_controller`, `story_editor_view`, `story_viewer_view`) |
| Profile screen (story ring → viewer) | `modules/profile/` |
| Theme / colors / text styles | `core/theme/` |
| Realtime behavior / socket framing | `core/network/socket_service.dart` |
| Mock data / seed content | `data/repositories/*_repository.dart` (`_seed()` methods) |
| Backend URLs / mock flag / current user | `core/network/app_config.dart` |
| Routes | `routes/app_routes.dart` + `routes/app_pages.dart` |

## Conventions & gotchas

- **Light mode only**: `ThemeMode.light` and both `theme`/`darkTheme` point at
  `AppTheme.light` (`main.dart`). Colors come from `AppColors`; don't introduce
  hard-coded dark-palette colors.
- **Code style** (enforced by `analysis_options.yaml`): `prefer_const_constructors`,
  `prefer_single_quotes`, plus flutter_lints. Single quotes everywhere; use
  `const` where possible.
- **No comments unless meaningful** — the existing code has explanatory
  comments for non-obvious things (e.g. why `permanent: true`, why
  `posts.refresh()`). Match that spirit; don't comment the obvious.
- **Ownership rule**: only a post's owner (`PostModel.isOwner(currentUserId)`)
  sees Edit/Delete. `AppConfig.currentUserId = 'me'` is the hardcoded current
  user; the mock `UserModel` with `id: 'me'` / name 'You' is "you".
- **One `CommentModel`** — defined in `data/models/post_model.dart` with a
  nullable `parentId` + `isReply` getter; replies stream over the same
  `post:<id>:comments` channel as top-level comments (the old
  `comment_model.dart` / `comment_repository.dart` / `post_detail_*` scaffolding
  was deleted — dead code referencing files that don't exist). All comment
  state lives in `CommunityRepository` + `CommentsController`.
- **Story expiry** is enforced in `MockCommunityRepository.fetchStories()` by
  filtering `!s.isExpired` (24h) — no cleanup job needed.
- **`posts.refresh()`** pattern: repos mutate `PostModel` fields in place (like
  `toggleLike`), so controllers call `.refresh()` on the `RxList` to trigger
  Obx rebuilds (object identity doesn't change).
- **Platform folders** (`android/`, `ios/`, `web/`, `windows/`, `android_old/`)
  contain hand-written config only (manifests with permissions, Info.plist
  strings). `android_old/` is legacy/duplicate — prefer `android/`. Platform
  boilerplate is regenerated with `flutter create .` (see README).
- **Images** are referenced by **local file paths** until posted; no upload
  persistence yet.

## Commands

```bash
flutter pub get          # install deps
flutter run              # run the app (offline by default, no backend needed)
flutter analyze          # lint + static analysis (run after changes)
flutter test             # tests (test/widget_test.dart — boots to Community feed)
flutter test --coverage  # coverage (optional)
flutter create . --org com.youthx --project-name youthx_app   # regen platform scaffolding if missing
```

## Going live (production next steps, from README)

1. Set `AppConfig.useMockBackend = false` and point `socketUrl` / `apiBaseUrl`
   at a real backend.
2. Add real `CommunityRepository` / `ChatRepository` implementations that use
   `ApiProvider`, and swap them into the bindings.
3. Add auth (currently single hardcoded user), persistence, and feed pagination.
