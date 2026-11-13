# frozen_string_literal: true

module TranslatableFieldsHelper
  # Renders a jsonb-translated attribute as six tabbed inputs (ES first, then
  # EN/FR/DE/IT/PT). Spanish is required; the other locales may be empty and
  # fall back through Mobility/I18n.
  def translatable_form_field(form, record, attribute, label:, type: :text, required: true, rows: 4)
    render "admin/shared/translatable_fields",
           form: form,
           record: record,
           attribute: attribute,
           label: label,
           type: type,
           required: required,
           rows: rows
  end
end
