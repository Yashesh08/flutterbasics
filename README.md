# Course System CRUD (Flutter)

A small beginner-friendly Flutter app that demonstrates CRUD operations for a course system.

## What this app teaches

- **Create** a new course with a title, teacher, and duration.
- **Read** all courses in a simple list.
- **Update** an existing course from the edit button.
- **Delete** a course from the delete button.
- Basic Flutter concepts: `MaterialApp`, `StatefulWidget`, `setState`, `ListView.builder`, forms, validation, and dialogs.

## Project structure

```text
lib/main.dart        Main Flutter application and CRUD logic
test/widget_test.dart Basic widget test for the starting screen
pubspec.yaml         Flutter dependencies and project metadata
```

## Run the project

```bash
flutter pub get
flutter run
```

## Run tests

```bash
flutter test
```

## Beginner notes

The app stores courses in an in-memory `List<Course>`, so data resets when the app restarts. This keeps the code easy to understand before adding databases or APIs.
