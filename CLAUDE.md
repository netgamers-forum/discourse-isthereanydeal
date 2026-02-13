# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Discourse plugin that fetches free game deals (100% off) from the IsThereAnyDeal.com API and creates daily topics in a configurable Discourse category. One topic per day; same-day updates are appended as replies.

## Architecture

This is a standard Discourse plugin (Ruby + Ember.js). It runs inside a Discourse instance — there is no standalone build/test step outside of Discourse's own dev environment.

- **`plugin.rb`** — Entry point. Declares metadata, `enabled_site_setting`, registers admin routes, and loads all modules inside `after_initialize`.
- **`lib/isthereanydeal/api_client.rb`** — HTTP client wrapping the ITAD API. Handles pagination, rate-limit header logging, and free-deal filtering. Uses `Excon` for HTTP.
- **`lib/isthereanydeal/deal_formatter.rb`** — Pure functions that turn deal data into Discourse markdown.
- **`lib/isthereanydeal/deal_poster.rb`** — Topic creation/reply logic using `PostCreator`. Manages daily topic tracking and deal deduplication via `PluginStore`.
- **`app/jobs/scheduled/fetch_free_deals.rb`** — Sidekiq scheduled job (`Jobs::Scheduled`, every 4 hours). Orchestrates ApiClient → DealPoster.
- **`app/controllers/isthereanydeal_admin_controller.rb`** — Admin-only endpoints to proxy the ITAD shops list and save shop selection.
- **`assets/javascripts/discourse/admin/`** — Ember route, controller, and template for the admin shop-selector UI.

## Key External APIs

- **IsThereAnyDeal Deals**: `GET https://api.isthereanydeal.com/deals/v2` — requires API key as `key` query param. Paginated via `hasMore`/`nextOffset`. Rate-limit info in response headers.
- **IsThereAnyDeal Shops**: `GET https://api.isthereanydeal.com/service/shops/v1` — no auth required. Returns `[{id, title, deals, games, update}]`.

## State Storage (PluginStore)

All under plugin name `"discourse-isthereanydeal"`:
- `topic_YYYY-MM-DD` → integer topic ID for that day's post
- `posted_deal_keys` → JSON array of `"gameId_shopId"` strings for deduplication

## Testing Within Discourse

To test the scheduled job manually from a Discourse Rails console:
```ruby
Jobs::FetchFreeDeals.new.execute({})
```

## Conventions

- All log messages prefixed with `[DiscourseIsthereanydeal]`.
- Admin settings prefixed with `isthereanydeal_`.
- The `isthereanydeal_api_key` setting uses `secret: true` — never log or expose its value.
