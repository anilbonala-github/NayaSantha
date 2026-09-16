# NayaSantha API (Spring Boot + PostgreSQL)

The dynamic backend for NayaSantha — the **system of record** for users, households,
addresses, catalogue, plans, baskets, orders and payment state.
Flutter is only a client; this service owns validation, prices, totals, consent and
payments (Vol1 §11, Vol2 §2–3).

## Stack
Java 17 · Spring Boot 3.3 · Spring Data JPA · Flyway · Spring Security (JWT) ·
springdoc-OpenAPI · PostgreSQL.

## Core account endpoints
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

## Household, weekly pricing and checkout

The API includes household setup, catalogue, recipes, plans, a persistent basket,
reviewed checkout, orders and operator fulfilment. Confirmed `FIXED_WEEKLY` orders
retain their selling prices when procurement costs change.

- `GET /api/v1/baskets/current/checkout-preview` returns the address, prices,
  delivery fee, total and review token.
- `POST /api/v1/baskets/current/checkout` accepts `basketId` and `quoteToken`.
  Changed items/prices/address/fees require another review. Retrying the same
  checked-out basket returns its existing order.
- `POST /api/v1/weekly-plans/{id}/add-to-basket` imports a draft plan once.
- Administrator-only `POST /api/v1/ops/selling-prices/publish` schedules weekly
  selling prices. Existing orders keep their snapshots.

## Database verification

`mvn test` runs the unit tests and `DatabaseCheckoutTest`. The latter starts an
isolated real PostgreSQL process on a random local port using a test dependency;
it does not use `.env`, Neon or a shared database. Docker is not required. The
first run downloads platform binaries through Maven. Run as a normal user
(PostgreSQL cannot initialize as root on Linux).

The integration fixture first migrates an empty database to V20, then starts
Spring Boot to apply V21/V22 and validate the Hibernate mappings. Tests exercise
checkout persistence, duplicate retries, stale reviews and authenticated household
and order requests. To run just these checks:

```
mvn -Dtest=DatabaseCheckoutTest test
```

## Hosted database and rollout

1. Check the hosted API and database separately. `/api/v1/ping` is only process
   liveness; it does not query PostgreSQL. A timed-out API does not prove the
   database is down.
2. In Render, verify the service status and startup logs and compare its three
   `SPRING_DATASOURCE_*` values with the intended Neon endpoint. Keep credentials
   in secret environment variables. Spring Boot does **not** automatically load
   `backend/.env`; export those values or configure them in the IDE/hosting UI.
3. Before upgrading a shared database, take a provider snapshot/backup and verify
   Flyway history. Do not edit already-applied migration files or use `repair`
   to silence an unexplained checksum mismatch.
4. Test this branch against an isolated database first. V21 adds fixed pricing
   fields/calendar; V22 links an order uniquely to its basket. Both are additive.
   Existing orders remain `LEGACY_VARIABLE`.
5. Deploy the backend with the intended database environment. Flyway applies
   pending migrations at startup; Hibernate then validates the schema. Verify
   migrations 21/22 succeeded and test an authenticated request before releasing
   the matching frontend.
6. Exercise Razorpay **test mode** separately. Missing gateway configuration now
   blocks online payment instead of simulating a successful charge. Real SMS OTP
   and payment-provider verification remain release requirements.

Changes on a feature branch do not update the live deployment. The repository's
frontend workflow deploys on `main`; coordinate backend and frontend releases.
