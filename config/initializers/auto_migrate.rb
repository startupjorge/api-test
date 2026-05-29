# Automatically run pending migrations on boot.
# Keeps Railway/production in sync without manual steps.
if defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.present?
  begin
    ActiveRecord::Migration.check_all_pending!
  rescue ActiveRecord::PendingMigrationError
    Rails.logger.info "[auto_migrate] Running pending migrations..."
    ActiveRecord::MigrationContext.new(
      Rails.root.join("db/migrate").to_s,
      ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection)
    ).migrate
    Rails.logger.info "[auto_migrate] Migrations complete."
  end
end
