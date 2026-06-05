# OSLAH (Open-Source Local Agent Hub) - Phase 2 Architecture Plan

We are extending the local-first AI hub to support SQLite database storage, an offline multi-user HTTP API hosting server, and an advanced local RAG indexing engine.

---

## User Review Required

> [!IMPORTANT]
> **Database Initialization:** For Flutter Desktop, SQLite must be initialized using the `sqflite_common_ffi` package, requiring `sqfliteFfiInit()` and binding the database factory on startup.
> **Local HTTP Server Endpoint:** The server binds to `0.0.0.0` (all local interfaces) on a configurable port (default 8080). It handles incoming `/api/chat` requests and streams responses back to external clients using HTTP chunked encoding.
> **RAG Lookup Engine:** We will implement a text-overlap keyword similarity lookup in Dart using SQLite to match files against the user query, providing instant offline RAG context injection.

---

## Open Questions

> [!NOTE]
> 1. **Server Stream vs Complete Response:** For the HTTP endpoint `/api/chat`, we will support both chunked streaming and single-block responses based on the request JSON `'stream'` parameter, identical to Ollama's specifications.
> 2. **Multi-User Queue Integration:** Since the HTTP server requests run concurrently with local UI requests, routing them both through the existing `QueueManager` guarantees that the system never chokes. We will update the `QueueManager` to support this.

---

## Proposed Changes

### Dependencies Layer

#### [MODIFY] [pubspec.yaml](file:///e:/oslah/pubspec.yaml)
Add database and path utility packages:
- `sqflite_common_ffi`: ^2.3.3
- `sqlite3_flutter_libs`: ^0.5.24
- `path_provider`: ^2.1.3
- `path`: ^1.9.0

---

### Core Services Layer

#### [NEW] [database_service.dart](file:///e:/oslah/lib/services/database_service.dart)
Initializes database `oslah.db` using FFI.
- Handles migrations and table setups:
  - `network_settings` (`host TEXT, port INTEGER, server_status INTEGER`)
  - `knowledge_chunks` (`id TEXT PRIMARY KEY, file_name TEXT, chunk_index INTEGER, text_content TEXT`)
- CRUD operations for retrieving settings and saving/searching document chunks.

#### [NEW] [rag_indexer_service.dart](file:///e:/oslah/lib/services/rag_indexer_service.dart)
Coordinates file content chunking and text similarity indexing.
- Slices documents into 500-character chunks with a 100-character overlap.
- Inserts chunks into SQLite.
- Performs TF-IDF or keyword-frequency similarity queries to retrieve the top 3 matching chunks for prompt injection.

#### [NEW] [local_server_service.dart](file:///e:/oslah/lib/services/local_server_service.dart)
Runs a background Dart `HttpServer` binding to port 8080.
- Listens to POST `/api/chat`.
- Validates payload structure, enqueues request in `QueueManager`, and pipes the output stream back to the client as chunked HTTP response.

---

### UI & Presentation Layer

#### [NEW] [network_settings_panel.dart](file:///e:/oslah/widgets/network_settings_panel.dart)
The server administration screen:
- Server switch: Start/Stop HTTP server in real-time.
- Metrics cards: Shows Host IP, active port, status (Running/Stopped).
- Queue status: List view tracking active external request handles.

#### [MODIFY] [dashboard_screen.dart](file:///e:/oslah/lib/screens/dashboard_screen.dart)
- Integrate a new navigation tab: **"Local Server API"** linking to the `NetworkSettingsPanel`.

#### [MODIFY] [agent_provider.dart](file:///e:/oslah/lib/providers/agent_provider.dart)
- Integrates `DatabaseService`, `RagIndexerService`, and `LocalServerService`.
- Coordinates server state toggles, RAG document ingestion, and configuration saving/loading.

---

## Verification Plan

### Automated Tests
- Build and compile verification:
  ```bash
  flutter pub get
  flutter analyze
  ```
- Run widget smoke tests verifying local server tab:
  ```bash
  flutter test
  ```

### Manual Verification
- Verify running the HTTP Server, fetching local IP, and calling the POST `/api/chat` endpoint using `curl` from a terminal.
- Verify text file ingestion divides contents into correct chunk sizes in database.
