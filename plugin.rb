# frozen_string_literal: true

# name: discourse-isthereanydeal
# about: Fetches free game deals from IsThereAnyDeal.com and posts them as daily topics
# version: 0.1.0
# authors: NetGamers
# url: https://github.com/netgamers/discourse-isthereanydeal

enabled_site_setting :isthereanydeal_enabled

after_initialize do
  module ::DiscourseIsthereanydeal
    PLUGIN_NAME = "discourse-isthereanydeal"
  end

  require_relative "lib/isthereanydeal/api_client"
  require_relative "lib/isthereanydeal/deal_formatter"
  require_relative "lib/isthereanydeal/deal_poster"
  require_relative "app/jobs/scheduled/fetch_free_deals"
end
