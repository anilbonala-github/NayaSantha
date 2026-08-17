# NayaSantha — Delivered Functionality

Every customer screen runs off the live backend — no mock data. Prices, totals, the
guaranteed-maximum cap, coupons, wallet, perks and payment capture are all computed
server-side.

**At a glance:** 14 customer feature areas · 8 ops/admin sections · 20 DB migrations (V1–V20) ·
3 platforms (Android, iOS, Web).

Status legend: ✅ live in production · 🟡 built, final setup step remaining.

---

## Customer app

### 👤 Accounts & onboarding
- ✅ OTP mobile login — JWT access + refresh rotation, logout
- ✅ Guided onboarding — profile, family members (diet + allergies), address
- ✅ Weekly budget & price consent — stored per household
- ✅ Kitchen staples — seeds the pantry; one-time completion
- ✅ Address serviceability — community capture for delivery waves

### 🛒 Catalogue, basket & search
- ✅ Categories & products — paginated, searchable, Hyderabad seed
- ✅ Product detail & search
- ✅ Persistent basket — server-recalculated totals
- ✅ Basket badge & quick-add in the app shell

### ✨ AI weekly plan & assistant
- ✅ AI weekly grocery plan — validated against SKUs, allergies, diet, budget
- ✅ 4 price-preference options — audited consent
- ✅ Estimated total + guaranteed maximum payable
- ✅ AI assistant chat — catalogue + weekly-model context
- ✅ Deterministic fallback planner — works with no AI key

### 📊 Weekly market pricing & settlement
- ✅ Guaranteed-maximum model — cap = round-up(estimate × 1.025)
- ✅ Sunday price capture & settlement
- ✅ Within-cap auto-charge — captures only the final amount
- ✅ Over-cap approval flow — accept / remove-expensive / cancel
- ✅ Estimate-vs-actual bill — per item + savings

### 💳 Payments, wallet & refunds
- ✅ Razorpay checkout — web (`checkout.js`) + native mobile
- ✅ Real refunds — full/partial, to source or wallet
- ✅ Wallet + ledger — balance and transaction history
- ✅ Pay-from-wallet at checkout — part or full; gateway charges the remainder

### 🎟️ Coupons & offers
- ✅ Coupon catalogue — browse, copy code
- ✅ Apply / remove at checkout — flat & percent with caps
- ✅ Usage rules — min basket, per-user & global limits
- ✅ New-household & members-only offers

### ⭐ Membership & perks
- ✅ Plans — Basic / Plus / Family; subscribe, switch, cancel
- ✅ Recurring wallet billing — month 1 + monthly renewals
- ✅ Past-due retry → expire after 3 failed attempts
- ✅ Billing history
- ✅ Enforced perks — free delivery, member-only offers, priority delivery slot

### 🎁 Referrals, recipes & insights
- ✅ Referrals — code + apply, bonus credited to both wallets
- ✅ Recipes — add all ingredients to the basket in one tap
- ✅ Budget insights — spend trend, category breakdown
- ✅ Savings & within-budget rate

### 🥫 Pantry & orders
- ✅ Pantry CRUD — backend-computed low-stock & expiry
- ✅ Orders list & detail
- ✅ Full fulfillment lifecycle — confirmed → packed → out-for-delivery → delivered

### 🔔 Notifications & push
- ✅ In-app inbox — unread badge, mark-read
- ✅ Lifecycle alerts — order, payment, refund, delivery, referral
- ✅ Device registry — register / refresh / unregister tokens
- ✅ Push notifications (FCM) — **Android live**; web wired; 🟡 iOS in final signing step

---

## 🏪 Ops / Admin portal (admin-only)

The team's Sunday procurement & fulfillment console.

- ✅ **Dashboard** — confirmed orders, estimated GMV, items-to-purchase, price alerts
- ✅ **Order cutoff console** — status counts + over-cap exceptions queue
- ✅ **Market purchase list** — consolidated buy list, buffer, buy qty, max rate, CSV export
- ✅ **Price capture** — forecast → actual, variance flagging, publish = finalize
- ✅ **Packing** — waves grouped by community
- ✅ **Delivery** — dispatch, mark-delivered, refunds
- ✅ **Reports** — GMV, within-cap rate, exception rate, refunds
- ✅ **Settings** — buffer %, cap %, variance threshold, delivery slot & fee, priority slot

---

## ⏱️ Automation & scheduling

Cron jobs with admin manual triggers as a fallback.

- ✅ Saturday 8 PM reminder — nudge un-approved households
- ✅ Saturday 10 PM cutoff — lock confirmed orders for procurement
- ✅ Daily subscription billing — renew memberships from the wallet
- ✅ Manual admin triggers — run any of the above on demand

---

## Platforms

- ✅ **Web** — live at nayasantha.com
- ✅ **Android** — build + push verified on a real device
- 🟡 **iOS** — app builds & ships to TestFlight; push pending the final APNs/signing step

_See [`TECH_STACK.md`](TECH_STACK.md) for the technology stack and rationale._
