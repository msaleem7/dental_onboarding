class Language < ApplicationRecord
  has_many :candidate_languages, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
