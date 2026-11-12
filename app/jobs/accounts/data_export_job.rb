# frozen_string_literal: true

module Accounts
  class DataExportJob < ApplicationJob
    queue_as :default

    def perform(user_id)
      user = User.find_by(id: user_id)
      return if user.blank?

      json = JSON.pretty_generate(Accounts::DataExport.new(user).as_json)
      user.data_export.attach(
        io: StringIO.new(json),
        filename: "pcmarket-data-#{user.id}.json",
        content_type: "application/json"
      )

      token = Accounts::ExportToken.generate(user)
      AccountMailer.data_export(user, token).deliver_later
    end
  end
end
