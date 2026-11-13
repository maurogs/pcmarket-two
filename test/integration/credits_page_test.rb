# frozen_string_literal: true

require "test_helper"

class CreditsPageTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.delete(Demo::ImageCredits::CACHE_KEY)
    @listing = listings(:published_gpu)
    @photo = @listing.photos.create!(position: 0)
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("listing.png").open,
      filename: "demo-credits.png",
      content_type: "image/png",
      metadata: {
        demo_provider: "openverse",
        demo_source_url: "https://example.com/photos/credits",
        demo_author: "Ada Lovelace",
        demo_author_url: "https://example.com/ada",
        demo_license: "CC BY 4.0",
        demo_license_url: "https://creativecommons.org/licenses/by/4.0/",
        demo_title: "A graphics card"
      }
    )
    @photo.image.attach(@blob)
  end

  teardown do
    Rails.cache.delete(Demo::ImageCredits::CACHE_KEY)
  end

  test "renders every used demo image with author, provider, licence and source" do
    get credits_path

    assert_response :success
    assert_includes response.body, I18n.t("credits.title")
    assert_includes response.body, "openverse"
    assert_includes response.body, "Ada Lovelace"
    assert_includes response.body, "CC BY 4.0"
    assert_includes response.body, "https://example.com/ada"
    assert_includes response.body, "https://example.com/photos/credits"
    assert_includes response.body, "https://creativecommons.org/licenses/by/4.0/"
    assert_includes response.body, "hover:text-content\" href=\"/credits\">#{I18n.t('footer.legal.image_credits')}</a>"
  end

  test "renders an empty state without demo photos" do
    @blob.update!(metadata: {})
    Rails.cache.delete(Demo::ImageCredits::CACHE_KEY)

    get credits_path

    assert_response :success
    assert_includes response.body, I18n.t("credits.empty")
    assert_not_includes response.body,
                        "hover:text-content\" href=\"/credits\">#{I18n.t('footer.legal.image_credits')}</a>"
  end
end
