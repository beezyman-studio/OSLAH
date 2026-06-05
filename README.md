# 🌌 OSLAH: Open-Source Local Agent Hub

[![OSLAH App Header](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-blueviolet?style=for-the-badge&logo=flutter)](https://github.com/beezyman-studio/OSLAH)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Privacy: 100% Local](https://img.shields.io/badge/Privacy-100%25%20Local-success?style=for-the-badge&logo=shield)](https://github.com/beezyman-studio/OSLAH)
[![Open-Core: Active](https://img.shields.io/badge/Monetization-Open--Core-orange?style=for-the-badge&logo=cashapp)](https://github.com/beezyman-studio/OSLAH)

> **OSLAH** is a private, local-first AI automation platform for Windows and macOS. It empowers developers and teams to run, share, and orchestrate private LLMs locally on their own machines without transmitting any data to third-party cloud providers.

---

## 💎 Open-Core Monetization Model

OSLAH is built on an **Open-Core** distribution model. The core orchestration features are 100% free and open-source under the MIT license, while advanced multi-user routing, network administration, and enterprise security features require a commercial license.

### Feature Comparison Matrix

| Feature | 🍃 Free Core Edition | 🏆 Enterprise Pro Edition |
| :--- | :---: | :---: |
| **Local LLM Chat Interface** | ✅ Yes | ✅ Yes |
| **Offline RAG Document Indexing** | ✅ Yes | ✅ Yes |
| **Ollama Autopilot Provisioning** | ✅ Yes | ✅ Yes |
| **Hardware Workload Telemetry** | ✅ Yes | ✅ Yes |
| **LAN HTTP Server Gateway** | ❌ No | ✅ Yes |
| **Cupertino Switch Control Center** | ❌ No | ✅ Yes |
| **Admin vs Employee Role Separation** | ❌ No | ✅ Yes |
| **Administrative Control Endpoints** | ❌ No | ✅ Yes |
| **SQLite User Log Telemetry** | ❌ No | ✅ Yes |

---

## 📊 Corporate Strategy & Roadmap

OSLAH is uniquely positioned to capture the offline enterprise AI market by eliminating dependency on cloud infrastructures. For a deep-dive look at our business model, go-to-market strategy, and investor pitch deck, please refer directly to:
📄 **[OSLAH Corporate Strategy Presentation](docs/OSLAH_Strategy_Presentation.pdf)**

### Key Business Strategy Pillars:
1. **Commercial Licensing & Support:** Tailored subscriptions for local offices wishing to run local sandboxed AI gateways with priority technical SLA support.
2. **100% Air-Gapped Compliance:** Designed specifically for secure environments (such as healthcare, banking, and legal firms) that require strictly zero internet access and zero telemetry leakage.
3. **Hardware Optimization:** Maximizes the utilization of existing office workstation graphics cards (GPUs) to run lightweight local models (DeepSeek-R1, Llama 3) without ongoing token fees.

---

## ⚙️ Quick Installation & Setup

OSLAH is distributed as a native executable. We use Inno Setup to package and build clean installers for Windows desktop.

### 💻 Installing via Pre-built Installer (Windows)

1. Navigate to the **[InnoOutput/](InnoOutput/)** directory.
2. Launch **`OSLAH_Setup.exe`**.
3. Follow the installation wizard steps to create desktop shortcuts and run the application.

### 🛠️ Building from Source (Windows Developer Guide)

Ensure you have [Flutter SDK](https://flutter.dev/docs/get-started/install) and [Inno Setup](https://jrsoftware.org/isinfo.php) installed.

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/beezyman-studio/OSLAH.git
   cd oslah
   ```
2. **Install Dart Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Compile Release Binary:**
   ```bash
   flutter build windows --release
   ```
4. **Compile Setup Installer:**
   Open a terminal and run the Inno Setup compiler compiler:
   ```bash
   iscc oslah_installer.iss
   ```
   *The output installer will be generated at `InnoOutput/OSLAH_Setup.exe`.*

---

## 🧠 Local Brain Selection Matrix

When setting up OSLAH, you can choose and download the local LLM model weights matching your hardware profiles:

| Model Option | Parameters | Core Strengths (PROS) | Drawbacks (CONS) | Malayalam Support | CPU / RAM Profile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DeepSeek-R1** | `7B` | 🧠 Logical step-by-step thinking (`<think>` tags). Excellent math & coding capabilities. | ⏳ Slower initial token stream due to reasoning cycles. | **Excellent** 🌟 (Superb translations & comprehension) | Moderate-High (8GB+ RAM / VRAM) |
| **Llama 3** | `8B` | 💬 Highly conversational, fast streams. Extremely robust general knowledge base. | 🌐 Lacks native reasoning outputs. | **Basic** ⚠️ (English is highly preferred) | Moderate-High (8GB+ RAM / VRAM) |
| **Phi-3** | `3.8B` | ⚡ Ultra-lightweight & fast. Runs efficiently on basic laptop CPU configurations. | 📉 Limited reasoning scope. Smaller context. | **Poor** ❌ (Basic vocabulary matching only) | Low-Lightweight (4GB+ RAM / VRAM) |

---

## 🔒 Security & Sandboxing

OSLAH is designed with local enterprise security compliance in mind:
*   Incoming requests outside the host require a valid API header token: `X-OSLAH-Key` or `Authorization: Bearer <API_KEY>`.
*   Access rules are verified by the internal role-based middleware (`Admin` vs `Employee` keys).
*   Incoming payloads are parsed using a strict sequential queue to prevent local memory overflow or CPU exhaustion DOS attacks.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. Custom Enterprise modules are subject to commercial licensing terms.

---
**BeezyMan Studio Kerala**
