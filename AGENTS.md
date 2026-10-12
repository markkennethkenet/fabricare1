# Fabricare Project - AI Agent Instructions

## Project Context

Fabricare is an existing Flutter mobile application with
Python backend components and database-related functionality.

Read knowledge.md before making significant changes.
Inspect the actual source code before assuming how a feature works.

## Preserve Existing Code

- Do not replace the application with a new template.
- Preserve unrelated developer changes.
- Follow the current Git branch.
- Avoid destructive commands and unnecessary refactoring.
- Do not delete files without authorization.

## Flutter and Dart

- Follow existing Dart conventions and analysis settings.
- Reuse existing widgets and UI components.
- Keep screens consistent with the current design.
- Handle loading, success, empty, and error states.
- Consider navigation, accessibility, and small screens.
- Run Flutter checks when appropriate.

## Python Backend

- Inspect existing route handlers, services, and database code.
- Follow the existing API contracts.
- Validate incoming data.
- Handle errors without exposing sensitive details.
- Do not invent endpoints or database fields.

## Database

- Inspect the existing schema before changing queries.
- Preserve existing data and relationships.
- Avoid destructive schema changes without authorization.
- Use parameterized queries where supported.
- Keep database credentials out of source code.

## Security

- Never commit populated environment files or secrets.
- Use .env.example for safe configuration examples.
- Protect authentication information and personal data.
- Avoid logging passwords, tokens, or sensitive records.
- Validate authorization on the trusted backend.

## Testing

- Inspect the available Flutter and Python test suites.
- Test changed functionality and relevant edge cases.
- Run checks appropriate to the change.
- Report actual results; do not claim tests passed unless run.

## Git

- Check Git status before editing.
- Review the diff before committing.
- Do not discard user changes.
- Do not force-push or rewrite history without approval.
- Keep changes focused on the requested task.

## Final Response

Report the files changed, implementation details,
tests performed, test results, and remaining limitations.