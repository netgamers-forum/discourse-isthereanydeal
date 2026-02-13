# discourse-isthereanydeal

A Discourse plugin that automatically posts free game deals from [IsThereAnyDeal.com](https://isthereanydeal.com/) as daily topics.

## How It Works

Every 4 hours, the plugin queries the IsThereAnyDeal API for deals with a price of zero (100% off). When free games are found:

- **First run of the day**: a new topic is created (e.g. "Free Games - February 13, 2026") in your chosen category.
- **Later runs the same day**: new deals are appended as replies to the existing daily topic.

Deals are deduplicated — the same game+shop combination will never be posted twice.

## Installation

Add the plugin to your Discourse `app.yml` container configuration:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/netgamers/discourse-isthereanydeal.git
```

Then rebuild the container:

```bash
cd /var/discourse
./launcher rebuild app
```

## Obtaining an IsThereAnyDeal API Key

1. Create an account on [IsThereAnyDeal.com](https://isthereanydeal.com/) if you don't have one.
2. Go to [https://isthereanydeal.com/dev/app/](https://isthereanydeal.com/dev/app/).
3. Click **Create App** and fill in the details (app name, description, etc.).
4. Once created, copy your **API Key** from the app dashboard.

## Configuration

After installation, go to **Admin > Settings** and search for `isthereanydeal`. Configure the following:

| Setting | Description |
|---------|-------------|
| **isthereanydeal enabled** | Master on/off switch for the plugin. |
| **isthereanydeal api key** | Your API key from IsThereAnyDeal.com (see above). |
| **isthereanydeal category** | The Discourse category where daily deal topics will be created. |
| **isthereanydeal country** | Two-letter country code for regional pricing (e.g. `US`, `GB`, `DE`). Defaults to `US`. |
| **isthereanydeal include dlc** | Whether to include free DLC deals in addition to full games. |
| **isthereanydeal include mature** | Whether to include deals flagged as mature content. |

### Selecting Shops

The plugin includes an admin page for selecting which stores to monitor:

1. Go to **Admin > Plugins > IsThereAnyDeal**.
2. Click **Fetch Shops** to load the list of available stores from the API.
3. Check the stores you want to monitor (e.g. Steam, GOG, Epic Game Store).
4. Click **Save Selection**.

If no shops are selected, deals from all shops will be included.

## Rate Limiting

The IsThereAnyDeal API is rate-limited. The plugin reads rate-limit headers from every API response and logs them. If the remaining quota drops to 2 or fewer requests, the plugin stops making further requests until the next scheduled run. You can monitor this in your Discourse logs by searching for `[DiscourseIsthereanydeal]`.

## License

MIT
