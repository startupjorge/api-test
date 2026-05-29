class CustomerAccess
  def self.allowed?(email)
    allowed_emails.include?(email.to_s.downcase.strip)
  end

  def self.all_emails
    allowed_emails
  end

  private

  def self.allowed_emails
    raw = ENV.fetch("CUSTOMER_EMAILS", "")
    raw.split(",").map(&:strip).map(&:downcase).reject(&:blank?)
  end
end
