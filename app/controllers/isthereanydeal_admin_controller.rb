# frozen_string_literal: true

class IsthereanydealAdminController < Admin::AdminController
  requires_plugin DiscourseIsthereanydeal::PLUGIN_NAME

  # GET /admin/plugins/isthereanydeal/shops
  # Fetches shops from ITAD API and caches them in PluginStore.
  # The cached list is used by the serializer to populate the shop_ids
  # multi-select dropdown in site settings.
  def shops
    client = DiscourseIsthereanydeal::ApiClient.new
    shop_list = client.fetch_shops

    if shop_list.present?
      PluginStore.set(DiscourseIsthereanydeal::PLUGIN_NAME, "cached_shops", shop_list)
    else
      shop_list = PluginStore.get(DiscourseIsthereanydeal::PLUGIN_NAME, "cached_shops") || []
    end

    render json: {
      shops: shop_list.map { |s|
        { id: s["id"], title: s["title"], deals: s["deals"], games: s["games"] }
      },
    }
  end

  def update_shops
    shop_ids = params[:shop_ids]

    if shop_ids.is_a?(Array)
      clean_ids = shop_ids.map(&:to_i).reject(&:zero?).join("|")
      SiteSetting.isthereanydeal_shop_ids = clean_ids
      render json: { success: true, shop_ids: clean_ids }
    else
      render json: { error: "shop_ids must be an array" }, status: 400
    end
  end
end
