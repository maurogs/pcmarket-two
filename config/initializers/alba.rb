# frozen_string_literal: true

# Alba serialises through ActiveSupport::JSON so it matches Rails' encoder
# (dates, BigDecimal, etc.) without an extra dependency.
Alba.backend = :active_support
