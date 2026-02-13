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

      new_deals = filter_new_deals(deals)
      return if new_deals.empty?

      today = Date.today.to_s
      topic_id = get_today_topic_id(today)

      if topic_id && Topic.exists?(id: topic_id)
        append_to_topic(topic_id, new_deals)
      else
        topic_id = create_new_topic(new_deals, category_id, today)
      end

      mark_deals_as_posted(new_deals) if topic_id
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
      body = DealFormatter.format_topic_body(deals)

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

      topic_id
    rescue => e
      Rails.logger.error("[DiscourseIsthereanydeal] Failed to create topic: #{e.message}")
      nil
    end

    def self.append_to_topic(topic_id, deals)
      body = DealFormatter.format_reply_body(deals)

      PostCreator.create!(
        Discourse.system_user,
        topic_id: topic_id,
        raw: body,
        skip_validations: true,
      )

      Rails.logger.info(
        "[DiscourseIsthereanydeal] Appended #{deals.size} deal(s) to topic #{topic_id}"
      )
    rescue => e
      Rails.logger.error("[DiscourseIsthereanydeal] Failed to append to topic #{topic_id}: #{e.message}")
    end

    private_class_method :get_today_topic_id, :set_today_topic_id,
                         :posted_deal_keys, :save_posted_deal_keys,
                         :deal_key, :filter_new_deals, :mark_deals_as_posted,
                         :create_new_topic, :append_to_topic
  end
end
