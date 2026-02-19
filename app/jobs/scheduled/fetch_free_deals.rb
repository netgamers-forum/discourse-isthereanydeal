# frozen_string_literal: true

module Jobs
  class FetchFreeDeals < ::Jobs::Scheduled
    every 4.hours

    def execute(args)
      return unless SiteSetting.isthereanydeal_enabled
      return if SiteSetting.isthereanydeal_api_key.blank?

      Rails.logger.info("[DiscourseIsthereanydeal] Starting scheduled fetch of free deals")

      client = DiscourseIsthereanydeal::ApiClient.new
      deals = client.fetch_free_deals

      Rails.logger.info("[DiscourseIsthereanydeal] Fetched #{deals.size} free deal(s) from API")

      DiscourseIsthereanydeal::DealPoster.post_deals(deals)

      if client.last_rate_limit_remaining
        msg = "[DiscourseIsthereanydeal] Job completed. API quota: #{client.last_rate_limit_remaining}/#{client.last_rate_limit_limit} remaining"
        msg += ", resets at #{client.last_rate_limit_reset}" if client.last_rate_limit_reset
        Rails.logger.info(msg)
      else
        Rails.logger.info("[DiscourseIsthereanydeal] Job completed. No API quota info available.")
      end
    end
  end
end
