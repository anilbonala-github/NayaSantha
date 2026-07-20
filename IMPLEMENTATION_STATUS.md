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

## Remaining phases (Vol2 §15)
- **P1 finish**: wire the Flutter **login/OTP screens** to `authControllerProvider`
  (replace mock `AppState` auth), plus profile/address screens → their repositories.
- **P2 Catalogue**: categories, products, prices, search, basket persistence.
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
