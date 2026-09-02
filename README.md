# Campus Canteen

Flutter and Node.js authentication foundations for a campus canteen application. Students and canteen staff can create an account and sign in to access their role-specific experience.

## Included in the Auth module

- Flutter login and registration screens with client-side form validation, password visibility controls, loading state, and accessible error feedback.
- A home menu screen with category filtering, item selection, cart quantities, and order-total preview.
- Role selection for **Student** and **Canteen staff** registrations.
- MongoDB `User` schema with name, unique email, hashed password, and role (`student`, `staff`, or `admin`).
- `POST /api/auth/register` and `POST /api/auth/login` endpoints using bcrypt password hashing and seven-day JWTs.
- Flutter `AuthService` which calls the API. The default Android-emulator URL is `http://10.0.2.2:3000`; override it with `--dart-define=API_BASE_URL=http://your-host:3000` for another target.

## Project structure

```text
lib/
  main.dart              Flutter login and signup screens
  home_screen.dart       Canteen menu, item selection, and cart
  auth_service.dart      Auth API client and response models
server/
  models/User.js         MongoDB user schema
  routes/auth.js         Register and login routes
  server.js              Express application entry point
  .env.example           Required server configuration template
test/widget_test.dart    Flutter auth screen tests
```

## Run the API

```bash
cd server
cp .env.example .env
# Set MONGODB_URI and use a long, unique JWT_SECRET in .env
npm install
npm start
```

## Run the Flutter app

```bash
flutter pub get
flutter run
```

For Flutter web, iOS Simulator, or a physical device, pass the host reachable from that device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:3000
```

## Test

```bash
flutter test
```
