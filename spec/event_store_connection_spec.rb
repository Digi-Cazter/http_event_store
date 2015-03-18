require 'spec_helper'

module HttpEventstore
  describe EventStoreConnection do

    let(:client)      { InMemoryEs.new }
    let(:connection)  { EventStoreConnection.new }
    let(:events)      { prepare_events }
    let(:stream_name) { 'teststream' }

    before(:each) do
      allow(connection).to receive(:client).and_return(client)
      client.reset!
      HttpEventstore.configure do |config|
        config.page_size = 3
      end
    end

    specify 'can create new event in stream' do
      create_stream
      expect(client.event_store[stream_name].length).to eq 4
    end

    specify 'can deleted stream in es' do
      create_stream
      expect(client.event_store[stream_name].length).to eq 4
      connection.delete_stream(stream_name)
      expect(client.event_store[stream_name]).to eq nil
    end

    specify 'can load all events backward' do
      create_stream
      events = connection.read_all_events_backward(stream_name)
      expect(events[0][:type]).to eq 'EventType4'
      expect(events[1][:type]).to eq 'EventType3'
      expect(events[2][:type]).to eq 'EventType2'
      expect(events[3][:type]).to eq 'EventType1'
    end

    specify 'can load all events forward' do
      create_stream
      events = connection.read_all_events_forward(stream_name)
      expect(events[0][:type]).to eq 'EventType1'
      expect(events[1][:type]).to eq 'EventType2'
      expect(events[2][:type]).to eq 'EventType3'
      expect(events[3][:type]).to eq 'EventType4'
    end

    private

    def prepare_events
      [
       {event_type: 'EventType1', data: { id: 1 }},
       {event_type: 'EventType2', data: { id: 2 }},
       {event_type: 'EventType3', data: { id: 3 }},
       {event_type: 'EventType4', data: { id: 4 }}
      ]
    end

    def create_stream
      events.each do |event|
        connection.append_to_stream(stream_name, event[:event_type], event[:data])
      end
    end

  end
end
