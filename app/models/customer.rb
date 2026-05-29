class Customer < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  before_save { self.email = email.downcase.strip }

  def self.allowed?(email)
    exists?(email: email.to_s.downcase.strip)
  end

  def self.api_key_for(email)
    find_by(email: email.to_s.downcase.strip)&.api_key&.presence
  end
end
