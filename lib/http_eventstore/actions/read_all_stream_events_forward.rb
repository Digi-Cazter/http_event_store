module HttpEventstore
  class ReadAllStreamEventsForward < ReadAllStreamEvents

    def initialize(client)
      super(client)
      @start_point = 0
      @count = HttpEventstore.configuration.page_size
    end

    private
    attr_reader :start_point, :count

    def append_entries(entries, batch)
      entries + batch.reverse!
    end

    def get_stream_batch(stream_name, start)
      if start.nil?
        read_stream_forward(stream_name, start_point, count)
      else
        read_stream_by_url(start)
      end
    end

    def read_stream_forward(stream_name, next_id, count)
      client.read_stream_forward(stream_name, next_id, count)
    end

    def read_stream_by_url(uri)
      client.read_stream_page(uri)
    end

    def get_next_start_point(links)
      link = links.detect { |link| link['relation'] == 'previous' }
      unless link.nil?
        link['uri'].slice! HttpEventstore.configuration.get_store_url
        link['uri']
      end
    end
  end
end
