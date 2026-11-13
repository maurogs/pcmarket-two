# frozen_string_literal: true

require "uri"
require "digest"

module Demo
  module ImageSources
    # Pixabay API. Requires PIXABAY_API_KEY. Their terms ask clients to cache
    # results (the library caches every downloaded file locally).
    class Pixabay < Base
      ENDPOINT = "https://pixabay.com/api/"

      def provider_name
        "pixabay"
      end

      def available?
        key.present?
      end

      def skip_reason
        "PIXABAY_API_KEY is not set"
      end

      def search(query, limit: 20)
        uri = URI.parse(ENDPOINT)
        uri.query = URI.encode_www_form(
          key: key,
          q: query,
          image_type: "photo",
          orientation: "horizontal",
          safesearch: "true",
          per_page: [ limit, 20 ].min
        )

        payload = get_json(uri.to_s)
        Array(payload["hits"]).filter_map do |hit|
          download = hit["largeImageURL"].presence || hit["webformatURL"].presence
          next if download.blank?

          user_id = hit["user_id"]
          author_url = user_id.present? ? "https://pixabay.com/users/#{hit['user']}-#{user_id}/" : nil

          {
            external_id: hit["id"].to_s.presence || Digest::SHA1.hexdigest(download),
            provider: provider_name,
            title: hit["tags"].presence || query,
            download_url: download,
            source_url: hit["pageURL"],
            author: hit["user"].presence || "Pixabay contributor",
            author_url: author_url,
            license: "Pixabay Content License",
            license_url: "https://pixabay.com/service/license-summary/",
            width: hit["imageWidth"],
            height: hit["imageHeight"]
          }
        end
      end

      private

      def key
        ENV["PIXABAY_API_KEY"].presence
      end
    end
  end
end
