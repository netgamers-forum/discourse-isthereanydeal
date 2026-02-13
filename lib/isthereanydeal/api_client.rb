# frozen_string_literal: true

module DiscourseIsthereanydeal
  class ApiClient
    BASE_URL = "https://api.isthereanydeal.com"
    DEALS_PATH = "/deals/v2"
    SHOPS_PATH = "/service/shops/v1"
    MAX_LIMIT = 200

    def initialize
      @api_key = SiteSetting.isthereanydeal_api_key
      @country = SiteSetting.isthereanydeal_country
      @mature = SiteSetting.isthereanydeal_include_mature
    end

    # Fetches all free deals (price.amount == 0) by paginating through the API.
    # Returns an array of deal hashes, or an empty array on error.
    def fetch_free_deals
      all_deals = []
      offset = 0

      loop do
        response = fetch_deals_page(offset)
        break if response.nil?

        log_rate_limit_headers(response)

        if rate_limit_exhausted?(response)
          Rails.logger.warn("[DiscourseIsthereanydeal] Rate limit nearly exhausted, stopping pagination")
          break
        end

        body = parse_response(response)
        break if body.nil?

        list = body["list"] || []
        free_deals = list.select { |deal| deal.dig("deal", "price", "amount") == 0 }
        all_deals.concat(free_deals)

        # Sorted by price ascending: if no free deals on this page, no more will follow
        break if free_deals.empty?

        # Pagination: check hasMore and advance offset
        break unless body["hasMore"]
        offset = body["nextOffset"]
      end

      all_deals
    end

    # Fetches the list of available shops from the ITAD API.
    # No API key required for this endpoint.
    # Returns an array of shop hashes [{id, title, deals, games, update}], or empty array on error.
    def fetch_shops
      query_params = { country: @country }
      query_string = URI.encode_www_form(query_params)
      url = "#{BASE_URL}#{SHOPS_PATH}?#{query_string}"

      response = Excon.get(url, read_timeout: 30, connect_timeout: 10)

      if response.status != 200
        Rails.logger.error(
          "[DiscourseIsthereanydeal] Shops API returned status #{response.status}: #{response.body.to_s[0..500]}"
        )
        return []
      end

      log_rate_limit_headers(response)
      parse_response(response) || []
    rescue Excon::Error => e
      Rails.logger.error("[DiscourseIsthereanydeal] Shops HTTP error: #{e.message}")
      []
    end

    private

    def fetch_deals_page(offset)
      query_params = {
        key: @api_key,
        country: @country,
        offset: offset,
        limit: MAX_LIMIT,
        sort: "price",
        nondeals: false,
        mature: @mature,
      }

      # Add shop filter if configured
      shop_ids = SiteSetting.isthereanydeal_shop_ids
      if shop_ids.present?
        query_params[:shops] = shop_ids.gsub("|", ",")
      end

      query_string = URI.encode_www_form(query_params)
      url = "#{BASE_URL}#{DEALS_PATH}?#{query_string}"

      response = Excon.get(url, read_timeout: 30, connect_timeout: 10)

      if response.status != 200
        Rails.logger.error(
          "[DiscourseIsthereanydeal] Deals API returned status #{response.status}: #{response.body.to_s[0..500]}"
        )
        return nil
      end

      response
    rescue Excon::Error => e
      Rails.logger.error("[DiscourseIsthereanydeal] Deals HTTP error: #{e.message}")
      nil
    end

    def parse_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("[DiscourseIsthereanydeal] JSON parse error: #{e.message}")
      nil
    end

    def log_rate_limit_headers(response)
      headers = response.headers || {}
      remaining = headers["X-RateLimit-Remaining"] || headers["x-ratelimit-remaining"]
      limit = headers["X-RateLimit-Limit"] || headers["x-ratelimit-limit"]
      reset = headers["X-RateLimit-Reset"] || headers["x-ratelimit-reset"]

      if remaining
        msg = "[DiscourseIsthereanydeal] Rate limit: #{remaining}/#{limit} remaining"
        msg += ", resets at #{reset}" if reset
        Rails.logger.info(msg)
      end
    end

    def rate_limit_exhausted?(response)
      headers = response.headers || {}
      remaining = headers["X-RateLimit-Remaining"] || headers["x-ratelimit-remaining"]
      return false if remaining.nil?

      remaining.to_i <= 2
    end
  end
end
