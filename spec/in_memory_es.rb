require 'json'

module HttpEventstore
  class InMemoryEs

    def initialize
      @event_store = {}
    end
    attr_reader :event_store

    def append_to_stream(stream_name, event_data, expected_version)
      unless event_store.key?(stream_name)
        event_store[stream_name] = []
      end
      id = event_store[stream_name].length
      event_store[stream_name].unshift({'eventId' => event_data.event_id, 'data' => event_data.data.to_json, 'eventType' => event_data.type, 'positionEventNumber' => id})
    end

    def delete_stream(stream_name, hard_delete)
      event_store.delete(stream_name)
    end

    def read_stream_backward(stream_name, start, count)
      if event_store.key?(stream_name)
        start_index = start == :head ? event_store[stream_name].length - 1 : start
        last_index = start_index - count
        entries = event_store[stream_name].select do |event|
          event['positionEventNumber'] > last_index && event['positionEventNumber'] <= start_index
        end
        { 'entries' => entries, 'links' => links(last_index, stream_name, 'next', entries)}
      end
    end

    def read_stream_forward(stream_name, start_index, count, long_pool = false)
      if event_store.key?(stream_name)
        last_index = start_index + count
        entries = event_store[stream_name].reverse.select do |event|
          event['positionEventNumber'] < last_index && event['positionEventNumber'] >= start_index
        end
        { 'entries' => entries.reverse!, 'links' => links(last_index, stream_name, 'previous', entries)}
      end
    end

    def reset!
      @event_store = {}
    end

    private

    def links(batch_size, stream_name, direction, entries)
      if entries.empty? || batch_size < 0
        []
      else
        [{
             'uri' => "http://127.0.0.1:2113/strams/#{stream_name}/#{batch_size}/direction/3",
             'relation' => direction
         }]
      end
    end

  end
end
