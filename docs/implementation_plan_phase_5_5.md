# OSLAH - Phase 5.5 Setup Bootstrapper & Welcome Splash Screen Plan

We are implementing an elegant first-launch onboarding sequence. It checks for local Ollama presence, silently downloads and installs Ollama if missing, pulls the user's preferred LLM, and provides a premium interactive setup UI in Malayalam & English.

---

## User Review Required

> [!IMPORTANT]
> **Ollama Silent Installer:** If Ollama is missing, the app will download `OllamaSetup.exe` from `https://ollama.com/download/OllamaSetup.exe` and execute it silently via `Process.run` with the `/silent` parameter.
> **First-Launch Detection:** We will add a `first_launch` flag (default 1) in `network_settings` SQLite table. If set to 1, the app boots into the `SplashWelcomeScreen` instead of `DashboardScreen`.
> **Model Selection Pros/Cons:** Stage 1 displays two side-by-side hover-animated model cards (DeepSeek-R1 7B vs Llama 3 8B) showing localized English and Malayalam Pros/Cons.

---

## Proposed Changes

### Database Layer

#### [MODIFY] [database_service.dart](file:///e:/oslah/lib/services/database_service.dart)
- Update `network_settings` table definition to include `first_launch INTEGER DEFAULT 1`.
- Update `onUpgrade` to alter existing tables if needed.
- Add helper methods `Future<bool> checkFirstLaunch()` and `Future<void> completeFirstLaunch()`.

---

### Core Services Layer

#### [NEW] [bootstrapper_service.dart](file:///e:/oslah/lib/services/bootstrapper_service.dart)
- Implements a stream-based bootstrapping orchestrator.
- Defines state model `BootstrapperProgress`:
  - `status` (checking, downloadingInstaller, installing, startingOllama, pullingModel, completed, failed)
  - `progress` (double)
  - `speedMBs` (double)
  - `errorMessage` (String)
- **Presence Check:** Runs `Process.run('ollama', ['--version'])`.
- **Silent Download & Install:** If missing, pulls `OllamaSetup.exe` over HTTP, saves it locally, and launches it with `['/silent']` (Inno Setup silent flag).
- **Service Verification:** Polling check for connection to `http://localhost:11434`.
- **Model Pulling:** Calls `ModelDownloaderService` to pull the selected model.

---

### UI & Splash Layer

#### [NEW] [splash_welcome_screen.dart](file:///e:/oslah/lib/screens/splash_welcome_screen.dart)
- Premium dark obsidian welcome screen with two onboarding stages:
  - **Stage 1 (Model Selection):** Glassmorphic comparison cards.
    - DeepSeek-R1 (Excellent Malayalam, Reasoning steps, needs higher resources).
    - Llama 3 (Fast English, general knowledge, weak Malayalam translation).
  - **Stage 2 (Provisioning Ticker):** Animated loading meters displaying installer download speeds, active status messages, and model pull status.

#### [MODIFY] [main.dart](file:///e:/oslah/lib/main.dart)
- Map `MaterialApp.home` dynamically using `Consumer<AgentProvider>` checking `provider.isFirstLaunch`.

#### [MODIFY] [agent_provider.dart](file:///e:/oslah/lib/providers/agent_provider.dart)
- Manage `_isFirstLaunch` state loaded from database settings.
- Expose method `completeSetup(String selectedModel)` which calls `BootstrapperService` and marks first launch as complete.

---

## Verification Plan

### Automated Tests
- Run code verification:
  ```bash
  flutter analyze
  flutter test
  ```

### Manual Verification
- Simulate first-launch by wiping the database or updating SQLite settings.
- Verify welcome interface correctly compares models with responsive animations.
- Test downloading Ollama (or running the bootstrapper when Ollama is uninstalled) and verify it completes without errors.
