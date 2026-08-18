module ToolingInvoker
  # Every worker thread polls GET /jobs/next several times a second, so the
  # cost of *establishing* connections dominates the cost of the requests
  # themselves. rest-client builds a fresh TCP connection (and, now that the
  # orchestrator is behind an HTTPS load balancer, a fresh TLS handshake) for
  # every call, which measured at ~63 new connections/sec against ~57
  # requests/sec — essentially no reuse at all.
  #
  # Net::HTTP::Persistent keeps a connection pool keyed by thread and origin,
  # so each worker reuses its own connection across polls. It is thread-safe:
  # one shared instance is correct, and threads never share a socket.
  module Http
    NotFound = Class.new(StandardError)
    RequestFailed = Class.new(StandardError)

    # Opens no sockets — it's a pool object, built once at load time and shared
    # by every worker thread.
    CONNECTION = Net::HTTP::Persistent.new(name: 'tooling-invoker')

    class << self
      def get(path)
        uri = uri_for(path)
        perform(uri, Net::HTTP::Get.new(uri))
      end

      def patch(path, payload = {})
        uri = uri_for(path)
        request = Net::HTTP::Patch.new(uri)

        # Matches how rest-client encoded a Hash body, which is what the
        # orchestrator's params parsing expects.
        request.set_form_data(payload)

        perform(uri, request)
      end

      private
      def perform(uri, request)
        response = CONNECTION.request(uri, request)

        case response
        when Net::HTTPNotFound then raise NotFound
        when Net::HTTPSuccess then response
        else
          raise RequestFailed, "#{request.method} #{uri} returned #{response.code}"
        end
      end

      def uri_for(path)
        URI.parse("#{base_url}#{path}")
      end

      # Net::HTTP::Persistent requires an absolute URI, where rest-client would
      # quietly prepend http:// to a bare host. Production sets an explicit
      # https:// scheme; this keeps a scheme-less development value working.
      def base_url
        address = ToolingInvoker.config.orchestrator_address
        address.to_s.match?(%r{\Ahttps?://}) ? address : "http://#{address}"
      end
    end
  end
end
