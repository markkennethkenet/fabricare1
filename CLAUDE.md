
# Claude Code Instructions - Fabricare

Follow AGENTS.md as the primary repository guidance.

Before making significant changes:

1. Read knowledge.md.
2. Check the current Git branch and working-tree status.
3. Inspect relevant Flutter, Dart, Python, and database files.
4. Identify the existing implementation before proposing changes.
5. Explain important assumptions and the implementation plan.

## Development Guidelines

- Preserve the existing Fabricare application.
- Follow established architecture and coding conventions.
- Reuse existing screens, widgets, services, and utilities.
- Keep changes focused and reviewable.
- Maintain compatibility with existing API contracts.
- Handle validation, errors, and network failures appropriately.
- Protect user data and application credentials.
- Avoid unnecessary dependencies and unrelated refactoring.

## Testing and Review

- Inspect available Flutter and Python tests.
- Test affected behavior and relevant failure cases.
- Run appropriate analysis and tests when possible.
- Review the diff before finishing.
- Report failures honestly and identify untested behavior.

## Safety

Never discard unrelated changes, expose secrets,
perform destructive database operations, or deploy changes
without the required authorization.

## Completion Report

Summarize changed files, technical decisions, tests performed,
actual results, and outstanding issues.
