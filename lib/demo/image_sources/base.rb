# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "fileutils"
require "open3"
require "securerandom"
require "openssl"

module Demo
  module ImageSources
    # Raised when an API keeps returning 429/5xx after the retry budget. The
    # library backs off from that provider for the rest of the run instead of
    # hammering it.
    class RateLimited < StandardError; end

    # Shared HTTP plumbing for the demo photo providers. Every request has
    # explicit timeouts and a small retry/backoff loop; downloads are validated
    # and resized with ImageMagick before being cached on disk.
    class Base
      MAX_IMAGE_BYTES = 25 * 1024 * 1024
      USER_AGENT = "PCMarketDemoBot/1.0 (+https://pcmarket.example)"
      IMAGE_MAGIC = [
        "\xFF\xD8".b, # JPEG
        "\x89PNG".b,  # PNG
        "GIF8".b,
        "RIFF".b      # WebP
      ].freeze

      attr_reader :skip_reason

      def initialize(logger: Rails.logger, sleeper: nil, request_interval: 1.0)
        @logger = logger
        @sleeper = sleeper || ->(seconds) { sleep(seconds) }
        @request_interval = request_interval
      end

      def provider_name
        self.class.name.split("::").last
                     .gsub(/([a-z])([A-Z])/, '\1-\2')
                     .downcase
      end

      def available?
        true
      end

      # Providers must return an array of hashes with:
      # external_id, provider, title, download_url, source_url, author,
      # author_url, license, license_url and optional track_url.
      def search(_query, limit: 20)
        raise NotImplementedError
      end

      # Optional provider hook (Unsplash requires the download endpoint to be
      # hit when an image is used).
      def track_usage(_entry)
        true
      end

      def download(entry, destination)
        response = request(URI.parse(entry.fetch(:download_url)),
                           headers: download_headers(entry), attempts: 2, throttle: false)
        body = response.body.to_s

        unless response.is_a?(Net::HTTPSuccess) && body.bytesize.positive?
          raise RequestFailed, "download returned #{response.code}"
        end

        content_type = response["content-type"].to_s
        unless content_type.start_with?("image/") || image_magic?(body)
          raise RequestFailed, "download is not an image (#{content_type.presence || 'unknown'})"
        end

        raise RequestFailed, "image is larger than #{MAX_IMAGE_BYTES} bytes" if body.bytesize > MAX_IMAGE_BYTES

        FileUtils.mkdir_p(File.dirname(destination))
        temp = File.join(File.dirname(destination), ".download-#{SecureRandom.hex(6)}")
        File.binwrite(temp, body)
        resize_image(temp, destination)
        true
      ensure
        FileUtils.rm_f(temp) if defined?(temp) && temp
      end

      private

      def api_key
        raise NotImplementedError
      end

      def download_headers(_entry)
        { "User-Agent" => USER_AGENT }
      end

      def get_json(url, headers: {})
        request(URI.parse(url), headers: headers, attempts: 3).body.to_s.then do |body|
          JSON.parse(body)
        rescue JSON::ParserError => e
          raise RequestFailed, "invalid JSON: #{e.message}"
        end
      end

      def request(uri, headers: {}, attempts: 3, redirects: 3, throttle: true)
        raise ArgumentError, "not an HTTP(S) URL: #{uri}" unless uri.is_a?(URI::HTTP)

        attempt = 0

        loop do
          attempt += 1
          wait_before_request if throttle
          response = perform(uri, headers)

          case response
          when Net::HTTPSuccess
            return response
          when Net::HTTPRedirection
            raise RequestFailed, "too many redirects" if redirects <= 0

            location = response["location"].to_s
            return request(URI.join(uri, location), headers: headers,
                           attempts: attempts, redirects: redirects - 1, throttle: throttle)
          when Net::HTTPTooManyRequests, Net::HTTPServerError, Net::HTTPRequestTimeout
            raise RateLimited, "#{provider_name} responded #{response.code}" if attempt >= attempts

            backoff(attempt, response)
          else
            raise RequestFailed, "#{provider_name} responded #{response.code} for #{uri}"
          end
        end
      end

      def perform(uri, headers)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 25

        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "application/json, image/*;q=0.9, */*;q=0.5"
        headers.each { |key, value| request[key] = value }

        http.start { |connection| connection.request(request) }
      rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
        raise RequestFailed, "#{provider_name} request failed: #{e.message}"
      end

      def wait_before_request
        @sleeper.call(@request_interval) if @request_interval.to_f.positive?
      end

      def backoff(attempt, response)
        retry_after = response["retry-after"].to_i
        delay = if response.code.to_i == 429
                  retry_after.positive? ? retry_after : 2**attempt
        else
                  2**attempt
        end
        delay = [ delay, 30 ].min
        @logger&.warn("[demo:images] #{provider_name} throttled, retrying in #{delay}s")
        @sleeper.call(delay)
      end

      def image_magic?(body)
        IMAGE_MAGIC.any? { |magic| body.start_with?(magic) }
      end

      # `magick input -resize 1600x1600> output` only shrinks images; small
      # source files are copied through unchanged. WebP/PNG are converted to
      # JPEG so all demo photos share one content type.
      def resize_image(source, destination)
        _out, err, status = Open3.capture3(
          "magick", source,
          "-auto-orient",
          "-resize", "1600x1600>",
          "-quality", "85",
          "jpg:" + destination
        )
        raise RequestFailed, "ImageMagick failed: #{err}" unless status.success?

        raise RequestFailed, "ImageMagick produced no output" unless File.size?(destination)
      rescue Errno::ENOENT
        # No ImageMagick: keep the original bytes rather than failing the run.
        FileUtils.mv(source, destination)
      end
    end

    class RequestFailed < StandardError; end

    # The retry loop above raises RequestFailed after the retry budget for
    # provider errors, which the library logs and skips.
  end
end
