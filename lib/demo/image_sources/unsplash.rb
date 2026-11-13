# frozen_string_literal: true

require "uri"
require "digest"

module Demo
  module ImageSources
    # Unsplash API. Requires UNSPLASH_ACCESS_KEY. Their API guidelines require
    # triggering the download endpoint when an image is actually used and
    # crediting the photographer with a link back to Unsplash.
    class Unsplash < Base
      ENDPOINT = "https://api.unsplash.com/search/photos"
      UTM = "utm_source=pcmarket_demo&utm_medium=referral"

      def provider_name
        "unsplash"
      end

      def available?
        key.present?
      end

      def skip_reason
        "UNSPLASH_ACCESS_KEY is not set"
      end

      def search(query, limit: 20)
        uri = URI.parse(ENDPOINT)
        uri.query = URI.encode_www_form(query: query, per_page: [ limit, 30 ].min, orientation: "landscape")

        payload = get_json(uri.to_s, headers: auth_headers)
        Array(payload["results"]).filter_map do |result|
          urls = result["urls"] || {}
          download = urls["full"].presence || urls["regular"].presence
          next if download.blank?

          user = result["user"] || {}
          source_url = result.dig("links", "html").presence || "https://unsplash.com/photos/#{result['id']}"

          {
            external_id: result["id"].presence || Digest::SHA1.hexdigest(download),
            provider: provider_name,
            title: result["alt_description"].presence || query,
            download_url: download,
            source_url: add_utm(source_url),
            author: user["name"].presence || user["username"].presence || "Unsplash contributor",
            author_url: add_utm(user.dig("links", "html")),
            license: "Unsplash License",
            license_url: "https://unsplash.com/license",
            track_url: result.dig("links", "download_location").presence,
            width: result["width"],
            height: result["height"]
          }
        end
      end

      def track_usage(entry)
        return true if entry[:track_url].blank?

        request(URI.parse(entry[:track_url]), headers: auth_headers, attempts: 2)
        true
      rescue RequestFailed, RateLimited => e
        @logger&.warn("[demo:images] unsplash download tracking failed: #{e.message}")
        false
      end

      private

      def key
        ENV["UNSPLASH_ACCESS_KEY"].presence
      end

      def auth_headers
        { "Authorization" => "Client-ID #{key}", "Accept-Version" => "v1" }
      end

      def add_utm(url)
        return if url.blank?
        return url if url.include?("utm_source=")

        separator = url.include?("?") ? "&" : "?"
        "#{url}#{separator}#{UTM}"
      end
    end
  end
end
