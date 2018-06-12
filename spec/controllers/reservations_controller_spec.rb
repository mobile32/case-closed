require 'rails_helper'

Rspec.describe 'ReservationsController', type: :controller do
  describe 'POST#create' do
    it 'should return (201) response if reservation can be created' do
      room = create(:room)
      params = {
          reservationId: '01234',
          checkinDate: '2018-06-11',
          checkoutDate: '2018-06-16',
          guestName: 'Tony Stark',
          roomId: room.id
      }.to_json

      post :create, params

      expect(response).to have_http_status(:created)
    end

    it 'should return (409) response if reservation failed' do
      params = {
          reservationId: '01234',
          checkinDate: '2018-06-11',
          checkoutDate: '2018-06-16',
          guestName: 'Tony Stark',
          roomId: ''
      }.to_json

      post :create, params

      expect(response).to have_http_status(409)
      response_errors = JSON.parse(response.body)['errors']
      expect(response_errors).not_to be_empty
    end
  end
end