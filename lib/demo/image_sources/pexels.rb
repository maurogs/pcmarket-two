# frozen_string_literal: true

require "uri"
require "digest"

module Demo
  module ImageSources
    # Pexels API. Requires PEXELS_API_KEY. Attribution is displayed on the
    # credits page even though the Pexels licence does not require it.
    class Pexels < Base
      ENDPOINT = "https://api.pexels.com/v1/search"

      def provider_name
        "pexels"
      end

      def available?
        key.present?
      end

      def skip_reason
        "PEXELS_API_KEY is not set"
      end

      def search(query, limit: 20)
        uri = URI.parse(ENDPOINT)
        uri.query = URI.encode_www_form(query: query, per_page: [ limit, 30 ].min,
                                       orientation: "landscape", size: "large")

        payload = get_json(uri.to_s, headers: { "Authorization" => key })
        Array(payload["photos"]).filter_map do |photo|
          source = photo["src"] || {}
          download = source["large2x"].presence || source["original"].presence || source["large"].presence
          next if download.blank?

          {
            external_id: photo["id"].to_s.presence || Digest::SHA1.hexdigest(download),
            provider: provider_name,
            title: photo["alt"].presence || query,
            download_url: download,
            source_url: photo["url"],
            author: photo["photographer"].presence || "Pexels contributor",
            author_url: photo["photographer_url"],
            license: "Pexels License",
            license_url: "https://www.pexels.com/license/",
            width: photo["width"],
            height: photo["height"]
          }
        end
      end

      private

      def key
        ENV["PEXELS_API_KEY"].presence
      end
    end
  end
end
