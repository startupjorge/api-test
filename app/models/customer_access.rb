class CustomerAccess
  def self.allowed?(email)
    allowed_emails.include?(email.to_s.downcase.strip)
  end

  def self.all_emails
    allowed_emails
  end

  def self.api_key_for(email)
    raw = ENV.fetch("CUSTOMER_KEYS", "")
    raw.split(",").each do |pair|
      e, k = pair.strip.split(":", 2)
      return k.to_s.strip if e.to_s.strip.downcase == email.to_s.downcase.strip && k.to_s.strip.present?
    end
    nil
  end

  def self.all_with_keys
    allowed_emails.map do |email|
      { email: email, api_key: api_key_for(email) }
    end
  end

  private

  def self.allowed_emails
    raw = ENV.fetch("CUSTOMER_EMAILS", "")
    raw.split(",").map(&:strip).map(&:downcase).reject(&:blank?)
  end
end
