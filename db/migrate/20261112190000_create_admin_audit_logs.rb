# frozen_string_literal: true

class CreateAdminAuditLogs < ActiveRecord::Migration[8.1]
  def up
    create_table :admin_audit_logs do |t|
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.jsonb :changes_data, null: false, default: {}
      t.string :ip
      t.string :user_agent

      t.datetime :created_at, null: false
    end

    add_index :admin_audit_logs, [ :auditable_type, :auditable_id ]
    add_index :admin_audit_logs, [ :action, :created_at ]
    add_index :admin_audit_logs, :created_at
  end

  def down
    drop_table :admin_audit_logs
  end
end
