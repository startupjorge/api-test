class CustomQuery < ApplicationRecord
  validates :name,       presence: true
  validates :query_key,  presence: true, uniqueness: true,
                         format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, underscores" }
  validates :value_path, presence: true

  before_validation :generate_key, on: :create

  scope :active, -> { where(active: true) }

  # Dig into a nested hash using dot-notation path e.g. "scores.overallScore"
  def extract_value(hash)
    value_path.split(".").reduce(hash) do |obj, key|
      obj.is_a?(Hash) ? (obj[key] || obj[key.to_sym]) : nil
    end
  end

  private

  def generate_key
    return if query_key.present?
    self.query_key = name.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
  end
end
