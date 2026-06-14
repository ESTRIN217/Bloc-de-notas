

# AI Development Guidelines for "Bloc de notas" in GitHub Codespaces
These guidelines define the operational principles and capabilities of the AI agent interacting with the **Bloc de notas** codebase\. The environment is shifted from Firebase to a web\-based **GitHub Codespaces** cloud container optimized for Android and Flutter development\.

## 1\. Environment & Context Awareness
The AI operates within a GitHub Codespaces container, utilizing terminal\-based tools, headless Android tools, and web previews\.

- **Project Structure & Architecture:** Standard Flutter layout applies\. The architecture must explicitly separate UI from business logic using **Feature\-first Structure** or **Layered Architecture** \(Presentation, Domain, Data\)\.
- **DRY Principle:** The AI must rigorously respect the **DRY \(Don't Repeat Yourself\)** philosophy\. Before writing any utility, widget, or helper, the AI will inspect existing files to reuse logic and avoid code duplication\.
- **Localization & Internationalization:** Every user\-facing string **must** support multi\-language translations\. Hardcoded strings in the UI are strictly prohibited\. The AI will utilize Flutter's localization files \(e\.g\., ARB files or localization context\) to add translations for any new feature\.
- **Environment Limitations:** Since development occurs via web\-browser containers, local physical device access isn't available\. The AI will leverage web previews or headless testing configurations inside the Codespace environment\.

## 2\. Material Design 3 UI/UX Specifications
The application interface must strictly adhere to **Material Design 3 \(Material You\)** guidelines\.

### Iconography Rule
- **Outlined Icons Only:** The AI must **always** use the outlined variant of Material Icons \(Icons\.xxxx\_outlined\) whenever available\. Filled, rounded, or sharp variations should never be generated unless an outlined equivalent does not exist\.

### Dynamic & Harmonic Colors
- The application must utilize ColorScheme\.fromSeed to ensure cohesive, modern, and accessible color palettes across light and dark modes\.
- Visual effects like multi\-layered drop shadows, soft deep elevation for lifted cards, and elegant colored glows on interactive states should be incorporated to create a premium, tactile feel\.

## 3\. Code Modification & State Management
- **Core Code Base:** The main entry point is lib/main\.dart\. The application relies on **Provider** and ChangeNotifier for app\-wide state management, dependency injection, and theme toggling \(Light/Dark/System\)\.
- **Local UI Reactivity:** For localized, single\-value state changes, the AI will use ValueNotifier and ValueListenableBuilder to maximize performance and minimize unnecessary widget rebuilds\.
- **Dependency Control:** External packages must be stable and added via standard Flutter tooling:
- **Automated Clean Code:** The AI will automatically trigger formatting and basic fixes to keep the code clean and compile\-ready:

## 4\. Local Architecture & Storage \(No Firebase\)
Since Firebase is no longer used, all persistence, cloud\-sync references, and AI architectures are shifted to modern standalone local methods or user\-controlled client\-side strategies\.

- **Local Storage:** High\-performance local storage \(like Hive, Isar, or Sqflite\) is preferred for caching notes, metadata, and user categories\.
- **Client\-Side Cloud Integration:** Any external backup systems \(e\.g\., Google Drive sync\) must be implemented strictly **Client\-Side** via OAuth2 and official REST APIs, maintaining privacy and decoupled architecture\.
- **Local Logging:** Application logs must rely exclusively on the structured dart:developer library\.

## 5\. Iterative Blueprint Management
Every cycle of change follows a strict documentation and verification flow to ensure consistency across separate IDE sessions:

1. **Blueprint Synchronization:** Before changing anything, the AI will create or update a blueprint\.md file in the root directory\. This file is the single source of truth and contains:
    - **Project Overview:** Current state, styling parameters, and established features\.
    - **Change History:** Log of changes from initial versions up to version 4\.0\.0 and upcoming 5\.0\.0 milestones\.
    - **Current Action Plan:** Step\-by\-step roadmap of the current prompt\.
2. **Verification Flow:** After changes are applied, the AI simulates or triggers flutter analyze and flutter test to ensure that no existing features are broken, and formatting conforms exactly to local specifications\.

## 6\. GitHub Codespaces Configuration \(\.devcontainer\)
To ensure that any GitHub Codespace container spins up with the exact toolchain required for this Flutter setup, the \.devcontainer/devcontainer\.json or configuration files should be used as the environment's source of truth instead of dev\.nix\.The environment includes:

- Flutter and Dart SDKs configured for Android and Web targets\.
- Extensions for Dart, Flutter, and Markdown styling\.
