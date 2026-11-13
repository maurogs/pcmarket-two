# frozen_string_literal: true

module Demo
  # ImageMagick needs an explicit font path on macOS and some minimal Linux
  # containers. Returns nil when none of the common system fonts exist, in which
  # case placeholders fall back to a textless gradient.
  module Fonts
    CANDIDATES = [
      "/System/Library/Fonts/Supplemental/Arial.ttf",
      "/System/Library/Fonts/Helvetica.ttc",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
      "/usr/share/fonts/dejavu/DejaVuSans.ttf",
      "C:/Windows/Fonts/arial.ttf"
    ].freeze

    def self.path
      @path ||= CANDIDATES.find { |candidate| File.file?(candidate) }
    end
  end
end
