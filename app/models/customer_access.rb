class CustomerAccess < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save { self.email = email.downcase.strip }

  def self.allowed?(email)
    exists?(email: email.to_s.downcase.strip)
  end
end
