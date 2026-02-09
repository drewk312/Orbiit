# Contributing to Orbiit 🌌

First off, thanks for taking the time to contribute! Orbiit (formerly WiiGC Fusion) is a community-driven project, and we love seeing new faces.

## 🤝 How Can I Contribute?

### 🐛 Reporting Bugs
This section guides you through submitting a bug report for Orbiit. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

- **Use the Issue Search:** check if the issue has already been reported.
- **Check the [Issue Template](.github/ISSUE_TEMPLATE/bug_report.md):** We have a template for a reason! Please fill it out completely.

### 💡 Suggesting Enhancements
This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.

- **Check the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md):** Describe your idea in detail.

### 💻 Local Development

1.  **Fork the repo** and clone it locally.
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Build the Native Core:**
    Orbiit uses a C++ core (`forge_core`) for performance. You must build it before running the app.
    ```bash
    cd native
    mkdir build && cd build
    cmake ..
    cmake --build . --config Debug
    ```
4.  **Run the App:**
    ```bash
    flutter run -d windows
    ```

## 🎨 Coding Style

- **Dart:** We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
- **C++:** We generally follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html).
- **Commits:** Please use descriptive commit messages. We prefer [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat: add new hardware detection`).

## 📜 License

By contributing, you agree that your contributions will be licensed under the project's [LICENSE](LICENSE).
