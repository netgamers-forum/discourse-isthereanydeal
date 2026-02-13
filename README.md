# discourse-isthereanydeal

A Discourse plugin that automatically posts free game deals from [IsThereAnyDeal.com](https://isthereanydeal.com/) as daily topics.

## How It Works

Every 4 hours, the plugin queries the IsThereAnyDeal API for deals with a price of zero (100% off). When free games are found:

- **First run of the day**: a new topic is created (e.g. "IsThereAnyDeal - Free Games for 13/02/2026") in your chosen category. The opening post contains a summary table showing how many deals were found per shop. Each deal is then posted as a separate reply with a banner image, price info, shop/DRM details, and a claim link.
- **Later runs the same day**: any newly discovered deals are added as individual replies to the existing daily topic.

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
2. Go to [https://isthereanydeal.com/apps/](https://isthereanydeal.com/apps/).
3. Click **Create App** and fill in the details (app name, description, etc.).
4. Once created, copy your **API Key** from the app dashboard.

## Configuration

After installation, go to **Admin > Settings** and search for `isthereanydeal`. Configure the following:

| Setting | Description |
|---------|-------------|
| **isthereanydeal enabled** | Master on/off switch for the plugin. |
| **isthereanydeal api key** | Your API key from IsThereAnyDeal.com (see above). |
| **isthereanydeal category** | The Discourse category where daily deal topics will be created. |
| **isthereanydeal country** | Two-letter country code for regional pricing (e.g. `EU`, `GB`, `US`). Defaults to `EU`. Also determines the timezone used for expiry dates (e.g. EU = CET, US = EST, GB = GMT). |
| **isthereanydeal include dlc** | Whether to include free DLC deals in addition to full games. |
| **isthereanydeal include mature** | Whether to include deals flagged as mature content. |
| **isthereanydeal shops** | Shop IDs to monitor. Defaults to `61, 16, 35`. Leave empty to include all shops. |

### Selecting Shops

To choose which stores to monitor, browse [https://isthereanydeal.com/shops/](https://isthereanydeal.com/shops/) and find the numeric ID in each shop's URL (e.g. `https://isthereanydeal.com/shops/61/` means ID `61`). Enter the IDs in the **isthereanydeal shops** setting.

## Rate Limiting

The IsThereAnyDeal API is rate-limited. The plugin reads rate-limit headers from every API response and logs them. If the remaining quota drops to 2 or fewer requests, the plugin stops making further requests until the next scheduled run. You can monitor this in your Discourse logs by searching for `[DiscourseIsthereanydeal]`.

## Manual Testing

To trigger the job manually from a Discourse Rails console:

```ruby
# Clear previous state if you want to re-post deals
PluginStore.remove("discourse-isthereanydeal", "topic_#{Date.today}")
PluginStore.remove("discourse-isthereanydeal", "posted_deal_keys")

# Run the job
Jobs::FetchFreeDeals.new.execute({})
```

## License

MIT
