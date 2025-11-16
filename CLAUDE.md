# CLAUDE.md - AI Assistant Guide

**Last Updated**: 2025-11-16
**Repository**: test
**Status**: Initial Setup / Pre-Development Phase

---

## Table of Contents

1. [Repository Overview](#repository-overview)
2. [Current State](#current-state)
3. [Directory Structure](#directory-structure)
4. [Development Workflow](#development-workflow)
5. [Git Conventions](#git-conventions)
6. [Code Organization Guidelines](#code-organization-guidelines)
7. [Testing Strategy](#testing-strategy)
8. [Documentation Standards](#documentation-standards)
9. [AI Assistant Best Practices](#ai-assistant-best-practices)
10. [Future Roadmap](#future-roadmap)

---

## Repository Overview

### Project Information

- **Repository Name**: test
- **Current Branch**: `claude/claude-md-mi1szrp24uypcwn9-01VSw6cvpN2Kd7QK5eQKAtnq`
- **Remote Origin**: `http://local_proxy@127.0.0.1:46788/git/kevchou/test`
- **Primary Language**: TBD (not yet determined)
- **Stage**: Pre-initialization

### Purpose

This repository is currently in its initial setup phase. The exact purpose and technology stack have not yet been defined.

---

## Current State

### What Exists

- **README.md**: Minimal documentation with project title
- **.git/**: Git repository initialized and configured
- **Branch Strategy**: Using feature branches with `claude/` prefix

### What's Missing

The repository currently lacks:

- Source code files
- Package manager configuration (package.json, requirements.txt, etc.)
- Build and deployment configuration
- Testing framework and tests
- CI/CD pipelines
- Linting and formatting configuration
- Documentation beyond basic README
- License file
- Contributing guidelines

---

## Directory Structure

### Current Structure

```
/home/user/test/
├── README.md
├── CLAUDE.md (this file)
└── .git/
```

### Recommended Structure (To Be Implemented)

Once the project type is determined, consider organizing as follows:

#### For Web Application (Node.js/TypeScript)
```
/
├── src/                 # Source code
│   ├── components/      # Reusable components
│   ├── services/        # Business logic
│   ├── utils/           # Utility functions
│   ├── types/           # TypeScript type definitions
│   └── index.ts         # Entry point
├── tests/               # Test files
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/                # Additional documentation
├── scripts/             # Build and automation scripts
├── .github/             # GitHub workflows and templates
│   └── workflows/
├── public/              # Static assets (if applicable)
├── package.json
├── tsconfig.json
├── .eslintrc.js
├── .prettierrc
├── README.md
├── CLAUDE.md
└── LICENSE
```

#### For Python Project
```
/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── core/
│       ├── utils/
│       └── main.py
├── tests/
│   ├── __init__.py
│   ├── test_unit/
│   └── test_integration/
├── docs/
├── scripts/
├── .github/
│   └── workflows/
├── pyproject.toml
├── requirements.txt
├── .flake8
├── .pylintrc
├── README.md
├── CLAUDE.md
└── LICENSE
```

---

## Development Workflow

### Branch Strategy

**Feature Branches**: All development work should be done on feature branches following the pattern:
- `claude/claude-md-<session-id>-<hash>`
- Example: `claude/claude-md-mi1szrp24uypcwn9-01VSw6cvpN2Kd7QK5eQKAtnq`

**Branch Rules**:
- NEVER push directly to main/master branches
- Always create feature branches from the latest main/master
- Branch names MUST start with `claude/` for AI assistant work
- Feature branches should be focused on specific tasks or features

### Pull Request Process

When ready to merge changes:

1. **Commit** all changes with descriptive commit messages
2. **Push** to the feature branch: `git push -u origin <branch-name>`
3. **Create PR** via GitHub UI (gh CLI not available)
4. **Request review** from appropriate team members
5. **Address feedback** and push updates as needed
6. **Merge** once approved (squash merge preferred for cleaner history)

---

## Git Conventions

### Commit Messages

Follow the **Conventional Commits** specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates
- `perf`: Performance improvements
- `ci`: CI/CD changes

**Examples**:
```
feat(auth): add user authentication with JWT

Implement JWT-based authentication system including:
- Login endpoint with token generation
- Token validation middleware
- Refresh token rotation

Closes #123
```

```
fix(api): resolve race condition in data fetching

Added mutex lock to prevent concurrent access issues
when multiple requests hit the endpoint simultaneously.
```

### Git Operations Best Practices

**Pushing**:
- Always use: `git push -u origin <branch-name>`
- Retry logic: Up to 4 attempts with exponential backoff (2s, 4s, 8s, 16s)
- Verify branch name starts with `claude/` before pushing

**Fetching/Pulling**:
- Prefer specific branches: `git fetch origin <branch-name>`
- Use retry logic for network failures
- For pulls: `git pull origin <branch-name>`

**Committing**:
- Run pre-commit hooks (never use `--no-verify` unless explicitly requested)
- Stage related changes together
- Write descriptive commit messages
- Keep commits atomic and focused

---

## Code Organization Guidelines

### General Principles

1. **Separation of Concerns**: Keep business logic, presentation, and data access separate
2. **DRY (Don't Repeat Yourself)**: Extract common functionality into reusable modules
3. **SOLID Principles**: Follow object-oriented design principles
4. **Explicit Over Implicit**: Code should be self-documenting
5. **Consistency**: Follow established patterns within the codebase

### Naming Conventions

**To Be Established Based on Language Choice**

Common standards:
- **Files**: kebab-case for most languages (`user-service.ts`), snake_case for Python (`user_service.py`)
- **Directories**: kebab-case (`user-management/`)
- **Variables/Functions**: camelCase (JavaScript/TypeScript), snake_case (Python)
- **Classes**: PascalCase (all languages)
- **Constants**: SCREAMING_SNAKE_CASE (all languages)

### Code Style

- Use a formatter (Prettier, Black, etc.) to maintain consistent style
- Configure linter (ESLint, Flake8, etc.) for code quality
- Include editor config (.editorconfig) for consistent IDE settings
- Set up pre-commit hooks to enforce standards

---

## Testing Strategy

### Testing Pyramid

1. **Unit Tests** (70%): Test individual functions and classes in isolation
2. **Integration Tests** (20%): Test component interactions
3. **End-to-End Tests** (10%): Test complete user workflows

### Test Organization

- Mirror source directory structure in tests/
- Name test files: `<source-file>.test.<ext>` or `test_<source-file>.<ext>`
- One test file per source file (generally)
- Group related tests using describe/context blocks

### Coverage Goals

- Aim for 80%+ code coverage
- 100% coverage for critical business logic
- Focus on meaningful tests, not just coverage numbers

### Test Naming

Use descriptive test names that explain:
- What is being tested
- Under what conditions
- What the expected outcome is

Example:
```javascript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a new user with valid data', () => { /* ... */ });
    it('should throw ValidationError when email is invalid', () => { /* ... */ });
    it('should hash password before storing', () => { /* ... */ });
  });
});
```

---

## Documentation Standards

### Required Documentation

1. **README.md**: Project overview, setup instructions, usage examples
2. **CLAUDE.md**: AI assistant guide (this file)
3. **CONTRIBUTING.md**: Contribution guidelines
4. **LICENSE**: Project license
5. **CHANGELOG.md**: Version history and changes
6. **API Documentation**: For libraries and services (JSDoc, Sphinx, etc.)

### Inline Documentation

- Document all public APIs
- Use JSDoc, docstrings, or language-appropriate documentation format
- Explain WHY, not just WHAT (code shows what, comments explain why)
- Keep documentation close to code it describes
- Update documentation when changing code

### Documentation Format

**Function/Method Documentation**:
```typescript
/**
 * Authenticates a user with email and password.
 *
 * @param email - The user's email address
 * @param password - The user's plain text password
 * @returns A JWT token for authenticated requests
 * @throws {AuthenticationError} If credentials are invalid
 * @throws {RateLimitError} If too many attempts made
 *
 * @example
 * ```typescript
 * const token = await authenticateUser('user@example.com', 'password123');
 * ```
 */
async function authenticateUser(email: string, password: string): Promise<string> {
  // Implementation
}
```

---

## AI Assistant Best Practices

### When Working on This Repository

1. **Always Check Current State First**
   - Read relevant files before editing
   - Understand existing patterns and conventions
   - Use Grep/Glob to find similar code for consistency

2. **Use Todo Management**
   - Create todos for multi-step tasks
   - Mark tasks as in_progress before starting
   - Complete todos immediately when done
   - Don't batch completions

3. **Follow Git Workflow**
   - Develop on designated feature branch
   - Commit with conventional commit messages
   - Push to correct branch with retry logic
   - Never force push without explicit permission

4. **Maintain Code Quality**
   - Run tests before committing
   - Fix linting errors
   - Ensure builds pass
   - Check for security vulnerabilities (XSS, SQL injection, etc.)

5. **Documentation Updates**
   - Update this CLAUDE.md when structure changes
   - Keep README.md current
   - Document new APIs and functions
   - Update CHANGELOG.md for notable changes

6. **Security Considerations**
   - Never commit secrets or credentials
   - Validate and sanitize user input
   - Follow OWASP Top 10 guidelines
   - Use parameterized queries for databases
   - Implement proper authentication and authorization

7. **Communication**
   - Ask for clarification when requirements are unclear
   - Explain significant changes and architectural decisions
   - Provide context in commit messages and PR descriptions
   - Report blockers or issues discovered

### Task Planning Approach

For complex tasks:

1. **Research Phase**
   - Explore codebase to understand current implementation
   - Identify files and components that need changes
   - Check for existing patterns to follow

2. **Planning Phase**
   - Break down task into actionable items
   - Create todo list with TodoWrite
   - Identify dependencies and order of operations

3. **Implementation Phase**
   - Mark todo as in_progress
   - Make focused, incremental changes
   - Test as you go
   - Complete todo when done

4. **Verification Phase**
   - Run full test suite
   - Check linting and formatting
   - Build the project
   - Review changes for completeness

5. **Finalization Phase**
   - Commit with descriptive message
   - Push to feature branch
   - Create PR if ready for review

### Common Pitfalls to Avoid

- ❌ Making assumptions about project structure without verifying
- ❌ Editing files without reading them first
- ❌ Creating new files when editing existing ones would suffice
- ❌ Committing without running tests
- ❌ Force pushing or using --no-verify flags
- ❌ Batch completing multiple todos at once
- ❌ Using bash echo for communication instead of direct output
- ❌ Introducing security vulnerabilities

### Tool Usage Guidelines

**Prefer specialized tools**:
- Read tool for viewing files (not cat/head/tail)
- Edit tool for modifying files (not sed/awk)
- Write tool for creating files (not echo > or cat <<EOF)
- Grep tool for searching (not grep/rg commands)
- Glob tool for finding files (not find)

**Use Task tool for**:
- Exploring codebase to answer questions
- Complex multi-step research
- Code reviews
- Setting up new features

**Parallel execution**:
- Run independent operations in parallel
- Make multiple tool calls in single message when possible
- Only run sequentially when dependencies exist

---

## Future Roadmap

### Immediate Next Steps

1. **Determine Project Type and Language**
   - Choose primary programming language(s)
   - Select frameworks and libraries
   - Define project purpose and scope

2. **Initialize Development Environment**
   - Set up package manager (npm, pip, cargo, etc.)
   - Configure build tools
   - Install and configure linters/formatters
   - Set up pre-commit hooks

3. **Establish Project Structure**
   - Create src/ directory with initial modules
   - Set up tests/ directory with framework
   - Add configuration files
   - Create example/template files

4. **Configure CI/CD**
   - Set up GitHub Actions workflows
   - Configure automated testing
   - Set up automated builds
   - Add deployment pipeline (if applicable)

5. **Complete Documentation**
   - Expand README.md with setup instructions
   - Add CONTRIBUTING.md
   - Choose and add LICENSE
   - Create initial CHANGELOG.md
   - Document APIs as they're built

### Development Milestones

- [ ] Project initialization complete
- [ ] Basic project structure established
- [ ] First feature implemented with tests
- [ ] CI/CD pipeline operational
- [ ] Documentation complete
- [ ] First release/deployment

---

## Questions or Issues?

When working on this repository:

1. **Check documentation first**: README.md, this file, and inline docs
2. **Explore the codebase**: Use Task tool to understand existing patterns
3. **Ask for clarification**: When requirements or approaches are unclear
4. **Follow conventions**: Maintain consistency with established patterns
5. **Update this file**: Keep CLAUDE.md current as the project evolves

---

## Changelog

### 2025-11-16
- Initial CLAUDE.md creation
- Repository in pre-initialization state
- Established guidelines for future development
- Defined conventions and best practices for AI assistants

---

**Note**: This document should be updated regularly as the project evolves. When significant changes occur to project structure, workflows, or conventions, update this file accordingly.
