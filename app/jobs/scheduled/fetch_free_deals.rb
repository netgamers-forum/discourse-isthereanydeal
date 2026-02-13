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

      Rails.logger.info("[DiscourseIsthereanydeal] Scheduled job completed")
    end
  end
end
