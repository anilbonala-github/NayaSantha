# NayaSantha — Dynamic Implementation Status

Tracking the Volume 2 refactor from a static mock Flutter app to a dynamic
Spring Boot + PostgreSQL product. Business data must come from APIs, not Flutter
constants (Vol1 §11, Vol2 §2). Legacy mock screens still run until each is migrated.

## Architecture
```
Flutter (Dio + Riverpod)  ──HTTPS──►  Spring Boot /api/v1  ──►  PostgreSQL (system of record)
   secure token store                  JWT auth, Flyway            + Redis cache (later)
   loading/empty/error/offline         validation & totals        Google Gemini = advice only
```
Monorepo: `backend/` (Java) beside the Flutter app (repo root).

## Phase 1 — Foundation ✅ (auth + profile/household + address)
- **Backend** (`backend/`, compiles): Flyway migrations for the core tables
  (UUID PKs, UTC timestamps, optimistic-lock `version`, DB constraints); auth
  (OTP dev-stub, JWT + refresh rotation, logout); profile/household/members CRUD;
  address CRUD + serviceability; stable response/error envelope; OpenAPI/Swagger.
- **Flutter**: `core/api` Dio client (envelope unwrap, bearer token,
  refresh-on-401), secure `TokenStore`, typed `ApiFailure`; `features/auth`
  Riverpod controller wired to the backend. App wrapped in `ProviderScope`.

### To run Phase 1 (you)
1. Create a free Postgres at **neon.tech**, put its JDBC URL + user/pass in
   `backend/.env` (see `backend/.env.example`).
2. `cd backend && mvn spring-boot:run` → Swagger at http://localhost:8080/swagger-ui.html.
3. Run the app against it: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
   (Android emulator: use `http://10.0.2.2:8080`).

## Phase 2 — Catalogue + basket ✅ (backend + Flutter data layer)
- **Backend** (verified vs Neon): categories, products (paginated, category+query
  filters), product detail, search suggestions — each product carries its current
  price + effective version; persistent basket with server-recalculated **estimate +
  guaranteed maximum** and optimistic locking. Seeded 18-product Hyderabad catalogue.
- **Flutter**: `features/catalogue` + `features/basket` Riverpod repositories/providers
  consuming the API. **Next**: wire the catalogue grid / product page / basket screens
  to these providers (replace the mock `AppState` catalogue + basket).

## Phase 3 — Pantry + AI weekly plan + Gemini ✅ (backend + Flutter data layer)
- **Backend** (verified vs Neon): pantry CRUD with **backend-computed** low-stock +
  expiry status; **AI weekly plan** where Gemini *proposes* from sanitized household
  context and the service is the deterministic authority — validates every SKU,
  enforces allergies (peanut→groundnut synonym) + dietary + budget, recomputes
  trusted prices, persists estimate + guaranteed max. Rule-based **fallback** runs
  when `GEMINI_API_KEY` is unset (set it to enable real Gemini; validation stays server-side).
- **Flutter**: `features/pantry` + `features/plan` Riverpod repositories/providers.
- Verified: pantry LOW/EXPIRING status; plan estimate ₹1481 ≤ budget ₹1500; Groundnut
  Oil excluded for a peanut allergy.

## Phase 4 — Pricing consent + Sunday settlement ✅ (backend, per Volume 2A)
- **Backend** (verified vs Neon): the Estimated + **Guaranteed Maximum** + Final
  Settlement model. Plan max = `RoundUpTo5(estimate × 1.025)`. Approve stores an
  audited **price consent** (4 substitution preferences) + snapshots an **order** +
  a UPI-Autopay-style **authorization** of the cap. Sunday settlement (dev-simulated
  market prices): within cap → auto-capture; over cap → **price exception** +
  customer decision (accept / remove-expensive / cancel); capture charges only the
  final amount. Endpoints per Vol2A §11 (approve, lock, price-decision, capture,
  price-comparison, orders).
- Verified: formula, within-cap capture (charged ₹1494 ≤ ₹1520 cap), and over-cap
  path (₹1502 market → trimmed to ₹558 under a ₹600 cap). Customer never charged above cap.
- **Flutter data layer**: TODO (orders/consent repository + providers) — next.

## Remaining
- **Flutter data layer** for Phase 4 orders/consent, then **UI wiring** for all
  phases (catalogue/basket/pantry/AI-plan/consent/final-bill screens → providers;
  auth already migrated).
- **Ops/admin portal** (Vol3): real Sunday procurement + price capture (currently
  dev-simulated), packing/dispatch. Real payment provider + FCM notifications.
- Redis (cutoff timers), object storage (invoices/bills), offline sync, tests.
- **P3 Pantry + Weekly Plan**: household preferences, pantry, AI plan (Gemini,
  validated server-side).
- **P4 Pricing consent + Saturday cutoff** — needs the **Volume 2A** pricing doc
  (estimate + guaranteed maximum + Sunday settlement).
- **P5 Checkout / payments / orders / notifications**.
- **P6 Offline cache (Drift), analytics, security hardening, responsive web**.
- **P7 End-to-end tests + pilot release**.

## Definition of done (per screen, Vol2 §16)
Real endpoint · migration + constraints · documented API contract ·
loading/empty/error/offline states · authz + validation tests · widget +
repository tests · backend unit + integration tests · no hard-coded business
data · analytics + audit events.

## Infra notes
- **Hostinger shared hosting can only serve the static Flutter web build** — it
  cannot run Java or Postgres. The backend needs a PaaS (Railway/Render/Fly) +
  managed Postgres before the dynamic web/app work in production.
- Backend build tool isn't installed globally; run via an IDE (IntelliJ/Android
  Studio) or install Maven. CI for the backend is a later addition.
