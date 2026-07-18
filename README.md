# NayaSantha — Customer App

Your AI-Powered Weekly Market. One Flutter codebase targeting **Web, Android and iOS**,
implementing Volume 2 (Customer Applications) of the NayaSantha PRD.

## Status

All 29 screens from Volume 2 are implemented against a mock data layer, so the app
runs end to end today with no backend. Payments, OTP and AI responses are simulated
and clearly marked in code.

## Prerequisites

- Flutter **3.27 or newer** (the code uses `Color.withValues`)
- Xcode 15+ for iOS, Android Studio / SDK 34+ for Android

## Getting started

This repo contains `lib/`, `web/`, `assets/` and `pubspec.yaml`. Generate the native
platform folders once — `flutter create` will not overwrite existing files:

```bash
cd naya_santha
flutter create . --platforms=android,ios,web --org com.nayasantha
flutter pub get
```

Then run on whichever target you want:

```bash
flutter run -d chrome      # web
flutter run -d android     # Android device or emulator
flutter run -d ios         # iOS simulator (macOS only)
```

Release builds:

```bash
flutter build web --release          # build/web — deploy to any static host
flutter build appbundle --release    # Play Store
flutter build ipa --release          # App Store (macOS only)
```

## Architecture

```
lib/
  main.dart                  App entry, provider wiring
  core/
    theme/                   Brand colours, spacing scale, Material 3 theme
    router/                  Route constants + go_router config
    widgets/                 Design system: cards, chips, steppers, app shell
  data/
    models.dart              Domain models
    mock_data.dart           Seed catalogue and household data
  state/
    app_state.dart           Session, family, plan, basket, orders, wallet
    assistant_state.dart     AI chat state
  features/                  The 29 screens, grouped by flow
```

**Responsive strategy.** `AppShell` picks navigation chrome by viewport width:
below 1100 px it renders a bottom navigation bar plus a floating basket button;
at or above 1100 px it renders the persistent left sidebar and top search bar
from the desktop mockup. Page content is width-constrained by `PageBody` so wide
monitors do not stretch layouts.

**Deep links.** Every screen has a real URL (`/plan`, `/product/p_tomato`,
`/track/NS125687`), so the web build supports refresh, back/forward and sharing.

## Screen map

| # | Screen | Route | File |
|---|--------|-------|------|
| 01 | Splash | `/` | `features/auth_screens.dart` |
| 02 | Welcome | `/welcome` | `features/auth_screens.dart` |
| 03 | Login | `/login` | `features/auth_screens.dart` |
| 04 | OTP verification | `/otp` | `features/auth_screens.dart` |
| 05 | Registration | `/register` | `features/auth_screens.dart` |
| 06 | Family profile | `/onboarding/family` | `features/onboarding_screens.dart` |
| 07 | Address | `/onboarding/address` | `features/onboarding_screens.dart` |
| 08 | Dietary preferences | `/onboarding/dietary` | `features/onboarding_screens.dart` |
| 09 | AI kitchen setup | `/onboarding/kitchen` | `features/onboarding_screens.dart` |
| 10 | Dashboard | `/home` | `features/home_screen.dart` |
| 11 | AI weekly plan | `/plan` | `features/weekly_plan_screen.dart` |
| 12 | Basket review | `/basket` | `features/shopping_screens.dart` |
| 13 | Product details | `/product/:id` | `features/shopping_screens.dart` |
| 14 | Search | `/search` | `features/shopping_screens.dart` |
| 15 | Categories | `/categories` | `features/shopping_screens.dart` |
| 16 | Checkout | `/checkout` | `features/checkout_screens.dart` |
| 17 | Payment | `/payment` | `features/checkout_screens.dart` |
| 18 | Order success | `/order-success/:id` | `features/checkout_screens.dart` |
| 19 | Delivery tracking | `/track/:id` | `features/checkout_screens.dart` |
| 20 | AI assistant | `/assistant` | `features/lifestyle_screens.dart` |
| 21 | Pantry | `/pantry` | `features/lifestyle_screens.dart` |
| 22 | Recipes | `/recipes` | `features/lifestyle_screens.dart` |
| 23 | Budget insights | `/budget` | `features/lifestyle_screens.dart` |
| —  | Offers | `/offers` | `features/offers_screen.dart` |
| 24 | Subscription | `/subscription` | `features/account_screens.dart` |
| 25 | Notifications | `/notifications` | `features/account_screens.dart` |
| 26 | Wallet | `/wallet` | `features/account_screens.dart` |
| 27 | Referral | `/referral` | `features/account_screens.dart` |
| 28 | Profile | `/profile` | `features/account_screens.dart` |
| 29 | Settings | `/settings` | `features/account_screens.dart` |

Plus an order history screen at `/orders`, reachable from the sidebar and profile.

## Second pass (detailed mockup)

Added after the annotated screenshot:

- **Product ratings and trust badges** — `rating`, `ratingCount` and `badges`
  ("Farm Fresh", "No Chemicals") on `Product`, shown on both the grid card and
  the product page.
- **Pantry stock levels** — a `StockLevel` enum drives Low Stock chips, alongside
  the existing expiry tracking. A second **Smart suggestions** tab lists only
  items that are running low or about to spoil, each with the reason shown and a
  one-tap Add.
- **Actionable AI replies** — `ChatMessage` now carries an optional numbered list
  and a `ChatAction`. "Add ingredients to cart" actually adds the five products
  behind the suggested dinner; other replies deep-link to the plan, pantry,
  budget or order tracking.
- **Weekly plan context** — a family avatar strip under the headline (quantities
  are meaningless without knowing who they are for) and a Top recommendations
  rail for items the planner considered but did not add.
- **Offers screen** — promo codes with copy-to-clipboard, live price drops, and
  the referral cross-link, wired into the sidebar.

## Connecting the Spring Boot backend

Every network-shaped call lives in `state/app_state.dart` and
`state/assistant_state.dart`, each marked with the endpoint it should become.
Replace the method bodies; no widget code changes.

| Method | Endpoint |
|---|---|
| `requestOtp` | `POST /api/auth/otp/request` |
| `verifyOtp` | `POST /api/auth/otp/verify` → JWT |
| `generatePlan` | `POST /api/ai/plan/generate` |
| `placeOrder` | `POST /api/orders` |
| `search` | `GET /api/products?q=&category=` |
| `AssistantState.send` | `POST /api/ai/chat` |

## Security notes carried into the code

- **No card data touches this app.** The payment screen selects a method and hands
  off; in production, invoke the Razorpay SDK, which renders its own PCI-compliant
  sheet. NayaSantha receives only a token and a result.
- **No model API key in the client.** The Gemini key belongs on the Spring Boot
  side, behind `/api/ai/*`. Shipping it in a mobile binary makes it extractable.
- Allergies are modelled as hard exclusions, not soft preferences, because getting
  this wrong has real consequences for a household.

## What is mocked

- OTP accepts any 6 digits
- Payment always succeeds after a short delay
- AI replies are deterministic canned responses in `assistant_state.dart`
- Catalogue, pantry, orders and wallet come from `data/mock_data.dart`
- Product imagery uses emoji tiles; swap `ProduceAvatar` for `Image.network` once
  the CDN is live

## Not yet built

Vendor portal, farmer portal, delivery app and admin portal (Volumes 3 and 4) are
separate applications and are not part of this codebase.
