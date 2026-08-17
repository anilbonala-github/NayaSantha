# NayaSantha — Technology Stack

AI-powered weekly grocery market (Hyderabad apartment pilot). A **Flutter** client for
Android, iOS and Web talks to a **Spring Boot + PostgreSQL** backend. All business logic —
prices, totals, the guaranteed-maximum cap, coupons, wallet, perks and payment capture — is
computed **server-side**; Google Gemini only recommends and explains.

```
Flutter app (Android / iOS / Web)
      │  REST (JSON, JWT)
      ▼
Spring Boot API (Render, Docker) ──► PostgreSQL (Neon)
      │                        └────► Google Gemini   (AI plans / assistant)
      │                        └────► Firebase FCM     (push notifications)
      │                        └────► Razorpay          (payments / refunds)
      │
  Web → Hostinger (GitHub Actions)   Mobile → Codemagic (Play / TestFlight)
```

---

## Frontend — Flutter app

| Technology | Version | Purpose | Why we chose it |
|---|---|---|---|
| **Flutter / Dart** | Dart ≥ 3.3 | One codebase for Android, iOS & Web | Ship three platforms from a single codebase — fastest path for a small team, with native-grade performance |
| **go_router** | 14.2 | Declarative routing & navigation shell | Official router; URL-based routes work for web deep-links and mobile alike |
| **Riverpod** (`flutter_riverpod`) | 2.6 | State management for backend-backed features | Compile-safe, testable, no `BuildContext` coupling; clean handling of async API data |
| **Dio** | 5.7 | HTTP client | Interceptors give us JWT injection + automatic refresh-on-401 and a uniform error/envelope layer |
| **flutter_secure_storage** | 9.2 | Auth token storage | Keeps tokens in the platform keystore/keychain — never in shared prefs or logs (security requirement) |
| **firebase_core / firebase_messaging** | 3.6 / 15.1 | Push notifications (FCM) | One SDK covers Android, iOS and Web push on a free tier |
| **razorpay_flutter** | 1.3 | Native Razorpay checkout (mobile) | Official native checkout for India (UPI / cards / netbanking); web uses `checkout.js` |
| **provider** | 6.1 | Legacy state (un-migrated screens) | Already in place; retained for a few screens pending migration to Riverpod |
| **intl** | 0.19 | Currency & date formatting | Standard i18n/formatting for ₹ amounts and dates |

---

## Backend — REST API

| Technology | Version | Purpose | Why we chose it |
|---|---|---|---|
| **Java + Spring Boot** | 17 / 3.3.5 | Application framework (Maven) | Mature, batteries-included, huge ecosystem; excellent for transactional money logic |
| **Spring Web** | 3.3.5 | REST controllers + JSON envelope | First-class REST support and validation |
| **Spring Data JPA + Hibernate** | 3.3.5 | ORM over PostgreSQL | Rapid CRUD with relational integrity for orders, payments, wallet |
| **Spring Security + JWT** (jjwt) | 0.12.6 | Auth & authorization | Stateless OTP login (access + refresh tokens) and role-gated ops portal |
| **Flyway** | 10.x | Versioned DB migrations (V1–V20) | Repeatable, ordered schema changes across dev and the shared cloud DB |
| **springdoc-openapi** | 2.6.0 | OpenAPI 3 / Swagger UI | Auto-generated API docs that define the Flutter client contract |
| **Firebase Admin SDK** | 9.3.0 | Server-side FCM push | Sends push to registered devices; matches the client SDK |
| **Lombok** | — | Boilerplate reduction | Less getter/setter/constructor noise in entities and DTOs |

---

## Data & AI

| Technology | Version | Purpose | Why we chose it |
|---|---|---|---|
| **PostgreSQL** | 16+ | Primary data store | Strong consistency for money; UUID keys, constraints, UTC timestamps, optimistic locking |
| **Google Gemini** | `gemini-flash-latest` | AI weekly plans + in-app assistant | Capable and cost-effective with a free tier; used only for recommendations while the backend stays authoritative (deterministic fallback when no key) |

---

## Third-party services & cloud

| Service | Role | Why we chose it |
|---|---|---|
| **Neon** | Managed cloud PostgreSQL | Serverless Postgres with a free tier and instant provisioning — no DB ops overhead |
| **Render** | Backend hosting (Docker) | Simple container deploys for Spring Boot with a free tier and health-gated rollouts |
| **Hostinger** | Web hosting (nayasantha.com) | Low-cost hosting for the static Flutter web build on an already-owned domain |
| **Firebase Cloud Messaging** | Push delivery (Android/iOS/Web) | Free, cross-platform push from a single provider |
| **Razorpay** | Payments — orders, capture, refunds | Leading India gateway (UPI, cards, netbanking) with clean REST + native SDKs |
| **Apple APNs / App Store Connect** | iOS push + TestFlight distribution | Required Apple channel for iOS delivery and testing |
| **Google Play** | Android distribution (internal track) | Required Android channel for staged/internal releases |

---

## DevOps & CI/CD

| Tool | Role | Why we chose it |
|---|---|---|
| **GitHub** | Source control | Single `main` branch; free private repos and Actions |
| **GitHub Actions** | Web CI/CD | Builds the Flutter web app and deploys to Hostinger on every push — free for our volume |
| **Codemagic** | Mobile CI/CD | Flutter-specialised CI with code signing + Play/TestFlight publishing and generous free minutes |
| **Docker** | Backend containerization | Reproducible backend image consumed by Render |

---

## Architecture principles

- **Single source of truth** — all business data (users, products, prices, plans, baskets,
  pantry, orders, payments, wallet, subscriptions) comes from the backend + Postgres; no
  hard-coded business data outside seeds/tests.
- **Server owns money & rules** — prices, totals, the guaranteed-maximum cap, coupon/wallet/
  perk logic and payment capture are computed server-side. Gemini only recommends and explains.
- **Modular monolith** — one Spring Boot app organised by feature packages (catalogue, order,
  wallet, subscription, coupon, ops, push, …), deployable as separate services later if needed.
- **Weekly market model** — Mon AI plan → Sat 10 PM cutoff (estimate + guaranteed max) →
  Sun procurement (actual prices) → final settlement + substitutions → delivery.

---

_See [`FEATURES.md`](FEATURES.md) for the delivered functionality list._
