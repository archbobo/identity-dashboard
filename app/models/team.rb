class Team < ApplicationRecord
  self.table_name = :groups

  belongs_to :agency

  has_many :service_providers, dependent: :nullify, foreign_key: 'group_id',
                               inverse_of: :team
  has_many :user_teams, dependent: :nullify, foreign_key: 'group_id',
                        inverse_of: :team
  has_many :users, through: :user_teams

  validates :name, presence: true, uniqueness: true

  after_update :update_service_providers

  def to_s
    name
  end

  def update_service_providers
    service_providers.each do |sp|
      sp.update(agency_id: agency.id) if agency
    end
  end
end
