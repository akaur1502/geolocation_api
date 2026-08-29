# Geolocation API

A RESTful Ruby on Rails API that stores geolocation data for an IP address or
URL, using an external provider (ipstack) for lookups. Built to be easy to run,
easy to test, and easy to swap the geolocation provider in the future.

---

## Tech stack

- **Ruby** 3.3.6
- **Rails** 8.1 (API-only)
- **PostgreSQL** 16
- **RSpec** for testing (external HTTP stubbed with WebMock)
- **Docker + Docker Compose** for one-command setup

Ruby is pinned in `.ruby-version`, the `Dockerfile`, and the `Gemfile` so local
and containerized environments match.

---

## Quick start with Docker (recommended)

Everything (app + PostgreSQL) runs in containers. Nothing needs to be installed
locally except Docker.

```bash
# 1. Clone the repository
git clone <repo-url>
cd geolocation_api

# 2. Create your .env from the template
cp .env.example .env

# 3. Add your ipstack key to .env (free tier is fine - https://ipstack.com/)
#    Set: IPSTACK_API_KEY=your_key_here
#    The auth token and DB credentials already have safe local defaults.

# 4. Build and start (app + database)
docker compose up --build
```

The database is created, migrated, and **seeded with sample data** automatically
on first startup. The API is then available at `http://localhost:3000`.

To stop: `Ctrl+C`, then `docker compose down` (add `-v` to also wipe the database).

---

## Authentication

All endpoints require a bearer token:

```
Authorization: Bearer <token>
```

For local testing the token defaults to `dev-local-token` (override with
`API_TOKEN` in `.env`). Requests without a valid token receive `401`.

---

## Endpoints

Base path is versioned: `/api/v1`. Responses follow the JSON:API convention
(`data` on success, `errors` on failure).

- **Create** - `POST /api/v1/locations` returns `201 Created`
- **Retrieve** - `GET /api/v1/locations/:query` returns `200 OK`
- **Delete** - `DELETE /api/v1/locations/:query` returns `204 No Content`

`:query` is the IP address or URL. Update (PUT/PATCH) is intentionally not
supported - the resource represents immutable third-party lookup data.

### Create a location

```bash
curl -X POST http://localhost:3000/api/v1/locations \
  -H "Authorization: Bearer dev-local-token" \
  -H "Content-Type: application/json" \
  -d '{"query": "8.8.8.8"}'
```

Response (`201 Created`):

```json
{
  "data": {
    "id": "8.8.8.8",
    "type": "location",
    "attributes": {
      "query": "8.8.8.8",
      "query_type": "ip",
      "ip": "8.8.8.8",
      "ip_type": "ipv4",
      "continent_name": "North America",
      "country_name": "United States",
      "country_code": "US",
      "region_name": "California",
      "city": "Mountain View",
      "zip": "94043",
      "latitude": "37.386",
      "longitude": "-122.0838",
      "created_at": "2026-08-29T06:28:33.112Z"
    }
  }
}
```

A URL works the same way - it is resolved to an IP via DNS and stored with
`query_type: "url"`:

```bash
curl -X POST http://localhost:3000/api/v1/locations \
  -H "Authorization: Bearer dev-local-token" \
  -H "Content-Type: application/json" \
  -d '{"query": "github.com"}'
```

### Retrieve a location

```bash
curl http://localhost:3000/api/v1/locations/8.8.8.8 \
  -H "Authorization: Bearer dev-local-token"
```

### Delete a location

```bash
curl -X DELETE http://localhost:3000/api/v1/locations/8.8.8.8 \
  -H "Authorization: Bearer dev-local-token"
```

### Error responses

Errors use a consistent JSON:API shape, e.g. a private IP (`422`):

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Invalid request",
      "detail": "192.168.1.1 is a private or reserved address and can't be geolocated"
    }
  ]
}
```

Status codes: `201` created, `200` retrieved, `204` deleted, `401`
unauthenticated, `404` not found, `422` invalid input / private IP, `502`
provider failure.

---

## Running the tests

```bash
# In Docker
docker compose run web bundle exec rspec

# Or locally (requires local PostgreSQL and `bundle install`)
bundle exec rspec
```

Tests stub the external provider (no real network calls), so the suite is fast
and deterministic. Coverage includes the provider translation, the lookup
service, model validations, and the request endpoints - including the
"unfortunate" conditions (bad input, private IPs, provider failure, missing
token).

---

## Design notes

- **Thin controllers, service objects.** Controllers only coordinate; the real
  work (resolving input, calling the provider, translating results) lives in
  `app/services/geolocation/`.
- **Swappable provider.** A base `Geolocation::Provider` defines the contract;
  `IpstackProvider` implements it and is the only place ipstack is named
  (`config/initializers/geolocation.rb`). Adding a provider means writing one
  class and changing one line.
- **The provider is the adapter.** Each provider both calls its API and
  normalizes the response into the app's standard shape, so nothing above the
  provider layer knows any provider's raw format.
- **Consistent responses.** Success returns `data`; errors return `errors`, via
  a single serializer and centralized `rescue_from` error handling.
- **Store-and-reuse.** If a query is already stored, it's returned from the
  database instead of re-calling the provider (respects rate limits). A unique
  index on `query` keeps lookups fast and prevents duplicates.
- **Edge cases handled deliberately:** invalid IP/URL, private/reserved/loopback
  IPs (detected locally with `IPAddr`, before any provider call), IPv6 input,
  unresolvable hostnames, provider timeouts and errors.
- **Single table.** The domain has one entity (a geolocation record), so the
  schema is a single `locations` table. Auth uses a shared token rather than
  user accounts, so no users table is needed.

### What I'd add for production (out of scope here)

- **Repeat-access performance:** store-and-reuse plus the index cover current
  needs; a Redis cache could front the DB read under high load, then read
  replicas if reads outgrew one instance.
- **Data freshness:** a scheduled job would refetch records older than N days,
  keeping data current without any request paying the refetch cost.
- **Per-client API keys** for attribution, revocation, and rate limiting.
- **Split HTTP client from adapter** if a provider's request logic grew
  (retries, backoff, token refresh).

---

## Notes for reviewers

- The repository contains **no secrets**. `.env` is git-ignored; only
  `.env.example` (with placeholders) is committed.
- Provide your **own** ipstack key in `.env` to run live lookups (free tier is
  fine). Seed data is static, so the app returns data even without a key.
- ipstack requires the API key as a query parameter, which is not ideal. The key
  is kept in an environment variable, confined to the provider adapter, and
  never logged.
