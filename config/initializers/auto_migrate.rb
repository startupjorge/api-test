# Automatically run pending migrations on boot.
# Keeps Railway/production in sync without manual steps.
Rails.application.config.after_initialize do
  begin
    ActiveRecord::Migration.check_all_pending!
  rescue ActiveRecord::PendingMigrationError
    begin
      Rails.logger.info "[auto_migrate] Running pending migrations..."
      ActiveRecord::MigrationContext.new(
        Rails.root.join("db/migrate").to_s
      ).migrate
      Rails.logger.info "[auto_migrate] Migrations complete."
    rescue => e
      Rails.logger.error "[auto_migrate] Migration failed: #{e.message}"
    end
  rescue => e
    Rails.logger.error "[auto_migrate] Check failed: #{e.message}"
  end
end
