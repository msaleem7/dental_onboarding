class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :candidate_profile, dependent: :destroy

  enum :role, Users::Roles::ENUM_MAPPING, default: Users::Roles::CANDIDATE

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create_commit :ensure_candidate_profile!

  private

  def ensure_candidate_profile!
    Users::EnsureCandidateProfileService.call(self)
  end
end
