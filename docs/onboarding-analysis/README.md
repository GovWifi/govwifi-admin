# GovWifi Admin — Administrator Onboarding Journey Analysis

**Date:** 2026-07-08
**Scope:** The administrator sign-up / onboarding journey of the `govwifi-admin` Rails 8 application.
**Method:** App run locally (Docker/Podman, `localhost:8080`), the journey walked end-to-end with a real
account (`Cabinet Office`, gov.uk email, live 2FA), each screen captured, and the source code traced to
confirm behaviour, validation and data storage.

**Contents**

1. [How this was produced](#1-how-this-was-produced)
2. [User journey map](#2-user-journey-map)
3. [Screenshots (step by step)](#3-screenshots-step-by-step)
4. [Data collected](#4-data-collected)
5. [Compliance comparison](#5-compliance-comparison)
6. [Recommendations](#6-recommendations)
7. [Low-fidelity wireframes](#7-low-fidelity-wireframes)
8. [Enforcement strategy — where each rule belongs](#8-enforcement-strategy--where-each-rule-belongs)

---

## 1. How this was produced

- Built and served the app: MySQL 8.4 databases + Rails app container, reachable at `http://localhost:8080`.
  (The `make serve` target's `stop` step fails under `podman-compose` because it calls `docker compose rm`,
  which podman-compose does not implement — see [Recommendation R9](#r9-fix-the-local-dev-make-serve-target-podman).)
- Walked the journey by hand as a genuinely new user: signed up with a `@gov.uk` email, followed the Devise
  confirmation link, set a password + created the organisation, completed **real** two-factor auth using the
  TOTP secret shown on screen, reached the "invite second admin" step, skipped it, and landed on the
  Locations/Settings area.
- Screenshots are in [`screenshots/`](screenshots). The banner reads **"production"** because
  `SITE_CONFIG` defaults that label in dev; this is a local instance.

---

## 2. User journey map

```
                         ADMINISTRATOR ONBOARDING — GovWifi Admin

  [ Landing / Sign in ]                                            (unauthenticated)
        │  "Sign up for a GovWifi administrator account"
        ▼
  ┌─────────────────────┐   email must match gov/public-sector regexp (allowlist from S3)
  │ STEP 1  Sign up      │   ── fail ──▶ inline error, stay on page
  │ Enter email address  │
  └─────────┬───────────┘
            │ create unconfirmed User (email only, no password yet)
            ▼
  ┌─────────────────────┐
  │ STEP 2  Check email  │   Devise confirmable — email is the ONLY way forward
  │ "Confirmation sent"  │   (email delivery via GOV.UK Notify; disabled locally)
  └─────────┬───────────┘
            │ user clicks confirmation link (token)
            ▼
  ┌───────────────────────────────────────────────┐
  │ STEP 3  Create account  (confirmation form)     │  ◀── the pivotal screen
  │  • Organisation name  (dropdown, must be in     │      account + organisation + service
  │    the GOV.UK register allow-list)              │      email are ALL created here
  │  • Service email      (shared mailbox)          │
  │  • Your name                                    │
  │  • Password           (min 6 chars, zxcvbn)     │
  └─────────┬───────────────────────────────────────┘
            │ confirm user, create Organisation + confirmed Membership, sign in
            ▼
  ┌─────────────────────┐   MANDATORY — enforced by ApplicationController before_action
  │ STEP 4  2FA setup    │   scan QR / enter secret into authenticator, verify 6-digit code
  │ TOTP (RFC 6238)      │   ── wrong code ──▶ error, stay on page
  └─────────┬───────────┘
            │ persist otp_secret_key
            ▼
  ┌───────────────────────────────────────────────┐
  │ STEP 5  Invite second administrator             │  "There must be a minimum of 2
  │  • Email of team member                         │   administrators to add IPs or
  │  [ Invite as an admin ]     [ Skip for now ] ───┼──┐  multiple locations."
  └─────────┬───────────────────────────────────────┘  │  ◀── SKIPPABLE at onboarding
            │ invite sent                                │
            ▼                                            ▼
  ┌─────────────────────┐                    ┌───────────────────────────┐
  │ Team members list   │                    │ STEP 6  Locations / Settings │
  └─────────────────────┘                    │  Persistent banner:          │
                                              │  "Your organisation hasn't   │
                                              │   signed the MOU yet"        │
                                              └─────────┬───────────────────┘
                                                        │
              ┌─────────────────────────────────────────┴───────────────┐
              ▼                                                          ▼
  ┌───────────────────────────┐                          ┌───────────────────────────┐
  │ STEP 7a  Sign the MOU       │                          │ STEP 7b  Add a Location     │
  │  Who signs?                 │                          │  • Address                  │
  │   ○ I will sign             │                          │  • Postcode                 │
  │   ○ I will nominate someone │                          │      then  Add up to 5 IPs  │
  │  ▶ Read & Accept terms      │                          │                             │
  │    (name/email/job role +   │                          │  ⚠ BLOCKED until: MOU signed │
  │     "I have authority" ✔)   │                          │     AND ≥ 2 administrators   │
  └───────────────────────────┘                          └───────────────────────────┘

   ══════════════════════════════════════════════════════════════════════════════════
   HARD GATE (LocationsController#authorise_ip_actions): a user CANNOT add IP addresses
   or a second location until BOTH (a) the MOU is signed for the current version, and
   (b) the organisation has ≥ 2 administrators. These are deferred, not enforced inline
   during onboarding — the user only hits the wall when they try to add IPs.
   ══════════════════════════════════════════════════════════════════════════════════
```

### Ordering, and who enforces it

The order is not a linear wizard; it is enforced by `before_action` filters and redirects:

| Guard | Location | Effect |
|---|---|---|
| `authenticate_user!` | `ApplicationController` | Must be signed in for everything except errors/sign-up. |
| `confirm_two_factor_setup` | `ApplicationController` | Signed-in user with no TOTP → forced to **Step 4** (2FA). |
| `redirect_user_with_no_organisation` | `ApplicationController` | User with no confirmed membership → help page. |
| 2FA success branch | `two_factor_authentication_setup_controller` | If org lacks 2 admins → **Step 5** (invite); else stored location. |
| `HomeController#index` | post-login router | No IPs yet → **Settings/initial**; else → Locations. |
| `authorise_ip_actions` | `LocationsController` | Blocks IP / multi-location actions until MOU signed **and** ≥2 admins. |

---

## 3. Screenshots (step by step)

All full-page captures live in [`screenshots/`](screenshots). (A dark horizontal band in some images is the
local `rack-mini-profiler` debug bar, present only in development.)

| # | Screen | File |
|---|---|---|
| 0 | Sign in (entry point) | [`00-sign-in.png`](screenshots/00-sign-in.png) |
| 1 | Sign up — enter email | [`01-signup-email.png`](screenshots/01-signup-email.png) |
| 2 | Check your email (confirmation pending) | [`02-check-your-email.png`](screenshots/02-check-your-email.png) |
| 3 | Create account — blank / filled | [`03-create-account-blank.png`](screenshots/03-create-account-blank.png) · [`03b-create-account-filled.png`](screenshots/03b-create-account-filled.png) |
| 4 | Two-factor authentication setup | [`04-2fa-setup.png`](screenshots/04-2fa-setup.png) |
| 5 | Invite a second administrator (+ filled) | [`05-invite-second-admin.png`](screenshots/05-invite-second-admin.png) · [`05b-invite-second-admin-filled.png`](screenshots/05b-invite-second-admin-filled.png) |
| 6 | After skip → Locations | [`06-after-invite-skip.png`](screenshots/06-after-invite-skip.png) |
| 7 | Settings (account, org, MOU, servers) | [`07-settings.png`](screenshots/07-settings.png) · [`07b-settings-initial.png`](screenshots/07b-settings-initial.png) |
| 8 | Sign the MOU — choose signer | [`08-mou-show-options.png`](screenshots/08-mou-show-options.png) |
| 9 | Sign the MOU — accept terms | [`09-mou-sign.png`](screenshots/09-mou-sign.png) |
| 10 | Nominate someone to sign | [`10-mou-nominate.png`](screenshots/10-mou-nominate.png) |
| 11 | Locations index | [`11-locations-index.png`](screenshots/11-locations-index.png) |
| 12 | Add a location | [`12-location-new.png`](screenshots/12-location-new.png) |
| 13 | Team members | [`13-memberships.png`](screenshots/13-memberships.png) |

---

## 4. Data collected

Traced to `db/schema.rb` and the model files. "Journey step" = where the admin actually enters it.

### Administrator — `users`
| Data | Journey step | Notes / validation |
|---|---|---|
| Email address | Step 1 | Must match gov/public-sector regexp; unique; Devise `confirmable`. |
| Password | Step 3 | Length 6–80, zxcvbn strength check (`devise_zxcvbn`). Hint says only "at least 6 characters". |
| Name | Step 3 | Presence required at confirmation. |
| `otp_secret_key` (encrypted) | Step 4 | TOTP secret; `is_super_admin` default false. |
| Sign-in / security metadata | automatic | `sign_in_count`, `current/last_sign_in_at`, `current/last_sign_in_ip`, `failed_attempts`, `locked_at`, `unlock_token`, `confirmation_token`, `confirmed_at`, invitation fields, `mobile`, `direct_otp`. |

### Organisation — `organisations`
| Data | Journey step | Notes |
|---|---|---|
| Name | Step 3 | Must be in the GOV.UK organisations register allow-list; unique. |
| Service email | Step 3 | "A shared and monitored email"; validated against `Devise.email_regexp`. Editable in Settings. |
| `cba_enabled` | n/a | Feature flag (super admin), not collected during onboarding. |

### Membership — `memberships`
`organisation_id`, `user_id`, `invited_by_id`, `invitation_token`, `confirmed_at`, `can_manage_team`,
`can_manage_locations`. The first admin's membership is auto-confirmed at Step 3.

### MOU — `mous`
`organisation_id`, `user_id`, `version`, `name`, `email_address`, `job_role`, timestamps. The signature is a
**digital attestation** (a checkbox — "I confirm that I have the authority…" — plus typed name/email/job role),
**not** an uploaded signed document. `mou_templates` exists but is empty/unused.

### Nomination — `nominations`
`name`, `email`, `token`, `nominated_by`, `organisation_id`. Created when an admin nominates someone else to sign.

### Location — `locations`
`address` (required), `postcode` (NOT NULL, UK-postcode validated), `organisation_id`, auto-generated
`radius_secret_key`. Address is unique per organisation.

### IP — `ips`
`address` (unique, validated as a real IPv4), `location_id` (NOT NULL, cascade delete). IPs are added ≤5 at a
time and always hang off a Location.

> **Key data-model fact for compliance:** a **physical address lives on the Location**, and every IP belongs to
> exactly one Location. There is **no per-IP address field** — the address is per *location* (a group of IPs),
> not per individual IP/access point.

---

## 5. Compliance comparison

Assessment of the journey against the seven stated requirements.

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | **Signed MOU** | ✅ **Met** (as a gate) | MOU flow exists (`mous`/`nominated_mous`/`nominations`); a persistent banner nags until signed; `authorise_ip_actions` blocks IP/multi-location actions until `resign_mou?` is false. Signing is a digital attestation, not an uploaded document. **Not** part of the linear onboarding — surfaced only via banner/gate. |
| 2 | **Two admins** | 🟠 **Partial** | The 2-admin *minimum* is real and enforced as a **functional gate** (`meets_invited_admin_user_minimum?` → can't add IPs/locations). But the invite step is **skippable** ("Skip for now") and never *completed* is not blocked at onboarding — a lone admin can finish onboarding and even sit indefinitely with one admin until they try to add IPs. Also, an *invited* admin is not a *confirmed* admin until they accept. |
| 3 | **Service email** | ✅ **Met** | Collected at Step 3, mandatory, validated, editable in Settings, exportable by super admins. Hint explains its purpose ("shared and monitored"). No verification that the mailbox is real/monitored. |
| 4 | **Email verification** | ✅ **Met** | Devise `confirmable`; the confirmation link is the *only* path to Step 3. Account literally cannot be created without verifying the email. Resend supported. |
| 5 | **Status page alerts** | 🔴 **Not met (in-app)** | No in-app status feature. The route `resources :status` is declared but has **no controller/view** (dead code — would 500). The only "status page" is an external link (`https://status.wifi.service.gov.uk`) on the Locations page. No alerting/subscription, and it is not part of onboarding. |
| 6 | **Backup SSID plan** | 🔴 **Not met** | No trace of "backup" or "SSID" anywhere in `app/`. No field, guidance, or prompt for a fallback/backup SSID plan. |
| 7 | **Physical address per IP** | 🟠 **Partial** | Address is required per **Location**, not per **IP**. Every IP must belong to a Location that has an address + validated UK postcode — so IPs are covered by *an* address, but multiple IPs share one location address and there is no address captured against the individual IP/access point. |

**Summary:** 3 met, 3 partial, 1–2 not met. The strongest areas are email verification and service email
(both baked into account creation). The weakest are the missing status-alerts and backup-SSID concepts, and the
"two admins" requirement being deferrable rather than guaranteed.

---

## 6. Recommendations

Ordered by compliance impact.

### R1 — Make "two admins" a tracked commitment, not a silent skip
The current "Skip for now" lets a single-admin org exist indefinitely. Keep the skip (good for momentum) but:
add a **persistent dashboard banner** ("Add a second administrator — 1 of 2") like the MOU banner, email a
reminder after N days, and show the requirement as an explicit onboarding **checklist item** that stays
"incomplete". Distinguish *invited* vs *confirmed* second admin in the count.

### R2 — Add a first-class status page / alerts capability
Either remove the dead `resources :status` route or implement it. Recommended: an in-app **Service status**
panel that pulls from `status.wifi.service.gov.uk`, plus an **opt-in to incident alerts** during onboarding
(reuse the verified service email). This directly closes requirement #5.

### R3 — Introduce a "Backup SSID / resilience plan" step
Add a short onboarding screen (or Settings card) capturing the organisation's fallback plan if GovWifi is
unavailable — e.g. a backup SSID name and who owns it — even if only stored as guidance + a confirmation
checkbox. Closes requirement #6.

### R4 — Turn onboarding into an explicit checklist / task list
Today the journey is a chain of redirects with the real requirements (MOU, 2nd admin, first location) surfaced
only as banners or hard walls you hit later. A GOV.UK **task-list** landing page ("Set up GovWifi for your
organisation") with clear states (Completed / Cannot start yet) would make the sequence legible and make every
compliance item visible up front. See [wireframe W1](#w1--onboarding-task-list-new-landing-after-2fa).

### R5 — Bring the MOU into the onboarding flow
The MOU is a hard gate but is only discoverable via a banner. Add it as a checklist item and offer it right
after the 2nd-admin step, so the two blocking requirements (MOU + 2 admins) are dealt with before the user
tries — and fails — to add IPs.

### R6 — Clarify the password rule
The field enforces zxcvbn strength but the hint only says "at least 6 characters long". Users can be rejected
for a reason the UI never stated. Show the real rule ("must not be a common/weak password") and give inline
strength feedback.

### R7 — Consider per-access-point address granularity (or confirm location-level is sufficient)
If the compliance intent is truly "address per IP", either (a) allow an optional address/label per IP within a
location, or (b) document that location-level address is the accepted control and each IP maps to a located
site. At minimum, prompt for a location **name/label** to make multi-IP sites intelligible.

### R8 — Verify the service email is monitored
Optionally send a one-time confirmation to the service mailbox (like the admin email) so "shared and monitored"
is more than a hint. Reduces the risk of GovWifi being unable to reach the organisation.

### R9 — Fix the local-dev `make serve` target (podman)
`make stop` runs `docker compose … rm -fsv`, which `podman-compose` 1.0.6 rejects (`invalid choice: 'rm'`),
aborting `make serve`. Replace with `down -v --remove-orphans`, or guard the `rm` so local contributors on
podman can start the app with one command.

---

## 7. Low-fidelity wireframes

Low-fi wireframes for the highest-impact changes. These are deliberately structural (GOV.UK Design System
components: task list, notification banner, radios, inset text).

### W1 — Onboarding task list (new landing after 2FA)
*Implements R4/R5/R1/R3 — one legible page that makes every compliance item visible.*

```
┌──────────────────────────────────────────────────────────────────┐
│ GOV.UK  GovWifi                                   Support · Sign out│
├──────────────────────────────────────────────────────────────────┤
│ Cabinet Office · Switch organisation                                │
│                                                                     │
│  Set up GovWifi for your organisation                               │
│  Complete these steps before you can add access points.            │
│                                                                     │
│  Applied for                                                        │
│  ──────────────────────────────────────────────────────────────   │
│  1. Create your admin account .............................. ✔ Done │
│  2. Set up two-factor authentication ....................... ✔ Done │
│                                                                     │
│  Make your organisation compliant                                   │
│  ──────────────────────────────────────────────────────────────   │
│  3. Add a second administrator ..................... [ To do ]  (!) │
│        1 of 2 administrators added                                  │
│  4. Sign the Memorandum of Understanding ........... [ To do ]  (!) │
│  5. Add a backup SSID / resilience plan ............ [ To do ]      │
│  6. Opt in to service status alerts ................ [ To do ]      │
│                                                                     │
│  Start using GovWifi                                                │
│  ──────────────────────────────────────────────────────────────   │
│  7. Add your first location and IP addresses ....... [Cannot        │
│        Complete steps 3 and 4 first              start yet]         │
│                                                                     │
│  Your progress: 2 of 7 steps complete                               │
└──────────────────────────────────────────────────────────────────┘
```

### W2 — Second-admin step with persistent tracking
*Implements R1 — keep the skip, but make the outstanding requirement visible everywhere afterwards.*

```
┌──────────────────────────────────────────────────────────────────┐
│  (!) Important                                                      │
│  You have 1 of 2 required administrators. Add a second admin before│
│  you can add access points.                        [ Add admin ]   │
├──────────────────────────────────────────────────────────────────┤
│  Invite a team member to be an administrator                        │
│                                                                     │
│  Two admins are required so you can recover access if you lose your │
│  2FA device, and so there is always a contact if someone leaves.    │
│                                                                     │
│  Email address of team member                                      │
│  ┌───────────────────────────────────────────┐                     │
│  │                                             │                     │
│  └───────────────────────────────────────────┘                     │
│                                                                     │
│  [ Invite as an admin ]                                             │
│                                                                     │
│  Skip for now  →  (a reminder banner will stay until this is done)  │
└──────────────────────────────────────────────────────────────────┘
```

### W3 — Service status & alerts (closes requirement #5)
*Implements R2 — a real in-app status surface + opt-in alerts, reusing the verified service email.*

```
┌──────────────────────────────────────────────────────────────────┐
│  Service status                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  ● All systems operational           (from status.wifi…)     │   │
│  │  RADIUS London   ● OK      RADIUS Dublin   ● OK               │   │
│  │  Last checked: 2 minutes ago            View full status →   │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  Incident alerts                                                    │
│  Get emailed when there is a GovWifi incident or planned maintenance│
│                                                                     │
│  Send alerts to:  govwifi-team@gov.uk  (your service email)        │
│  [x] Email me about incidents                                       │
│  [x] Email me about planned maintenance                             │
│  [ Save alert preferences ]                                         │
└──────────────────────────────────────────────────────────────────┘
```

### W4 — Backup SSID / resilience plan (closes requirement #6)
*Implements R3 — a lightweight capture of the organisation's fallback plan.*

```
┌──────────────────────────────────────────────────────────────────┐
│  Your backup connectivity plan                                      │
│                                                                     │
│  Tell us what your organisation will use if GovWifi is unavailable. │
│  This helps us support you during an incident.                      │
│                                                                     │
│  Backup SSID name (optional)                                        │
│  ┌───────────────────────────────────────────┐                     │
│  │                                             │                     │
│  └───────────────────────────────────────────┘                     │
│                                                                     │
│  Who owns the backup network?                                       │
│  ┌───────────────────────────────────────────┐                     │
│  │                                             │                     │
│  └───────────────────────────────────────────┘                     │
│                                                                     │
│  [ ] We have a documented fallback plan for wifi outages            │
│                                                                     │
│  [ Save ]      Skip — I don't have a backup plan yet                │
└──────────────────────────────────────────────────────────────────┘
```

### W5 — Location with per-IP labelling (addresses requirement #7)
*Implements R7 — keep address at location level but give each IP a name/label so multi-IP sites are legible.*

```
┌──────────────────────────────────────────────────────────────────┐
│  Add a location                                                     │
│                                                                     │
│  Location name                                                      │
│  ┌───────────────────────────────────────────┐                     │
│  │ Head office — 3rd floor                     │                     │
│  └───────────────────────────────────────────┘                     │
│  Address                          Postcode                          │
│  ┌─────────────────────────────┐  ┌──────────────┐                 │
│  │ 10 High Street, London      │  │ SW1A 1AA     │                 │
│  └─────────────────────────────┘  └──────────────┘                 │
│                                                                     │
│  IP addresses at this location (up to 5)                            │
│  ┌───────────────────┐  Label (optional)                           │
│  │ 203.0.113.10      │  ┌────────────────────────┐                 │
│  └───────────────────┘  │ Reception AP           │                 │
│  ┌───────────────────┐  ┌────────────────────────┐                 │
│  │ 203.0.113.11      │  │ Meeting rooms AP       │                 │
│  └───────────────────┘  └────────────────────────┘                 │
│                                                                     │
│  [ Save location and IPs ]                                          │
│  ⚠ You must sign the MOU and have 2 admins before this is enabled.  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 8. Enforcement strategy — where each rule belongs

The practical question behind the recommendations above is: *for each requirement, can we add it to
sign-up, or should the admin self-confirm it?* The answer depends on whether the **system** can verify the
fact or only the **human** can. This section maps every rule to a concrete enforcement tier and the exact
code hook that implements it.

### 8.1 There are only two points where the app can *force* something

Everything in the onboarding "flow" is a chain of `before_action` redirects, **not** a linear wizard — so a
redirect can be dodged (that is exactly why "two admins" leaks today via *Skip for now*). Only two points are
genuine walls:

| Wall | Code | What it can force |
|---|---|---|
| **Create account (Step 3)** | `Users::ConfirmationsController#update` → `UserMembershipForm` (`form_params`) | Any field added here is **non-skippable** to create the account. But it is a *user*-level, single-shot form. |
| **Deferred hard gate** | `LocationsController#authorise_ip_actions` (`only: %i[bulk_upload add_ips]`) | Blocks adding IPs/locations until `!organisation.resign_mou?` **and** `organisation.meets_invited_admin_user_minimum?`. |

Design implication: **keep Step 3 lean (identity only)** — most requirements are *organisation*-level facts,
not *user* facts, and cram-loading the sign-up form hurts confirmation-completion. Use the deferred gate (and
a new task-list hub) for everything else.

### 8.2 The three tiers

**Tier 1 — Enforce it (the system has the data).** No checkbox needed; the app knows the true/false answer.

**Tier 2 — Self-certify (only the human knows).** The app *cannot* verify these, so a mandatory field adds
friction without assurance. Use an auditable confirmation checkbox — the same pattern the MOU signature
already uses successfully (a "I confirm I have the authority…" checkbox + typed name is treated as
sufficient today, so there is codebase precedent).

**Tier 3 — Build a feature.** Not a checkbox or a field — a capability that does not yet exist.

| # | Requirement | Tier | Where it lives / hook point |
|---|---|---|---|
| 4 | Email verification | **1 — Enforced** | Devise `confirmable`, pre-Step 3. Already the only path to account creation. ✅ |
| 3 | Service email | **1 — Enforced** | Mandatory field at Step 3 (`UserMembershipForm`). ✅ Add mailbox verification per [R8](#r8-verify-the-service-email-is-monitored). |
| 1 | Signed MOU | **1 — Enforced (gate)** | `authorise_ip_actions` via `resign_mou?`. ✅ Surface as a task-list item ([R5](#r5-bring-the-mou-into-the-onboarding-flow)) instead of banner-only. |
| 2 | Two admins | **1 — Enforced (gate), leaky** | `authorise_ip_actions` via `meets_invited_admin_user_minimum?`. Gate is real but *completion* is skippable — make it a tracked, always-visible checklist item ([R1](#r1--make-two-admins-a-tracked-commitment-not-a-silent-skip)). Keep the skip. |
| 6 | Backup SSID / resilience plan | **2 — Self-certify** | We cannot see their network. Confirmation checkbox on the task list (wireframe [W4](#w4--backup-ssid--resilience-plan-closes-requirement-6)). |
| 7 | Physical address per IP | **2 — Self-certify** | We validate postcode *format*, not truth. Location address stays required; optionally add a per-IP label + an "address is accurate" attestation (wireframe [W5](#w5--location-with-per-ip-labelling-addresses-requirement-7)). |
| 5 | Status page alerts | **3 — Build** | `resources :status` is a dead route (would 500). Build an opt-in alerts capture reusing the verified service email ([R2](#r2-add-a-first-class-status-page--alerts-capability) / wireframe [W3](#w3--service-status--alerts-closes-requirement-5)). |

### 8.3 Recommended placement

1. **Do not overload Step 3.** Sign-up stays identity-only. (Adding fields is technically just extending
   `form_params` + `UserMembershipForm`, but it is the wrong home for org-level facts and it costs conversion.)
2. **Add the task-list page ([W1](#w1--onboarding-task-list-new-landing-after-2fa)) as the post-2FA landing.**
   Redirect from `Users::TwoFactorAuthenticationSetupController#update` — currently → `invite_second_admin_path`
   or `stored_location_for(:user)` — to a new onboarding task-list controller. This page is the single hub:
   Tier-1 items render ✔ / To-do from live data; Tier-2 items are checkboxes; Tier-3 links to the new feature.
3. **Choose how hard Tier-2 bites:**
   - *Soft* — checklist visible + nag banners, never blocks. Best for conversion.
   - *Hard* — extend `authorise_ip_actions` to also require the confirmations, so IPs can't be added until the
     boxes are ticked. Best for compliance.
4. **Persist attestations auditably.** Self-cert needs storage: either boolean columns on `organisations` or a
   small `onboarding_confirmations` model, each carrying `confirmed_at` + `confirmed_by_id` (same auditable
   shape as `mous`) so a tick is attributable to a person and time.

### 8.4 Summary

> **Sign-up stays lean; the task list is the hub. Enforceable rules stay as gates (surfaced, not hidden);
> unenforceable rules become auditable confirmation checkboxes; status alerts are a small new feature.**
> Nothing that only the human can attest to should be a mandatory sign-up field — it buys friction, not
> assurance.
