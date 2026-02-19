# frozen_string_literal: true

module Jobs
  class IsthereanydealFetchdeals < ::Jobs::Scheduled
    every 4.hours

    def execute(args)
      return unless SiteSetting.isthereanydeal_enabled
      return if SiteSetting.isthereanydeal_api_key.blank?

      Rails.logger.warn("[DiscourseIsthereanydeal] [INFO] Starting scheduled fetch of free deals")

      client = DiscourseIsthereanydeal::ApiClient.new
      deals = client.fetch_free_deals

      Rails.logger.warn("[DiscourseIsthereanydeal] [INFO] Fetched #{deals.size} free deal(s) from API")

      DiscourseIsthereanydeal::DealPoster.post_deals(deals)

      if client.last_rate_limit_remaining
        msg = "[DiscourseIsthereanydeal] [INFO] Job completed. API quota: #{client.last_rate_limit_remaining}/#{client.last_rate_limit_limit} remaining"
        msg += ", resets at #{client.last_rate_limit_reset}" if client.last_rate_limit_reset
        Rails.logger.warn(msg)
      else
        Rails.logger.warn("[DiscourseIsthereanydeal] [INFO] Job completed. No API quota info available.")
      end
    end
  end
end
