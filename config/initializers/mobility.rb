Mobility.configure do
  plugins do
    backend :jsonb
    active_record
    reader
    writer
    query
    fallbacks
    presence
    locale_accessors %i[es en fr de it pt]
  end
end
