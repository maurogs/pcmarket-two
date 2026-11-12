# frozen_string_literal: true

require "test_helper"
require "yaml"

class ApiV1OpenapiTest < ActiveSupport::TestCase
  SPEC_PATH = Rails.root.join("public/api/v1/openapi.yaml")

  test "the OpenAPI document is valid YAML and OpenAPI 3.1" do
    spec = YAML.safe_load_file(SPEC_PATH, permitted_classes: [ Date, Time ], aliases: true)

    assert_equal "3.1.0", spec["openapi"]
    assert_equal "PCMarket API", spec.dig("info", "title")
    assert spec.dig("components", "securitySchemes", "bearerAuth").present?
    assert spec.dig("components", "schemas", "ErrorEnvelope").present?
    assert spec["paths"].is_a?(Hash)
    assert spec["paths"].any?
  end

  test "every API v1 route path is documented" do
    spec = YAML.safe_load_file(SPEC_PATH, permitted_classes: [ Date, Time ], aliases: true)
    documented = spec.fetch("paths").keys.sort
    actual = rails_api_paths.sort

    assert_equal actual, documented
  end

  test "every documented operation has at least one response" do
    spec = YAML.safe_load_file(SPEC_PATH, permitted_classes: [ Date, Time ], aliases: true)

    spec.fetch("paths").each do |path, operations|
      operations.each do |verb, operation|
        next unless %w[get post put patch delete head options].include?(verb)

        assert operation.key?("responses"), "#{verb.upcase} #{path} has no responses"
        assert operation["responses"].any?, "#{verb.upcase} #{path} has no response codes"
      end
    end
  end

  private

  def rails_api_paths
    Rails.application.routes.routes.filter_map do |route|
      path = route.path.spec.to_s
      next unless path.start_with?("/api/v1")

      path = path.sub("(.:format)", "")
      path.gsub(/:([a-z_]+)/, '{\1}')
    end.uniq
  end
end
