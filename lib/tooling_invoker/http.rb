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
    CONNECTION = Net::HTTP::Persistent.new(name: 'tooling-invoker').tap do |conn|
      # net-http-persistent defaults to 30s where rest-client allowed 60s.
      # Job output can be large, so keep the old ceiling rather than
      # introducing a new class of timeout under load.
      conn.read_timeout = 60

      # GET /jobs/next mutates state on the orchestrator (it locks the job to
      # this worker), so Net::HTTP's default transparent retry of "idempotent"
      # requests could pop a second job while the first sits locked against a
      # worker that never saw it. Fail loudly instead — the worker loop already
      # retries polling at a higher level.
      conn.max_retries = 0
    end

    class << self
      def get(path)
        uri = uri_for(path)
        perform(uri, Net::HTTP::Get.new(uri))
      end

      def patch(path, payload = {})
        uri = uri_for(path)
        request = Net::HTTP::Patch.new(uri)
        request.body = URI.encode_www_form(flatten_params(payload))
        request.content_type = 'application/x-www-form-urlencoded'

        perform(uri, request)
      end

      private
      # job.output is a Hash of filename => contents, and the orchestrator
      # reads it back as a Hash (params.slice("status", "output")). rest-client
      # encoded that as output[results.json]=contents, which Rack parses back
      # into a nested Hash.
      #
      # Net::HTTP's set_form_data does NOT do this — it calls to_s on a Hash
      # value, which would send a Ruby inspect string and silently corrupt
      # every job result. Hence encoding the nesting ourselves.
      def flatten_params(payload, prefix = nil)
        payload.flat_map do |key, value|
          name = prefix ? "#{prefix}[#{key}]" : key.to_s

          value.is_a?(Hash) ? flatten_params(value, name) : [[name, value.to_s]]
        end
      end

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
