require 'rails_helper'

Rspec.describe 'CreateReservation', type: :service do
  describe '#call' do
    it 'should create reservation for valid data' do
      room = create(:room)
      service = CreateReservation.new(
        external_reservation_id: '01234',
        checkin_date: '2018-06-11',
        checkout_date: '2018-06-16',
        guest_name: 'Tony Stark',
        room_id: room.id
      )

      expect {service.call}.to change {Reservation.count}.by(1)
      expect(room.reload.reservations.find_by(
               external_reservation_id: '01234',
               guest_name: 'Tony Stark',
               checkin_date: Date.parse('2018-06-11'),
               checkout_date: Date.parse('2018-06-16')
        )
      ).to be_present
    end

    it 'should not allow to create double reservations' do
      room = create(:room)
      service = CreateReservation.new(
        external_reservation_id: '01234',
        checkin_date: '2018-06-11',
        checkout_date: '2018-06-16',
        guest_name: 'Tony Stark',
        room_id: room.id
      )

      service.call

      expect { service.call }.to_not change { Reservation.count }
    end

    it 'should return Reservation with errors' do
      room = create(:room)
      service = CreateReservation.new(
        external_reservation_id: '01234',
        checkin_date: '2018-06-11',
        checkout_date: '2018-06-16',
        guest_name: 'Tony Stark',
        room_id: room.id
      )

      service.call
      result = service.call

      expect(result).to be_a_kind_of(Reservation)
      expect(result.errors).not_to be_empty
      expect(result.persisted?).to be false
    end

    it 'should prevent creation of overlapping reservations' do
      room = create(:room)
      CreateReservation.new(
        external_reservation_id: '01234',
        checkin_date: '2018-06-10',
        checkout_date: '2018-06-12',
        guest_name: 'Tony Stark',
        room_id: room.id
      ).call
      service = CreateReservation.new(
        external_reservation_id: '01235',
        checkin_date: '2018-06-11',
        checkout_date: '2018-06-16',
        guest_name: 'Tony Stark',
        room_id: room.id
      )

      result = service.call

      expect(result).to be_a_kind_of(Reservation)
      expect(result.errors).not_to be_empty
      expect(result.persisted?).to be false
    end

    it 'should allow partial reservations of whole apartment' do
      whole_apartment = create(:room)
      room_1 = create(:room, parent: whole_apartment)
      room_2 = create(:room, parent: whole_apartment)
      CreateReservation.new(
        external_reservation_id: '01234',
        checkin_date: '2018-06-10',
        checkout_date: '2018-06-12',
        guest_name: 'Tony Stark',
        room_id: room_1.id
      ).call
      service = CreateReservation.new(
        external_reservation_id: '01235',
        checkin_date: '2018-06-10',
        checkout_date: '2018-06-12',
        guest_name: 'Tony Stark',
        room_id: whole_apartment.id
      )

      result = service.call

      expect(result).to be_a_kind_of(Reservation)
      expect(result.errors).not_to be_empty
      expect(result.persisted?).to be false

      service = CreateReservation.new(
        external_reservation_id: '01235',
        checkin_date: '2018-06-10',
        checkout_date: '2018-06-12',
        guest_name: 'Tony Stark',
        room_id: room_2.id
      )

      expect { service.call }.to change { Reservation.count }.by(1)
    end

    it 'should prevent reservation of apartment single room if the whole apartment is already reserved' do
      whole_apartment = create(:room)
      room = create(:room, parent: whole_apartment)
      create(:room, parent: whole_apartment)

      CreateReservation.new(
        external_reservation_id: '01234',
        checkin_date: '2018-06-10',
        checkout_date: '2018-06-12',
        guest_name: 'Tony Stark',
        room_id: whole_apartment.id
      ).call

      service = CreateReservation.new(
        external_reservation_id: '01235',
        checkin_date: '2018-06-10',
        checkout_date: '2018-06-12',
        guest_name: 'Tony Stark',
        room_id: room.id
      )

      result = service.call

      expect(result).to be_a_kind_of(Reservation)
      expect(result.errors).not_to be_empty
      expect(result.persisted?).to be false
    end
  end
end