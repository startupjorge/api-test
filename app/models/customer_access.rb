class CustomerAccess
  def self.allowed?(email)
    Customer.allowed?(email)
  rescue
    env_emails.include?(email.to_s.downcase.strip)
  end

  def self.api_key_for(email)
    Customer.api_key_for(email)
  rescue
    nil
  end

  def self.all_with_keys
    Customer.order(:email).map { |c| { email: c.email, api_key: c.api_key } }
  rescue
    []
  end

  private

  def self.env_emails
    ENV.fetch("CUSTOMER_EMAILS", "").split(",").map(&:strip).map(&:downcase).reject(&:blank?)
  end
end
