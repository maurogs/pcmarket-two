# frozen_string_literal: true

require "uri"
require "digest"

module Demo
  module ImageSources
    # Openverse aggregates CC-licensed media and works without an API key.
    # Anonymous traffic is rate limited, so requests are spaced out and 429s are
    # retried with exponential backoff (honouring Retry-After).
    class Openverse < Base
      ENDPOINT = "https://api.openverse.org/v1/images/"
      LICENSES = "cc0,pdm,by,by-sa"

      def initialize(**options)
        super(request_interval: options.delete(:request_interval) || 2.0, **options)
      end

      def search(query, limit: 20)
        uri = URI.parse(ENDPOINT)
        uri.query = URI.encode_www_form(
          q: query,
          license: LICENSES,
          page_size: [ limit, 20 ].min,
          mature: "false"
        )

        payload = get_json(uri.to_s)
        Array(payload["results"]).filter_map do |result|
          url = result["url"].presence
          next if url.blank?

          {
            external_id: result["id"].presence || Digest::SHA1.hexdigest(url),
            provider: provider_name,
            title: result["title"].presence || query,
            # Openverse proxies thumbnails through its own API. Many upstream
            # hosts (Flickr in particular) reject hotlinking with a 403, so the
            # proxy is both faster and more reliable; the full-resolution URL is
            # kept as a fallback.
            download_url: result["thumbnail"].presence || url,
            fallback_url: result["thumbnail"].present? ? url : nil,
            source_url: result["foreign_landing_url"].presence || result["detail_url"],
            author: result["creator"].presence || "Unknown",
            author_url: result["creator_url"].presence,
            license: license_label(result),
            license_url: license_url(result),
            width: result["width"],
            height: result["height"]
          }
        end
      end

      private

      def license_label(result)
        code = result["license"].to_s.upcase
        version = result["license_version"].presence
        [ code, version ].compact.join(" ")
      end

      def license_url(result)
        code = result["license"].to_s.downcase
        version = result["license_version"].presence || "1.0"

        case code
        when "cc0" then "https://creativecommons.org/publicdomain/zero/1.0/"
        when "pdm" then "https://creativecommons.org/publicdomain/mark/1.0/"
        when "by" then "https://creativecommons.org/licenses/by/#{version}/"
        when "by-sa" then "https://creativecommons.org/licenses/by-sa/#{version}/"
        else "https://creativecommons.org/licenses/"
        end
      end
    end
  end
end
