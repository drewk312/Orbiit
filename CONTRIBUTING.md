# Contributing to Orbiit

First off, thank you for considering contributing to Orbiit! 🎉

It's people like you that make Orbiit such a great tool. We welcome contributions from everyone, whether you're fixing a typo, reporting a bug, or implementing a major feature.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Code Contributions](#code-contributions)
  - [Documentation](#documentation)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior via [GitHub Issues](https://github.com/drewk312/Orbiit/issues).

**In short:**
- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating a bug report, please check the [existing issues](https://github.com/drewk312/Orbiit/issues) to avoid duplicates.

**How to Submit a Good Bug Report:**

1. **Use a clear and descriptive title**
2. **Describe the exact steps to reproduce the problem**
3. **Provide specific examples** (screenshots, error messages, logs)
4. **Describe the behavior you observed** and what you expected
5. **Include your environment details**:
   - Orbiit version
   - Operating System (Windows/macOS/Linux)
   - Flutter version (if building from source)

**Bug Report Template:**

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. Windows 11]
 - Orbiit Version: [e.g. v1.01 Beta]
 - Flutter Version: [if building from source]

**Additional context**
Add any other context about the problem here.
```

---

### 💡 Suggesting Features

We love feature suggestions! Before creating a feature request:

1. **Check if it's already suggested** in [Discussions](https://github.com/drewk312/Orbiit/discussions)
2. **Consider if it aligns** with Orbiit's core purpose
3. **Think about scope** - is this a minor tweak or a major overhaul?

**Feature Request Template:**

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
Any alternative solutions or features you've considered.

**Additional context**
Add any other context, mockups, or screenshots about the feature request.

**Would you be willing to implement this?**
Let us know if you'd like to contribute code for this feature.
```

---

### 💻 Code Contributions

Ready to write some code? Awesome! Here's how to get started:

#### First Time Contributors

If this is your first time contributing to open source, check out:
- [First Timers Only](https://www.firsttimersonly.com/)
- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)

Look for issues labeled `good first issue` or `help wanted`!

#### What to Work On

- **Bug fixes**: Check issues labeled `bug`
- **Features**: Look for `enhancement` or `feature-request` labels
- **Documentation**: Issues labeled `documentation`
- **Testing**: We always need more test coverage!

**Before starting work on a major feature**, open an issue or discussion to get feedback from maintainers. This prevents wasted effort on changes that might not be merged.

---

### 📚 Documentation

Documentation improvements are always welcome! This includes:
- README improvements
- Code comments
- Wiki pages
- Tutorials and guides
- API documentation

---

## 🛠️ Development Setup

### Prerequisites

- **Flutter SDK** 3.0 or higher
- **Visual Studio 2022** (Windows) with C++ workload
- **CMake** 3.15+
- **Git**

### Setting Up Your Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
```bash
git clone https://github.com/YOUR-USERNAME/Orbiit.git
cd Orbiit
```

3. **Add upstream remote**:
```bash
git remote add upstream https://github.com/drewk312/Orbiit.git
```

4. **Install dependencies**:
```bash
flutter pub get
```

5. **Build native code**:
```bash
cd native
mkdir build && cd build
cmake ..
cmake --build . --config Release
cd ../..
```

6. **Run the app**:
```bash
flutter run -d windows
```

### Keeping Your Fork Updated

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

---

## 📐 Coding Guidelines

### Dart/Flutter Style

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

- Use `lowerCamelCase` for variables, methods, and parameters
- Use `UpperCamelCase` for classes and enums
- Use `lowercase_with_underscores` for library and file names
- Format code with `dart format .`
- Analyze code with `flutter analyze`

### Code Organization

```dart
// 1. Imports (sorted)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orbiit/models/game.dart';

// 2. Class declaration
class GameCard extends StatelessWidget {
  // 3. Public constants
  static const double cardHeight = 200.0;
  
  // 4. Public final fields
  final Game game;
  final VoidCallback? onTap;
  
  // 5. Constructor
  const GameCard({
    Key? key,
    required this.game,
    this.onTap,
  }) : super(key: key);
  
  // 6. Build method
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
  
  // 7. Private methods
  void _handleTap() {
    // Implementation
  }
}
```

### Comments

- Write self-documenting code when possible
- Add comments for complex logic
- Use `///` for public API documentation
- Use `//` for inline comments

```dart
/// Fetches game metadata from GameTDB.
/// 
/// Returns `null` if the game is not found or if there's a network error.
Future<GameMetadata?> fetchMetadata(String gameId) async {
  // Use cached data if available
  final cached = _cache[gameId];
  if (cached != null && !cached.isExpired) {
    return cached;
  }
  
  // Fetch from network
  try {
    final response = await http.get(Uri.parse('...'));
    // ... rest of implementation
  } catch (e) {
    print('Error fetching metadata: $e');
    return null;
  }
}
```

### Error Handling

- Always handle potential errors
- Use try-catch for async operations
- Provide meaningful error messages

```dart
// ✅ Good
try {
  final games = await scanLibrary(path);
  return games;
} catch (e) {
  debugPrint('Failed to scan library at $path: $e');
  showErrorSnackbar('Could not scan games. Please check your drive path.');
  return [];
}

// ❌ Bad
try {
  final games = await scanLibrary(path);
  return games;
} catch (e) {
  return [];
}
```

### Testing

- Write tests for new features
- Ensure existing tests pass before submitting PR
- Run tests with: `flutter test`

```dart
test('Game.fromJson correctly parses game data', () {
  final json = {
    'id': 'RMGE01',
    'title': 'Super Mario Galaxy',
    'platform': 'Wii',
  };
  
  final game = Game.fromJson(json);
  
  expect(game.id, 'RMGE01');
  expect(game.title, 'Super Mario Galaxy');
  expect(game.platform, Platform.wii);
});
```

---

## 📝 Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semi-colons, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Changes to build process or auxiliary tools

### Examples

```bash
feat(library): add region filtering to game library

Users can now filter their library by NTSC-U, PAL, or NTSC-J regions.
This includes a new dropdown in the library toolbar and updates to the
GameFilter class.

Closes #42
```

```bash
fix(downloads): resolve crash when download queue is cleared

Fixed a null pointer exception that occurred when clearing the download
queue while a download was in progress.

Fixes #89
```

```bash
docs(readme): update installation instructions for macOS

Added specific steps for macOS users including Xcode requirements and
CocoaPods installation.
```

---

## 🔀 Pull Request Process

### Before Submitting

1. **Test your changes** thoroughly
2. **Run code analysis**: `flutter analyze`
3. **Format your code**: `dart format .`
4. **Update documentation** if needed
5. **Add tests** for new features
6. **Update CHANGELOG.md** (if applicable)

### Submitting the PR

1. **Push your changes** to your fork
2. **Open a Pull Request** against the `main` branch
3. **Fill out the PR template** completely
4. **Link related issues** (e.g., "Fixes #123")
5. **Be responsive** to review feedback

### PR Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
Closes #(issue number)

## How Has This Been Tested?
Describe the tests you ran and how to reproduce them.

## Screenshots (if applicable)
Add screenshots to demonstrate the changes.

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### Review Process

- Maintainers will review your PR as soon as possible
- You may be asked to make changes
- Once approved, a maintainer will merge your PR
- **Be patient!** Reviews can take time, especially for large PRs

---

## 🏷️ Issue and PR Labels

| Label | Description |
|-------|-------------|
| `bug` | Something isn't working |
| `enhancement` | New feature or request |
| `good first issue` | Good for newcomers |
| `help wanted` | Extra attention is needed |
| `question` | Further information is requested |
| `documentation` | Improvements or additions to documentation |
| `wontfix` | This will not be worked on |
| `duplicate` | This issue or pull request already exists |
| `priority: high` | High priority issue |

---

## 🎯 Areas We Need Help

Current focus areas where contributions are especially welcome:

- **Performance Optimization**: Library scanning for 1000+ games
- **Multi-source Downloads**: Fallback CDN support
- **Testing**: Unit and integration tests
- **Documentation**: Wiki pages, tutorials
- **Localization**: Translations to other languages
- **Platform Support**: macOS and Linux improvements

---

## 📬 Questions?

If you have questions about contributing:

- Check the [Discussions](https://github.com/drewk312/Orbiit/discussions)
- Open an issue with the `question` label

---

## 🙏 Thank You!

Your contributions make Orbiit better for everyone. We appreciate your time and effort! 🌟

---

*This contributing guide is adapted from various open-source projects. Feel free to suggest improvements!*
