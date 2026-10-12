
# Fabricare Capstone Project Knowledge Base

## 1. Project Overview

Project Name: Fabricare

Project Type: Mobile Application

Frontend Framework: Flutter
Backend Language: Python
Development Environment: Visual Studio Code
Version Control: Git

Description:
Fabricare is a capstone project that includes a Flutter
mobile application and Python backend components.

Update this description to reflect the actual purpose
and functionality of the system.

## 2. Project Objectives

- Document the main purpose of the Fabricare application.
- Maintain a clear description of its existing architecture.
- Support consistent development and maintenance.
- Guide AI coding assistants when modifying the project.

## 3. Technology Stack

### Frontend
- Flutter
- Dart

### Backend
- Python
- Existing API implementation in fabricare_api.py

### Database
- Existing database-related files:
  - database.py
  - db_config.py

Document the actual database engine and schema after
verifying the implementation.

### Configuration
- .env
- .env.example
- analysis_options.yaml
- pubspec.yaml

Never place real credentials or API secrets in this file.

## 4. Important Project Files

- AGENTS.md: General AI coding instructions.
- CLAUDE.md: Instructions for Claude Code.
- knowledge.md: Project knowledge and architecture.
- auth_routes.py: Authentication-related routes.
- database.py: Database-related functionality.
- db_config.py: Database configuration.
- fabricare_api.py: API-related functionality.
- profile_screen.dart: Profile screen implementation.
- health_score_calculator.dart: Health score calculation.
- skills/: Project-specific AI skill instructions.

Verify the responsibility of each file before documenting
detailed behavior.

## 5. Custom AI Skills

### Fabricare Development
Location: skills/fabricare-development/skill.md

Purpose:
Document and guide development tasks related to the
Fabricare application.

### Fabricare UI
Location: skills/fabricare-ui/skill.md

Purpose:
Document and guide user interface development tasks.

Review the actual skill files and update these descriptions
to match their instructions.

## 6. Application Architecture

Document the actual flow between:

- Flutter mobile interface
- API communication
- Python backend
- Database operations
- Authentication
- Business logic

Confirm the actual architecture by inspecting the code.

## 7. Security and Privacy

- Keep credentials out of source code and documentation.
- Use environment variables for configuration where appropriate.
- Validate untrusted input.
- Protect authentication credentials and user data.
- Avoid exposing sensitive information in application logs.
- Never commit a populated .env file containing secrets.

## 8. Error Handling

- Handle API failures appropriately.
- Provide useful error messages to users.
- Handle invalid input.
- Handle database errors safely.
- Avoid exposing internal exceptions or credentials.

## 9. Testing

- Inspect existing Flutter tests.
- Test important screens and navigation.
- Test API responses and error handling.
- Test database operations where applicable.
- Test authentication and authorization where applicable.
- Test health score calculations against verified requirements.

Document actual test commands and results.

## 10. Development Rules

- Inspect existing code before making changes.
- Preserve working features.
- Follow existing coding conventions.
- Avoid unrelated refactoring.
- Reuse existing components and services.
- Update documentation when architecture changes.
- Review Git changes before committing.

## 11. Known Issues

Record confirmed bugs, incomplete features, and limitations.

Do not list assumptions as confirmed problems.

## 12. Future Improvements

Document proposed enhancements separately from completed features.

## 13. Important Decisions

Record important technical decisions and the reasons
behind them.
