# LoopServe 3.0 — Track A: Advanced Restaurant Operations System

> **Loopverse 3.0 Virtual App Development Challenge**  
> Visual Concept: **EMBER** — Modern Fine Dining Meets Cinematic Digital Craftsmanship

---

## 🌟 Quick Start Guide

### Prerequisites
- Flutter SDK `^3.44.4` (Dart `^3.12.2`)
- Node.js `^v24.18.0` / npm `^11.16.0`

### 1. Run Application
Run the application locally in Web or Desktop mode:

```bash
# Run in Chrome Web Browser (Recommended for 3D Studio WebGL engine)
flutter run -d chrome

# Or run Windows Desktop build
flutter run -d windows
```

### 2. Run Automated Test Suite
Execute unit and widget tests:

```bash
flutter test
```

### 3. Build Web Release
Generate production bundle:

```bash
flutter build web --release
```

---

## 🛠️ Operating Modes & Presentation Controls

The application includes a persistent **Mode Switcher Bar** rendered at the top of the viewport:

1. **Development Fixture Mode**: Uses deterministic seeded fine-dining menu items, active tickets, and portion inventory. Allows isolated UI demonstration without requiring an active backend server.
2. **Connected Backend Mode**: Connects to live REST API endpoints (`http://localhost:8080/api/v1`) and WebSocket event stream (`ws://localhost:8080/ws`).
3. **Role Switcher (`Customer View` vs `Staff Operations`)**: Seamlessly toggles between the Customer Ordering Journey and the Staff Kitchen Operations Console during hackathon presentation.

---

## 📚 Documentation Index
- [`docs/BACKEND_INTEGRATION.md`](file:///C:/Users/Hassan/OneDrive/Desktop/VerseLoop/docs/BACKEND_INTEGRATION.md): Complete backend integration guide & API contract.
- [`docs/FRONTEND_ARCHITECTURE.md`](file:///C:/Users/Hassan/OneDrive/Desktop/VerseLoop/docs/FRONTEND_ARCHITECTURE.md): State flow, Riverpod providers, & 3D WebGL bridge architecture.
- [`docs/REQUIREMENTS_TRACEABILITY.md`](file:///C:/Users/Hassan/OneDrive/Desktop/VerseLoop/docs/REQUIREMENTS_TRACEABILITY.md): Mapping of all Track A prompt requirements to code.
- [`docs/DEVELOPMENT_STATUS.md`](file:///C:/Users/Hassan/OneDrive/Desktop/VerseLoop/docs/DEVELOPMENT_STATUS.md): Current status matrix of all 12 stages.
- [`docs/TEST_REPORT.md`](file:///C:/Users/Hassan/OneDrive/Desktop/VerseLoop/docs/TEST_REPORT.md): Automated test execution report.
- [`docs/DEMO_SCRIPT.md`](file:///C:/Users/Hassan/OneDrive/Desktop/VerseLoop/docs/DEMO_SCRIPT.md): Step-by-step hackathon presentation guide.
