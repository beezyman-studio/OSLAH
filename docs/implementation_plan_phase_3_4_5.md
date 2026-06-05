# OSLAH (Open-Source Local Agent Hub) - Phase 3, 4, & 5 Architecture Plan

We are combining Phases 3, 4, and 5 to finalize the OSLAH MVP launch. This plan outlines schema migration, custom agent management, live hardware monitoring, Ollama model downloading, and request access log security vault features.

---

## User Review Required

> [!IMPORTANT]
> **Database Versioning:** SQLite database version will be incremented from `1` to `2`. We will add an `onUpgrade` hook to support dynamic schema migration of `agents` and `access_logs` tables.
> **Model Downloader Stream Parsing:** Ollama's model pull endpoint (`/api/pull`) streams progression metrics in JSON lines format. We will parse the stream in real-time, calculating download speed (in MB/s) and percentage completions.
> **Enterprise Access Logs:** Every HTTP API request hitting the local server will be logged into the database, tracking client IP, timestamp, endpoint, bytes, status code, and authentication result.

---

## Open Questions

> [!NOTE]
> 1. **Default Agents:** We will pre-populate the `agents` table with a few standard agents (e.g., "Developer Agent", "Creative Writer") to let the user test Custom Agents immediately on fresh launch.
> 2. **Mocking hardware metrics:** For cross-platform desktop reliability without heavy system-level dynamic library wrappers, CPU/RAM/GPU metrics will be driven by a robust timer service that simulates hardware utilization spikes when Ollama model inference is active.

---

## Proposed Changes

### Core Database Layer

#### [MODIFY] [database_service.dart](file:///e:/oslah/lib/services/database_service.dart)
- Upgrade DB version to `2`.
- Add `agents` table: `id TEXT PRIMARY KEY, name TEXT, system_prompt TEXT, icon TEXT, description TEXT`
- Add `access_logs` table: `id TEXT PRIMARY KEY, client_ip TEXT, timestamp TEXT, bytes_processed INTEGER, endpoint TEXT, status_code INTEGER, authenticated INTEGER`
- Implement helper methods to fetch, delete, and add access logs.

---

### Core Services Layer

#### [NEW] [agent_manager_service.dart](file:///e:/oslah/lib/services/agent_manager_service.dart)
- Database repository to manage custom agents (CRUD).
- Handles active agent selections, which feeds the agent's customized system prompts into the conversation stream.

#### [NEW] [model_downloader_service.dart](file:///e:/oslah/lib/services/model_downloader_service.dart)
- Communicates with Ollama local endpoint `POST /api/pull` with `stream: true`.
- Parses chunked lines to extract download stats: `status`, `completed`, `total`, `digest`.
- Computes percentage completions and download speeds, emitting updates via a broadcast `Stream`.

---

### UI Panels & Widgets

#### [NEW] [agent_builder_panel.dart](file:///e:/oslah/lib/widgets/agent_builder_panel.dart)
- UI panel containing:
  - Custom agent creation form (identity name, description, system prompt, icon selector).
  - List of saved agents with Quick-Select, Edit, and Delete action triggers.

#### [NEW] [system_metrics_panel.dart](file:///e:/oslah/lib/widgets/system_metrics_panel.dart)
- Visual workspace displaying:
  - CPU, RAM, and GPU utilization using premium custom UI progress arcs and line/bar indicators.
  - Model downloader interface: input a model name (e.g. `phi3`, `llama3`), trigger download, and view download speeds (MB/s) and percentage progress bars.

#### [NEW] [access_logs_panel.dart](file:///e:/oslah/lib/widgets/access_logs_panel.dart)
- Datatable layout showing incoming network traffic history.
- Columns: Client IP, Timestamp, Endpoint, Status Code, Bytes, and Authentication Status (Successful/Rejected).
- Option to clear log tables in SQLite.

---

### State Provider & Routing Layer

#### [MODIFY] [agent_provider.dart](file:///e:/oslah/lib/providers/agent_provider.dart)
- Manage state properties for custom agents (fetching list, active agent selection).
- Connect `ModelDownloaderService` stream bindings to provider state metrics (active downloads progress).
- Log incoming client network calls from `LocalServerService` inside database access logs table.

#### [MODIFY] [dashboard_screen.dart](file:///e:/oslah/lib/screens/dashboard_screen.dart)
- Remove inline `AgentBuilderWorkspace`.
- Add new sidebar tabs: **"System Metrics"** and **"Access Logs"**.
- Update navigation build routing.

---

## Verification Plan

### Automated Tests
- Run code quality analyzer:
  ```bash
  flutter analyze
  ```
- Run widget smoke tests:
  ```bash
  flutter test
  ```

### Manual Verification
- Verify database migration updates schema tables without data loss.
- Try creating a custom agent in the "Agent Builder" panel and start a chat session to verify prompt context injection.
- Trigger model pull endpoint mock or target Ollama downloads to view progress speed updates.
- Test hitting the API server with `curl` and verify access log records are written correctly in SQLite.
