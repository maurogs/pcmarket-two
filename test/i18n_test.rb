require "test_helper"
require "i18n/tasks"

class I18nTest < ActiveSupport::TestCase
  def setup
    @i18n = I18n::Tasks::BaseTask.new
  end

  def test_no_missing_keys
    missing = @i18n.missing_keys
    assert_empty missing, "Missing keys: #{missing.inspect}"
  end

  def test_no_unused_keys
    unused = @i18n.unused_keys
    assert_empty unused, "Unused keys: #{unused.inspect}"
  end
end
