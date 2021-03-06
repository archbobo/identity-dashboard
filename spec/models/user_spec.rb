require 'rails_helper'

describe User do
  include MailerSpecHelper

  describe 'Associations' do
    it { should have_many(:service_providers) }
  end

  let(:user) { build(:user) }

  describe '#uuid' do
    it 'does not assign uuid on create' do
      user.save
      expect(user.uuid).to be_nil
    end
  end

  describe '#after_create' do
    it 'does not send welcome email' do
      deliveries.clear
      expect(deliveries.count).to eq(0)
      user.save
      expect(deliveries.count).to eq(0)
    end
  end

  describe '#scoped_service_providers' do
    it 'returns user created sps and the users team sps' do
      team = create(:team)
      user.teams = [team]
      user.save
      user_sp = create(:service_provider, user: user)
      team_sp = create(:service_provider, team: team)
      create(:service_provider)
      sorted_sps = [user_sp, team_sp].sort_by { |x| x.friendly_name.downcase }
      expect(user.scoped_service_providers).to eq(sorted_sps)
    end
    it "alphabetizes the list of user created and the user's team sps" do
      team = create(:team)
      user.teams = [team]
      user.save
      sp = {}
      %i[a G c I e].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     user: user, friendly_name: "#{prefix}_service_provider")
      end
      %i[f B h D j].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     team: team, friendly_name: "#{prefix}_service_provider")
      end
      expect(user.scoped_service_providers).to eq(sp.keys.sort.map { |k| sp[k] })
    end
  end

  describe '#scoped_teams' do
    it 'returns collection of users user teams' do
      team = create(:team)
      user.teams = [team]
      user.save

      expect(user.scoped_teams).to eq([team])
    end

    it 'returns all user teams for admins' do
      2.times do
        create(:team)
      end
      user.admin = true
      user.save

      expect(user.scoped_teams).to eq(Team.all)
    end
  end

  describe 'validates' do
    it 'uniqueness of email address' do
      email = 'joe@gsa.gov'
      user.email = email
      user.save
      expect(user).to be_valid
      user_with_same_email = User.new(email: email)
      user_with_same_email.save
      expect(user_with_same_email).not_to be_valid
      user.destroy
      user_with_same_email.save
      expect(user_with_same_email).to be_valid
    end
  end
end
