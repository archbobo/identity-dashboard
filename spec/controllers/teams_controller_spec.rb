require 'rails_helper'

describe TeamsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:org) { create(:team) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#new' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end
      it 'has a success response' do
        get :new
        expect(response.status).to eq(200)
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        get :new
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#index' do
    context 'when the user is signed in' do
      it 'has a success response' do
        get :index
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a redirect response' do
        get :index
        expect(response.status).to eq(302)
      end
    end
  end

  describe '#show' do
    context 'when admin' do
      before do
        user.admin = true
      end

      it 'shows the team template' do
        get :show, params: { id: org.id }
        expect(response).to render_template(:show)
      end
    end

    context 'when not an admin but a team member' do
      before do
        org.users << user
      end

      it 'shows the team template' do
        get :show, params: { id: org.id }
        expect(response).to render_template(:show)
      end
    end
  end

  describe '#create' do
    context 'when the user is not an admin' do
      it 'has an error response' do
        post :create, params: { team: { name: 'unique name' } }
        expect(response.status).to eq(401)
      end
    end

    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      context 'when it creates successfully' do
        it 'has a redirect response' do
          post :create, params: { team: { name: 'unique name' }, new_user: { email: '' } }
          expect(response.status).to eq(302)
        end
      end
      context 'when it fails to create' do
        it 'renders #new' do
          post :create, params: { team: { name: '' }, new_user: { email: '' } }
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe '#destroy' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a redirect response' do
        delete :destroy, params: { id: org.id }
        expect(response.status).to eq(302)
      end
    end
    context 'when the user is not an admin'
    it 'has an error response' do
      delete :destroy, params: { id: org.id }
      expect(response.status).to eq(401)
    end
  end

  describe '#edit' do
    context 'when admin' do
      before do
        user.admin = true
      end
      it 'shows the edit template' do
        get :edit, params: { id: org.id }
        expect(response).to render_template(:edit)
      end
    end

    context 'when not an admin but a team member' do
      before do
        user.admin = false
        org.users << user
      end

      it 'shows the edit template' do
        get :edit, params: { id: org.id }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    context 'when user is an admin' do
      before do
        user.admin = true
      end

      context 'when the update is successful' do
        it 'has a redirect response' do
          patch :update, params: { id: org.id, team: { name: org.name }, new_user: { email: '' } }
          expect(response.status).to eq(302)
        end
      end

      context 'when the update is unsuccessful' do
        before do
          allow_any_instance_of(Team).to receive(:update).and_return(false)
        end

        it 'renders the edit action' do
          patch :update, params: { id: org.id, team: { name: org.name, user_ids: [user.id.to_s] }, new_user: { email: '' } }
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not an admin but a member of the team' do
      before do
        user.admin = false
        org.users << user
      end

      context 'when the update includes adding a new user' do
        let(:new_user) { create(:user) }

        it 'adds the user to the team' do
          patch :update, params: { id: org.id, team: { name: org.name, user_ids: [user.id.to_s] },
                                   new_user: { email: new_user.email } }
          expect(org.users.include?(new_user)).to be true
        end
      end
    end

    context 'when user is neither a admin nor a team member' do
      it 'has an unauthorized response' do
        patch :update, params: { id: org.id, team: { name: org.name, user_ids: [user.id.to_s] }, new_user: { email: '' } }
        expect(response.status).to eq(401)
      end
    end
  end
end
