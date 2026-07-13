# SnapSearch MVP Task Tracker

## ⚠️ MANDATORY INSTRUCTIONS FOR AI AGENTS
1. **READ FIRST:** Before starting any task, read this file to check current progress.
2. **UPDATE STATUS:** When you complete a task, change `[ ]` to `[x]`.
3. **RESPECT DEPENDENCIES:** If a task is marked `BLOCKED`, do not attempt it. Inform the human user.
4. **ADD COMMENTS:** If you need the other agent to do something, add a comment: `<!-- REQUEST: [Teammate] needs to [action] -->`.

---

## Phase 1: Foundation & Setup (Do Together)
- [x] Initialize Flutter project and configure strict linting (`AGENTS.md`, `analysis_options.yaml`).
- [x] Create `docs/` folder and define `ARCHITECTURE.md` and `DATA_CONTRACTS.md`.
- [ ] **Teammate 1 (Data):** Create `Screenshot` model and `IScreenshotRepository` interface in `lib/domain/`.
- [ ] **Teammate 2 (UI):** Setup `Provider` boilerplate, basic `MaterialApp` routing, and AppTheme in `lib/presentation/`.

## Phase 2: Mock Implementation (Parallel Execution)
*Goal: Get the UI running with fake data so Teammate 2 is not blocked by Teammate 1.*

- [ ] **Teammate 1 (Data):** Create `MockScreenshotRepository` in `lib/data/` returning 5 hardcoded dummy screenshots.
- [ ] **Teammate 2 (UI):** Build `DashboardScreen` (ListView of screenshots) and `DetailScreen` using the Mock Repository.
- [ ] **Teammate 2 (UI):** Wire up `ScreenshotProvider` to inject the Mock Repository.

## Phase 3: Real Data Layer (Teammate 1 Only)
*Goal: Replace mocks with real offline-first logic.*

- [ ] **Teammate 1 (Data):** Implement `DatabaseHelper` with SQLite and FTS5 setup for full-text search.
- [ ] **Teammate 1 (Data):** Implement `LocalScreenshotRepository` to replace the Mock.
- [ ] **Teammate 1 (Data):** Implement `OcrService` using ML Kit (resize image -> extract text).
- [ ] **Teammate 1 (Data):** Implement basic keyword-based categorization (e.g., if text contains "₹" or "$", category = 'receipt').

## Phase 4: UI Integration & Features (Teammate 2 Only)
*Goal: Connect the real data layer to the UI and add core features.*

- [ ] **Teammate 2 (UI):** Build `SearchScreen` with a search bar and category filter chips.
- [ ] **Teammate 2 (UI):** Connect `SearchScreen` to `IScreenshotRepository.searchScreenshots()`.
- [ ] **Teammate 2 (UI):** Implement permission handling (Photo gallery access) on app launch using `permission_handler`.
- [ ] **Teammate 2 (UI):** Add a background indexing trigger (e.g., a button "Scan New Screenshots") and loading states.

## Phase 5: Polish, Testing & Demo Prep
- [ ] **Both:** Run `flutter analyze` and fix ALL errors and warnings.
- [ ] **Both:** Test offline functionality (Turn on Airplane mode and verify search works).
- [ ] **Teammate 1 (Data):** Optimize image resizing to prevent Out-Of-Memory crashes on low-end devices.
- [ ] **Teammate 2 (UI):** Polish UI (add empty states, error snackbars, and smooth transitions).
- [ ] **Both:** Record 3-minute demo video and prepare pitch.

---

## 🚦 Current Blockers / Requests
<!-- Use this section to communicate across agents. Format: <!-- REQUEST: [Agent] needs [Action] --> -->