# frozen_string_literal: true

module Sitemaps
  # Regenerates public/sitemaps/*.xml.gz. Scheduled daily at 03:00 by
  # config/recurring.yml. The files are written atomically by the gem.
  class GenerateJob < ApplicationJob
    queue_as :default

    def perform
      SitemapGenerator::Interpreter.run
    end
  end
end
