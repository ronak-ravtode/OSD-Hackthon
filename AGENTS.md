# SnapSearch — AI Agent Constraints

## Global Rules
1. **Strict Dart Typing**: Always declare explicit types. Never use `dynamic`. Use `var` only when the type is obvious from the right-hand side.
2. **No Bare Catches**: Every `catch` must specify `on ExceptionType`. Never use a bare `catch (e)`.
3. **Response Limit**: Never write more than 50 lines of code in a single response. Break work into smaller, composable files.
4. **Package Approval**: Never add a package to `pubspec.yaml` without explicit user approval.
5. **Architecture First**: Always read `ARCHITECTURE.md` before writing any code. Follow the defined folder structure and data flow.
6. **Verify Before Claiming Done**: Run `flutter analyze` and `flutter test` before declaring any task complete.
7. **Ask, Don't Guess**: If implementation is unclear, STOP and ask the user. Do not invent behavior.

## Folder Discipline
- Feature code lives under `lib/features/<feature_name>/`.
- Shared utilities go in `lib/core/`.
- Database logic goes in `lib/data/db/`.
- Data models go in `lib/data/models/`.
- Never place business logic inside UI widgets.

## Code Quality
- Prefer `const` constructors everywhere possible.
- Use single quotes for strings.
- Prefer `final` over `var` for local variables that are not reassigned.
