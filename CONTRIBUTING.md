# Contributing to Songify 🎵

Thanks for your interest in contributing to **Songify**!

Songify is an independent Flutter project built for learning, experimentation, and creating a better music-listening experience.

Whether you're fixing a bug, improving the UI, adding a feature, improving documentation, or simply suggesting an idea, your contribution is welcome.

You don't need to be an open-source expert to contribute. Start small, learn as you go, and build something useful.

---

## 🌱 Ways to Contribute

You can contribute by:

* 🐛 Fixing bugs
* ✨ Adding features
* 🎨 Improving UI/UX
* ⚡ Improving performance
* 📱 Improving the mobile experience
* 📝 Improving documentation
* 💡 Suggesting ideas
* 🧪 Improving tests
* 🔧 Improving code quality

---

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

* [Flutter](https://flutter.dev/) installed
* [Dart](https://dart.dev/) installed
* Git installed
* An Android device or emulator
* A GitHub account

Check your Flutter installation:

```bash
flutter --version
```

Check Git:

```bash
git --version
```

---

## 🍴 1. Fork the Repository

Open the Songify repository on GitHub and click **Fork**.

This creates your own copy of the repository where you can make changes without affecting the original project.

---

## 📥 2. Clone Your Fork

Open your terminal and run:

```bash
git clone https://github.com/YOUR-USERNAME/songify.git
```

Move into the project:

```bash
cd songify
```

Replace `YOUR-USERNAME` with your GitHub username.

---

## 🔗 3. Add the Original Repository

Add the main Songify repository as `upstream`:

```bash
git remote add upstream https://github.com/YOUR-USERNAME/songify.git
```

Check your remotes:

```bash
git remote -v
```

You should see your fork as `origin` and the original repository as `upstream`.

> Replace the repository URL above with the actual Songify repository URL before publishing this guide.

---

## 🌿 4. Create a Branch

Don't make changes directly on `main`.

First, make sure your local `main` is up to date:

```bash
git checkout main
git pull upstream main
```

Create a new branch:

```bash
git checkout -b feature/your-feature-name
```

Examples:

```bash
git checkout -b feature/add-playlists
```

```bash
git checkout -b fix/player-crash
```

```bash
git checkout -b ui/improve-home-screen
```

```bash
git checkout -b docs/update-readme
```

Use a short and descriptive branch name.

---

## 📦 5. Install Dependencies

Install the Flutter dependencies:

```bash
flutter pub get
```

---

## 💻 6. Make Your Changes

Now make your changes.

Keep the following in mind:

* Follow the existing project structure.
* Keep code readable and simple.
* Avoid unnecessary dependencies.
* Keep your changes focused.
* Don't modify unrelated files.
* Remove debugging code before submitting.
* Add or update documentation when necessary.

For larger changes, consider opening an issue before starting so the approach can be discussed first.

---

## 🧪 7. Test Your Changes

Run Flutter's analyzer:

```bash
flutter analyze
```

Then run the application:

```bash
flutter run
```

Test the feature or fix you worked on.

If your change affects the UI, test it on an emulator or physical device and check different screen sizes where possible.

---

## 🔍 8. Check Your Changes

Before committing, check what changed:

```bash
git status
```

Review the actual changes:

```bash
git diff
```

Make sure you haven't accidentally included:

* Debug files
* API keys
* Passwords
* `.env` files
* Generated files that shouldn't be committed
* Unrelated changes

Never commit secrets or private credentials.

---

## 💾 9. Commit Your Changes

Stage your changes:

```bash
git add .
```

Create a meaningful commit:

```bash
git commit -m "Add playlist support"
```

Good commit messages describe what changed.

Examples:

```text
Add playlist support
Fix audio player state
Improve search UI
Update contributing guide
Fix player crash on song change
```

Avoid messages like:

```text
update
changes
final
final final
please work
```

The last one has never improved a codebase.

---

## ⬆️ 10. Push Your Branch

Push your branch to your fork:

```bash
git push origin feature/your-feature-name
```

For example:

```bash
git push origin feature/add-playlists
```

---

## 🔀 11. Open a Pull Request

Go to your fork on GitHub.

GitHub should show an option to create a **Pull Request** for your recently pushed branch.

Create the PR against:

```text
Songify → main
```

In your pull request description, explain:

### What changed?

Briefly describe your changes.

### Why?

Explain the problem or reason for the change.

### Testing

Mention how you tested it.

### Screenshots

For UI changes, include screenshots or a screen recording.

---

## 📋 Pull Request Checklist

Before submitting your PR:

* [ ] I created a separate branch.
* [ ] I tested my changes locally.
* [ ] `flutter analyze` passes.
* [ ] I reviewed my changes with `git diff`.
* [ ] I didn't commit secrets or credentials.
* [ ] I didn't include unrelated changes.
* [ ] My commit message is meaningful.
* [ ] I updated documentation where necessary.
* [ ] I added screenshots for significant UI changes.
* [ ] My PR description clearly explains the changes.

---

## 🔄 Keeping Your Fork Updated

Before starting new work, sync your fork with the original repository:

```bash
git checkout main
git pull upstream main
```

Then push the updated `main` to your fork:

```bash
git push origin main
```

Create a fresh branch for your next contribution:

```bash
git checkout -b feature/your-next-feature
```

Keeping your branch current helps reduce merge conflicts.

---

## 🐛 Reporting Bugs

Before opening an issue, search existing issues to make sure the problem hasn't already been reported.

A useful bug report should include:

* What happened
* What you expected
* Steps to reproduce the issue
* Device and operating system
* Flutter version
* Screenshots or recordings
* Error messages or logs, if available

---

## 💡 Suggesting Features

Have an idea for Songify?

Open an issue and explain:

* What you'd like to add
* Why it would be useful
* How you think it could work
* Examples or references, if applicable

Thoughtful feature proposals are always welcome.

---

## 🎨 UI Contributions

When improving Songify's interface:

* Keep the existing visual style consistent.
* Avoid unnecessary complexity.
* Consider different screen sizes.
* Test on an emulator or physical device.
* Include screenshots in your PR.

---

## 🤝 Code of Conduct

Be respectful and constructive when communicating with other contributors.

Different technical opinions are normal. Discuss the implementation, not the person.

---

## ❤️ Contributors

Every contribution matters.

Contributors will be recognized in **[CONTRIBUTORS.md](CONTRIBUTORS.md)** with links to their GitHub profiles.

Whether you fix a typo, improve the UI, fix a bug, or build a major feature, thank you for helping improve Songify.

---

## ⚠️ Project Disclaimer

Songify is an educational and portfolio project.

The application uses unofficial endpoints for music-related data. Songify does not claim ownership of music, artwork, metadata, artist information, or other copyrighted content provided through these services.

Contributions should respect applicable copyright laws and the terms of service of the services used by the project.

---

**Thank you for contributing to Songify! 🎵**

Built by developers, improved by the community.
