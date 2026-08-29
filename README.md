# Geolocation API

A RESTful Ruby on Rails API that stores geolocation data for an IP address or
URL, using an external provider (ipstack) for lookups. Built to be easy to run,
easy to test, and easy to swap the geolocation provider in the future.

---

## Tech stack & versions

- Ruby 3.3.6
- Rails 8.1.x (API-only)
- PostgreSQL 16
- RSpec for testing
- Docker + Docker Compose

Ruby is pinned in `.ruby-version`, the `Dockerfile`, and the `Gemfile` so local
and containerized environments match.

---

## Quick start (Docker — recommended)

Everything (app + PostgreSQL) runs in containers; nothing needs to be installed
locally except Docker.

```bash
# 1. Copy the example env file and add your ipstack key
cp .env.example .env
#    then edit .env and set IPSTACK_API_KEY=<your key>

# 2. Build and start (app + database)
docker compose up --build

# 3. The API is now available at:
http://localhost:3000
```

The database is created, migrated, and seeded automatically on startup.

### Getting an ipstack key

The app calls ipstack for geolocation. Grab a free key at
https://ipstack.com/ and put it in `.env` as `IPSTACK_API_KEY`. The free tier
uses `http` (not `https`) and has a monthly request cap, which is one reason the
app reuses stored results instead of re-fetching (see Design notes).

---

## Running locally without Docker (optional)

Requires Ruby 3.3.6 and a local PostgreSQL.

```bash
bundle install
cp .env.example .env        # set IPSTACK_API_KEY
bin/rails db:prepare        # create, migrate, seed
bundle exec rspec           # run the test suite
bin/rails server            # start on http://localhost:3000
```

---

## Authentication

All endpoints require a bearer token (this is the optional "secure endpoints"
requirement).

```
Authorization: Bearer <token>
```

For local testing the token defaults to `dev-local-token` if `API_TOKEN` is not
set in `.env`, so the app runs out of the box. Override it by setting
`API_TOKEN` in `.env`.

Requests without a valid token receive `401 Unauthorized`.

---

## API overview

Base path is versioned: `/api/v1`.

- **Add:** `POST /api/v1/locations` → `201 Created`
- **Fetch:** `GET /api/v1/locations/:query` → `200 OK`
- **Delete:** `DELETE /api/v1/locations/:query` → `204 No Content`

`:query` is the IP address or URL. Update (PUT/PATCH) is intentionally not
supported — the resource represents immutable third-party lookup data, not
user-editable fields.

Example (add):

```bash
curl -X POST http://localhost:3000/api/v1/locations \
  -H "Authorization: Bearer dev-local-token" \
  -H "Content-Type: application/json" \
  -d '{"query": "8.8.8.8"}'
```

---

## Design notes

- **Thin controllers, service objects.** Controllers only coordinate; the real
  work (resolving input, calling the provider, translating results) lives in
  `app/services/geolocation/`.
- **Swappable provider.** A base `Geolocation::Provider` defines the contract;
  `IpstackProvider` implements it and is the _only_ place ipstack is named. The
  provider is selected via configuration, so adding a new provider means writing
  one class and changing one config line.
- **The provider is the adapter.** Each provider both calls its API and
  translates the response into the app's standard shape, so nothing above the
  provider layer knows about any provider's raw format.
- **Consistent responses.** Success always returns `data`; errors always return
  `errors`, with meaningful HTTP status codes (`201`, `204`, `404`, `422`,
  `401`, `502`).
- **Store-and-reuse.** If an IP is already stored, it's returned from the
  database instead of re-calling the provider. This respects the provider's rate
  limits.
- **Edge cases handled deliberately:** invalid IP/URL, private/reserved IPs
  (detected locally before any provider call, using `IPAddr`), IPv6 input,
  unreachable URLs, provider timeouts/errors.

### What I'd add for production (out of scope here)

- **Caching/replicas** for high read volume (store-and-reuse + the index cover current needs).
- **Scheduled refresh** of stale records, since IP-to-location data drifts over time.
- **Per-client API keys** for attribution, revocation, and rate limiting.
- **Split HTTP client from adapter** if a provider's request logic grew.

---

## Testing

```bash
bundle exec rspec
```

Tests use RSpec with the external provider stubbed (no real network calls), so
the suite is fast and deterministic. Coverage targets the provider translation,
the lookup service, the model validations, and the request endpoints — including
the "unfortunate" conditions (bad input, private IPs, provider failure).

---

## Notes for reviewers

- The repository contains **no secrets**. `.env` is git-ignored; only
  `.env.example` (with placeholders) is committed.
- Provide your **own** ipstack key in `.env` to run lookups.
- ipstack requires the API key as a query parameter, which is not ideal. The key
  is kept in an environment variable, confined to the provider adapter, and never
  logged. A provider supporting header-based auth would be preferred.
