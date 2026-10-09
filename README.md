# LoopServe 3.0 — Track A: Advanced Restaurant Operations System

> **Loopverse 3.0 Virtual App Development Challenge**  
> Visual Concept: **EMBER** — Modern Fine Dining Meets Cinematic Digital Craftsmanship

---

## 🌟 Quick Start Guide

### Prerequisites
- Flutter SDK `^3.44.4` (Dart `^3.12.2`)
- Python `3.10+`

---

### 1. Run Backend Server (FastAPI + Supabase)
Start the live backend server on `http://localhost:8080`:

```bash
# 1. Start FastAPI backend with live WebSockets
python run_backend.py
```

To run the automated backend concurrency test suite (validating the non-negotiable constraints, race condition prevention on dish `d5`, idempotency, and cancellation conflicts):

```bash
python -m backend.test_backend
```

---

### 2. Run Frontend Application (Flutter)
Run the application locally in Web or Desktop mode:

```bash
# Run in Chrome Web Browser
flutter run -d chrome

# Or run Windows Desktop build
flutter run -d windows
```

---

### 3. Run Automated Flutter Test Suite
Execute unit and widget tests:

```bash
flutter test
```

---

## 🛠️ Operating Modes & Presentation Controls

The application includes a persistent **Mode Switcher Bar** rendered at the top of the viewport:

1. **Development Fixture Mode**: Uses deterministic seeded fine-dining menu items, active tickets, and portion inventory. Allows isolated UI demonstration without requiring an active backend server.
2. **Connected Backend Mode**: Connects to the live FastAPI server (`http://localhost:8080/api/v1`), Supabase database, and WebSocket event stream (`ws://localhost:8080/ws`).
3. **Role Switcher (`Customer View` vs `Staff Operations`)**: Seamlessly toggles between the Customer Ordering Journey and the Staff Kitchen Operations Console during hackathon presentation.

---

## 📚 Documentation Index
- [`docs/BACKEND_INTEGRATION.md`](file:///d:/loopverse/docs/BACKEND_INTEGRATION.md): Complete backend integration guide & API contract.
- [`docs/FRONTEND_ARCHITECTURE.md`](file:///d:/loopverse/docs/FRONTEND_ARCHITECTURE.md): State flow, Riverpod providers, & 3D canvas architecture.
- [`docs/REQUIREMENTS_TRACEABILITY.md`](file:///d:/loopverse/docs/REQUIREMENTS_TRACEABILITY.md): Mapping of all Track A prompt requirements to code.
- [`docs/DEVELOPMENT_STATUS.md`](file:///d:/loopverse/docs/DEVELOPMENT_STATUS.md): Current status matrix of all requirements.
- [`docs/TEST_REPORT.md`](file:///d:/loopverse/docs/TEST_REPORT.md): Automated test execution report.
- [`docs/DEMO_SCRIPT.md`](file:///d:/loopverse/docs/DEMO_SCRIPT.md): Step-by-step hackathon presentation guide.
