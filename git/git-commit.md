# Git Commit Message Standard

This document describes the standard format for writing clean, consistent, professional Git commit messages using **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)**.

---

## 📌 Commit Message Format

```
<type>(optional-scope): <short summary>

(optional body)

(optional footer)
```

---

## 🎯 Commit Types

| Type | Purpose |
|------|---------|
| **feat** | New feature |
| **fix** | Bug fix |
| **docs** | Documentation updates |
| **style** | Non-code changes (formatting, spacing) |
| **refactor** | Code improvement without changing behavior |
| **perf** | Performance improvement |
| **test** | Adding or updating tests |
| **build** | Build system or dependencies |
| **ci** | Continuous Integration updates |
| **chore** | Maintenance tasks |

---

## ✨ Examples

### 1. Adding a new document
```
docs: add project requirements document
```

### 2. Fixing a bug
```
fix(auth): resolve token expiration issue
```

### 3. Adding a new feature
```
feat(blog): add post search functionality
```

### 4. Refactoring code
```
refactor(api): simplify user serializer logic
```

### 5. Updating documentation
```
docs(readme): update setup instructions
```

---

## 📝 Best Practices

- Use **lowercase** for the commit type
- Write in **present tense** (e.g., "add" not "added")
- Keep the summary **short (≤ 50 characters)**
- Use the body to explain **why** the change was made
- Use footer for issue references, e.g.:

```
Closes #42
```

---

## 📄 Example with Body + Footer
```
feat(auth): implement refresh token flow

Added refresh token rotation and secure cookie handling.

Closes #42
```

---
