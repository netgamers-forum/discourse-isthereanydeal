# frozen_string_literal: true

module DiscourseIsthereanydeal
  class DealPoster
    PLUGIN_STORE_KEY = "discourse-isthereanydeal"

    def self.post_deals(deals)
      return if deals.empty?

      category_id = SiteSetting.isthereanydeal_category_id.to_i
      if category_id == 0
        Rails.logger.warn("[DiscourseIsthereanydeal] No category configured, skipping post")
        return
      end

      unless Category.exists?(id: category_id)
        Rails.logger.error("[DiscourseIsthereanydeal] Category #{category_id} does not exist")
        return
      end

      unless SiteSetting.isthereanydeal_include_dlc
        deals = deals.reject { |d| d["type"] == "dlc" }
      end

      min_price = SiteSetting.isthereanydeal_minimum_price.to_f
      if min_price > 0
        deals = deals.select { |d| (d.dig("deal", "regular", "amount") || 0).to_f >= min_price }
      end

      new_deals = filter_new_deals(deals)
      return if new_deals.empty?

      today = Date.today.to_s
      topic_id = get_today_topic_id(today)

      if topic_id && Topic.exists?(id: topic_id)
        post_deal_replies(topic_id, new_deals)
      else
        create_new_topic(new_deals, category_id, today)
      end
    end

    def self.get_today_topic_id(date_string)
      PluginStore.get(PLUGIN_STORE_KEY, "topic_#{date_string}")
    end

    def self.set_today_topic_id(date_string, topic_id)
      PluginStore.set(PLUGIN_STORE_KEY, "topic_#{date_string}", topic_id)
    end

    def self.posted_deal_keys
      PluginStore.get(PLUGIN_STORE_KEY, "posted_deal_keys") || []
    end

    def self.save_posted_deal_keys(keys)
      PluginStore.set(PLUGIN_STORE_KEY, "posted_deal_keys", keys)
    end

    def self.deal_key(deal_data)
      game_id = deal_data["id"]
      shop_id = deal_data.dig("deal", "shop", "id")
      "#{game_id}_#{shop_id}"
    end

    def self.filter_new_deals(deals)
      existing_keys = posted_deal_keys
      deals.reject { |d| existing_keys.include?(deal_key(d)) }
    end

    def self.mark_deals_as_posted(deals)
      keys = posted_deal_keys
      deals.each { |d| keys << deal_key(d) }
      keys.uniq!
      save_posted_deal_keys(keys)
    end

    def self.create_new_topic(deals, category_id, date_string)
      date = Date.parse(date_string)
      title = DealFormatter.topic_title(date)
      body = DealFormatter.format_summary(deals)

      post = PostCreator.create!(
        Discourse.system_user,
        title: title,
        raw: body,
        category: category_id,
        skip_validations: true,
      )

      topic_id = post.topic_id
      set_today_topic_id(date_string, topic_id)

      Rails.logger.info(
        "[DiscourseIsthereanydeal] Created topic #{topic_id} with #{deals.size} free deal(s)"
      )

      post_deal_replies(topic_id, deals)
    rescue => e
      Rails.logger.error("[DiscourseIsthereanydeal] Failed to create topic: #{e.message}")
    end

    def self.post_deal_replies(topic_id, deals)
      posted = []

      deals.each do |deal_data|
        body = DealFormatter.format_deal_reply(deal_data)

        PostCreator.create!(
          Discourse.system_user,
          topic_id: topic_id,
          raw: body,
          skip_validations: true,
        )

        posted << deal_data
      rescue => e
        title = deal_data["title"] || "unknown"
        Rails.logger.error(
          "[DiscourseIsthereanydeal] Failed to post deal '#{title}' to topic #{topic_id}: #{e.message}"
        )
      end

      mark_deals_as_posted(posted) if posted.any?

      Rails.logger.info(
        "[DiscourseIsthereanydeal] Posted #{posted.size}/#{deals.size} deal(s) to topic #{topic_id}"
      )
    end

    private_class_method :get_today_topic_id, :set_today_topic_id,
                         :posted_deal_keys, :save_posted_deal_keys,
                         :deal_key, :filter_new_deals, :mark_deals_as_posted,
                         :create_new_topic, :post_deal_replies
  end
end
