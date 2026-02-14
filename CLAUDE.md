# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Discourse plugin that fetches free game deals (100% off) from the IsThereAnyDeal.com API and creates daily topics in a configurable Discourse category. One topic per day; same-day updates are appended as replies.

## Architecture

This is a Ruby-only Discourse plugin (no Ember/frontend assets). It runs inside a Discourse instance — there is no standalone build/test step outside of Discourse's own dev environment. All configuration is done via Discourse site settings.

- **`plugin.rb`** — Entry point. Declares metadata, `enabled_site_setting`, and loads all modules inside `after_initialize`.
- **`lib/isthereanydeal/api_client.rb`** — HTTP client wrapping the ITAD API. Handles pagination, rate-limit header logging, and free-deal filtering. Uses `Excon` for HTTP.
- **`lib/isthereanydeal/deal_formatter.rb`** — Pure functions that turn deal data into Discourse markdown. Handles expiry timezone conversion based on configured country.
- **`lib/isthereanydeal/deal_poster.rb`** — Topic creation/reply logic using `PostCreator`. Manages daily topic tracking and deal deduplication via `PluginStore`.
- **`app/jobs/scheduled/fetch_free_deals.rb`** — Sidekiq scheduled job (`Jobs::Scheduled`, every 4 hours). Orchestrates ApiClient → DealPoster.

## Key External APIs

- **IsThereAnyDeal Deals**: `GET https://api.isthereanydeal.com/deals/v2` — requires API key as `key` query param. Paginated via `hasMore`/`nextOffset`. Rate-limit info in response headers. Sorted by price ascending so free deals come first.

## State Storage (PluginStore)

All under plugin name `"discourse-isthereanydeal"`:
- `topic_YYYY-MM-DD` → integer topic ID for that day's post
- `posted_deal_keys` → JSON array of `"gameId_shopId"` strings for deduplication

## Testing Within Discourse

To test the scheduled job manually from a Discourse Rails console:
```ruby
Jobs::FetchFreeDeals.new.execute({})
```

## Site Settings

All configured via Discourse admin (`/admin/site_settings`), prefix `isthereanydeal_`:
- `isthereanydeal_enabled` — master toggle (default: false)
- `isthereanydeal_api_key` — ITAD API key (secret)
- `isthereanydeal_category_id` — Discourse category for deal topics
- `isthereanydeal_country` — country code for API requests and expiry timezone (default: "EU")
- `isthereanydeal_include_dlc` — include DLC deals (default: false)
- `isthereanydeal_include_mature` — include mature content (default: false)
- `isthereanydeal_minimum_price` — minimum regular price filter (default: 0)
- `isthereanydeal_shops` — pipe-delimited shop IDs to filter (default: "61|16|35")

## Conventions

- All log messages prefixed with `[DiscourseIsthereanydeal]`.
- Admin settings prefixed with `isthereanydeal_`.
- The `isthereanydeal_api_key` setting uses `secret: true` — never log or expose its value.
