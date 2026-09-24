# Catalogue and staff portal

## Delivered in this phase

- Responsive customer catalogue, search, category filters, pagination, product photo support, detail navigation and quantity controls.
- `/admin/login` mobile verification form and `/admin` catalogue dashboard.
- Owner-only staff assignment; catalogue managers can manage categories, products, uploaded photos and weekly prices.
- Product drafts, publishing and archiving; out-of-stock products cannot be added or checked out. Each pack size uses a separate SKU.
- Initial selling price is set once; later changes go through the existing future-Monday price batch. Confirmed orders remain unchanged.
- Validated PNG/JPEG uploads: at most 1 MB input / 12 megapixels, re-encoded on the server. Images are stored persistently in PostgreSQL for the pilot. Move image bytes to object storage before a larger catalogue rollout.
- Product/category/staff changes record the acting user in admin_audit.
- Migration V23 extends roles, catalogue publication/availability, image storage, audit records and staff-session verification.

## Authentication prerequisite

The current backend has no real SMS sender. Production/staff OTP requests deliberately fail with a clear setup message; dummy OTPs never grant admin permissions. OWNER_MOBILE is a private deployment setting, and a matching account becomes OWNER only after real OTP verification. A designated number by itself is not proof of identity.

Staff access checks the current database role and role version on every request. Role changes revoke refresh sessions. Old access tokens remain invalid even after the role is later restored. Refresh cannot turn a dummy-OTP session into a verified staff session.

To activate staff login, integrate the selected SMS provider, configure its credentials and sender/template settings, set OWNER_MOBILE in Render, then disable OTP_DEV_MODE and verify delivery before enabling staff use. Do not disable the staff guard as a workaround.

## Release sequence

1. Run backend `mvn verify` and focused Flutter tests.
2. Back up the shared database and deploy backend V23.
3. Verify customer API compatibility and denial of customer/dummy-OTP staff requests.
4. Deploy web from the same branch, then build iOS.
5. Complete real SMS integration before onboarding the owner and catalogue staff.

## Later phases

This release supports one role per account. Multi-role staff membership, delivery assignments, inventory quantities/reservations, category archiving, multiple photos per product, customer reviews and owner MFA remain future work. ORDER_MANAGER and DELIVERY_STAFF are reserved roles, not options in staff assignment in this phase.
