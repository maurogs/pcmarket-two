ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module CacheTestHelpers
  def with_cache(store)
    previous = Rails.cache
    Rails.cache = store
    yield
  ensure
    Rails.cache = previous
  end
end

module ModernBrowserRequests
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36"

  # `allow_browser versions: :modern` rejects the default integration-test
  # User-Agent, so every request gets the modern Chrome header unless a test
  # deliberately overrides it.
  def process(method, path, **kwargs)
    headers = (kwargs[:headers] || {}).merge("User-Agent" => MODERN_USER_AGENT)
    super(method, path, **kwargs.merge(headers: headers))
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include CacheTestHelpers

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  prepend ModernBrowserRequests
end
