# frozen_string_literal: true

# name: discourse-isthereanydeal
# about: Fetches free game deals from IsThereAnyDeal.com and posts them as daily topics
# version: 0.1.0
# authors: NetGamers
# url: https://github.com/netgamers/discourse-isthereanydeal

enabled_site_setting :isthereanydeal_enabled

register_asset "stylesheets/isthereanydeal-admin.scss"

after_initialize do
  module ::DiscourseIsthereanydeal
    PLUGIN_NAME = "discourse-isthereanydeal"

    # Named module so Ruby won't re-add it to the ancestry on reload
    module SerializerExtension
      def valid_values
        if object.setting == "isthereanydeal_shop_ids"
          cached_shops = PluginStore.get(DiscourseIsthereanydeal::PLUGIN_NAME, "cached_shops")
          if cached_shops.present?
            return cached_shops.map do |s|
              { name: "#{s['title']} (#{s['deals']} deals)", value: s["id"].to_s }
            end
          end
        end

        super
      end
    end
  end

  require_relative "lib/isthereanydeal/api_client"
  require_relative "lib/isthereanydeal/deal_formatter"
  require_relative "lib/isthereanydeal/deal_poster"
  require_relative "app/jobs/scheduled/fetch_free_deals"
  require_relative "app/controllers/isthereanydeal_admin_controller"

  Discourse::Application.routes.append do
    scope "/admin/plugins/isthereanydeal", constraints: StaffConstraint.new do
      get "/shops" => "isthereanydeal_admin#shops"
      put "/shops" => "isthereanydeal_admin#update_shops"
    end
  end

  # Deferred so AdminDetailedSiteSettingSerializer is autoloaded before we patch it
  Rails.configuration.to_prepare do
    AdminDetailedSiteSettingSerializer.prepend(DiscourseIsthereanydeal::SerializerExtension)
  end
end
