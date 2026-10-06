# Solado Certo App

Flutter app for Solado Certo, a mobile marketplace where users buy and advertise podiatric products, with a podological profile for each user. It talks to the [Solado Certo backend](../../backend/README.md) over its REST API. This is an academic prototype (TCC).

## Requirements

- Flutter (stable channel; developed with Flutter 3.44, Dart SDK `^3.8.1` per `pubspec.yaml`)
- Chrome, for the quickest way to run it; or an Android emulator / device
- The backend running locally (see its README; it serves on `http://localhost:3000`)

## Setup

1. Start the backend first (`make up` in `codebase/backend`) and check `http://localhost:3000/health`.

2. Copy the example environment file:

   ```sh
   cp .env.example .env
   ```

   `.env` holds a single variable, `API_BASE_URL`, the backend address:

   | Where the app runs | `API_BASE_URL` |
   |---|---|
   | Chrome / desktop on the same machine | `http://localhost:3000` (the default in `.env.example`) |
   | Android emulator | `http://10.0.2.2:3000` (the emulator's alias for the host machine) |
   | Physical device | `http://<your computer's LAN IP>:3000` |

3. Install dependencies and run:

   ```sh
   flutter pub get
   flutter run -d chrome --dart-define-from-file=.env
   ```

   `--dart-define-from-file=.env` is required. `API_BASE_URL` is read at compile time, and without the flag the app falls back to a placeholder URL and every request fails. On Windows, `make run-chrome` does the same after cleaning `build/`.

After changing `.env`, stop the app and run it again; hot reload does not pick up compile-time variables.

## Project structure

```
lib/
  main.dart              entry point
  app/
    app.dart             MaterialApp, theme and named routes
    bootstrap.dart       dependency registration (get_it)
    theme/               colors and theme
  core/
    config/envs.dart     API_BASE_URL from --dart-define
    network/             Dio API client: attaches the access token, refreshes it on 401 and retries once
    storage/             token keys for flutter_secure_storage
    presentation/        shared widgets (buttons, text fields)
  features/
    auth/                sign in, sign up, sign out
    onboarding/          first-access steps
    profile/             user profile
    catalog/             ads (in progress)
    home/, splash/
      <feature>/         domain/ (entities, repositories, use cases) and
                         presentation/ (bloc, pages, components, routes);
                         catalog also has data/ (API data sources, models)
```

- **State management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) (blocs in auth, onboarding and catalog).
- **Dependency injection:** [get_it](https://pub.dev/packages/get_it), configured in `app/bootstrap.dart`.
- **Routing:** Flutter's `Navigator` with named routes; each feature exposes its own `routes` map, merged in `app/app.dart`.
- **HTTP:** [Dio](https://pub.dev/packages/dio). Tokens are stored with [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage).

## Checks

```sh
flutter analyze
```

There are no automated tests yet.
