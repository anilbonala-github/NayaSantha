# NayaSantha API (Spring Boot + PostgreSQL)

The dynamic backend for NayaSantha — the **system of record** for users, households,
addresses (and, in later phases, catalogue, plans, baskets, orders, payments).
Flutter is only a client; this service owns validation, prices, totals, consent and
payments (Vol1 §11, Vol2 §2–3).

## Stack
Java 17 · Spring Boot 3.3 · Spring Data JPA · Flyway · Spring Security (JWT) ·
springdoc-OpenAPI · PostgreSQL.

## Phase 1 scope (implemented)
- **Auth** — `POST /api/v1/auth/otp/request`, `/otp/verify`, `/refresh`, `/logout`
  (OTP is dev-stubbed until an SMS provider is wired; verify with code `000000`).
- **Profile / household / members** — `GET|PATCH /api/v1/profile`,
  `GET|PATCH /api/v1/households/current`, `POST|PATCH|DELETE /api/v1/household-members`.
- **Address + serviceability** — CRUD `/api/v1/addresses`, `GET /api/v1/serviceability?pincode=`.
- **Health** — `GET /api/v1/ping` (public).

Every table has a Flyway migration (`src/main/resources/db/migration`), UUID PKs,
UTC timestamps, optimistic-lock `version`, and DB constraints.

## 1. Provision a Postgres database (cloud, no local install)
1. Sign up at **neon.tech** (or supabase.com) → create a project → copy the
   connection string, e.g. `postgresql://user:pass@ep-xxx.aws.neon.tech/neondb?sslmode=require`.
2. Convert it to JDBC and split credentials into `.env` (copy from `.env.example`):
   ```
   SPRING_DATASOURCE_URL=jdbc:postgresql://ep-xxx.aws.neon.tech/neondb?sslmode=require
   SPRING_DATASOURCE_USERNAME=user
   SPRING_DATASOURCE_PASSWORD=pass
   ```
Flyway creates the schema automatically on first start.

## 2. Run
Java 17 is required. Using the bundled Maven or your own:
```
# with env vars exported (or set them in your IDE run config)
mvn spring-boot:run
```
Then open **http://localhost:8080/swagger-ui.html** for the live API docs and an
`Authorize` button (paste a JWT from `/auth/otp/verify`).

Quick smoke test:
```
curl localhost:8080/api/v1/ping
curl -X POST localhost:8080/api/v1/auth/otp/request -H 'Content-Type: application/json' -d '{"mobile":"9876543210"}'
curl -X POST localhost:8080/api/v1/auth/otp/verify  -H 'Content-Type: application/json' -d '{"mobile":"9876543210","code":"000000"}'
```

## Not yet (later phases)
Catalogue/search, weekly plan (Gemini), basket + pricing consent, Saturday cutoff,
checkout/payments, orders, notifications, Redis cache, offline sync. See Vol2 §15.
Real SMS OTP and Google sign-in replace the dev OTP stub.
