# frozen_string_literal: true

module LegalPages
  # Creates a new draft from an existing page (usually the latest published
  # version). The original row is never modified, so its history stays intact.
  class CreateVersion
    def initialize(page:, version: nil)
      @page = page
      @version = version.to_s.strip
    end

    def call
      duplicate = @page.dup
      duplicate.assign_attributes(
        version: chosen_version,
        status: :draft,
        published_at: nil,
        effective_at: nil,
        notified_at: nil
      )
      duplicate.body = @page.body.to_s
      duplicate.save!
      duplicate
    end

    private

    def chosen_version
      return @version if @version.present? && available?(@version)

      base = if @page.version.to_s.match?(/\A\d+\z/)
        @page.version.to_i
      else
        nil
      end

      if base
        candidate = base + 1
        candidate += 1 while !available?(candidate.to_s)
        candidate.to_s
      else
        suffix = 2
        suffix += 1 while !available?("#{@page.version}-#{suffix}")
        "#{@page.version}-#{suffix}"
      end
    end

    def available?(version)
      !LegalPage.exists?(country_code: @page.country_code, locale: @page.locale,
                          kind: @page.kind, version: version)
    end
  end
end
