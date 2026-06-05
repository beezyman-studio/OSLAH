# 🌌 OSLAH: Open-Source Local Agent Hub

[![OSLAH App Header](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-blueviolet?style=for-the-badge&logo=flutter)](https://github.com/yourusername/oslah)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Local First](https://img.shields.io/badge/Privacy-100%25%20Local-success?style=for-the-badge&logo=shield)](https://github.com/yourusername/oslah)

> **OSLAH** is a private, local-first AI automation platform for Windows and macOS. It empowers developers and teams to run, share, and orchestrate private LLMs locally on their own machines without transmitting any data to third-party cloud providers.

---

## 🌟 Core Pillars

*   🔒 **100% Data Privacy:** Zero cloud telemetry. All database files, inference workloads, document indexing, and conversation histories are retained offline on your local disk.
*   ⚡ **Local-First AI Engine:** Seamlessly connects to your local Ollama daemon on port `11434` for rapid, zero-latency streaming inferences.
*   👥 **Multi-User Network Engine:** Instantly host a local HTTP Server, exposing a secure `/api/chat` API endpoint across your local network (`0.0.0.0`) to share GPU compute capacity safely with API key validation.

---

## 🚀 Key Features

*   🔌 **Ollama Autopilot & Silent Provisioning:** Auto-detects local Ollama runtimes. If missing, OSLAH triggers a silent background installer stream (`OllamaSetup.exe` / daemon initialization) to get your workspace ready without manual setup.
*   🧠 **Onboarding Setup Wizard:** First-launch UI that lets users evaluate and download local model weights (DeepSeek-R1 reasoning engine, Llama 3 generalist, or Phi-3 lightweight).
*   💾 **Air-Tight SQLite Database Layer:** Structured schema managing custom agent profiles, file chunks, network settings, and secure API key access logs.
*   ⚡ **Offline RAG Ingestion Service:** Drops and indexes text files or PDFs, slicing them into structured chunks with overlap, allowing semantic search mapping against local databases.
*   📊 **Live Hardware Utilization Trackers:** Visual dashboard monitors CPU, RAM, and GPU workloads dynamically during active LLM inference.
*   🔑 **Enterprise Access Logs & Auditing:** Auditable list of incoming network requests, response times, token logs, and server statuses to manage shared team resources.

---

## 📊 Local Brain Selection Matrix

When setting up OSLAH, you can provision one of the pre-configured local LLM options based on your hardware capabilities and language requirements:

| Model Option | Parameters | Core Strengths (PROS) | Drawbacks (CONS) | Malayalam Support | CPU / RAM Profile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DeepSeek-R1** | `7B` | 🧠 Step-by-step logical reasoning using `<think>` tags. Excellent math & coding capabilities. | ⏳ Slower initial response due to thinking cycles. Higher resource utilization. | **Excellent** 🌟 (Superb translations & comprehension) | Moderate-High (8GB+ RAM / VRAM) |
| **Llama 3** | `8B` | 💬 Highly conversational, fast streams. Extremely robust general knowledge base. | 🌐 Lacks step-by-step reasoning outputs. General knowledge only. | **Basic** ⚠️ (English is highly preferred) | Moderate-High (8GB+ RAM / VRAM) |
| **Phi-3** | `3.8B` | ⚡ Ultra-lightweight & fast. Runs efficiently on basic hardware configurations. | 📉 Simple logical tasks only. Limited memory context window. | **Poor** ❌ (Basic vocabulary matching only) | Low-Lightweight (4GB+ RAM / VRAM) |

---

## ⚙️ Quick Installation Guide

Ensure you have [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your system.

### 💻 Windows Setup

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/yourusername/oslah.git
    cd oslah
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the Desktop Client:**
    ```bash
    flutter run -d windows
    ```

### 🍎 macOS Setup

1.  **Clone & Access Directory:**
    ```bash
    git clone https://github.com/yourusername/oslah.git
    cd oslah
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the Desktop Client:**
    ```bash
    flutter run -d macos
    ```

> [!NOTE]
> On the first boot, OSLAH will run a quick dependency check. If Ollama is not installed or running, it will automatically initiate a background download and guide you through the initial model setup page.

---

## 🔒 Security & Sandboxing

OSLAH is designed with local enterprise security compliance in mind:
*   Incoming requests outside the host require a valid API header token `Authorization: Bearer <API_KEY>`.
*   Incoming payloads are parsed using a strict sequential queue to prevent local memory overflow or CPU exhaustion DOS attacks.

---

## 📄 License

Team BeezMan Studio Kerala
