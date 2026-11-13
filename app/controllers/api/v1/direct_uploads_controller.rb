# frozen_string_literal: true

module Api
  module V1
    class DirectUploadsController < AuthenticatedController
      def create
        blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)
        render_data(
          blob.as_json(root: false, methods: :signed_id).merge(
            "direct_upload" => {
              "url" => blob.service_url_for_direct_upload,
              "headers" => blob.service_headers_for_direct_upload
            }
          ),
          status: :created
        )
      end

      private

      def blob_args
        params.expect(blob: [ :filename, :byte_size, :checksum, :content_type, metadata: {} ])
              .to_h.symbolize_keys
      end
    end
  end
end
