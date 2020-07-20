module ToolingInvoker
  class Configuration
    include Singleton
    class << self
      extend Forwardable
      def_delegators :instance, :containers_dir, 
                                :orchestrator_address, 
                                :invoker, 
                                :s3_config
    end

    def invoker
      case env
      when :development
        InvokeLocally
      else
        InvokeRunc
      end
    end

    def s3_config
      config = {
        region: "eu-west-1",
        http_idle_timeout: 0,
      }
      if env == :development
        if ENV["AWS_ACCESS_KEY_ID"]
          config[:access_key_id] = ENV["AWS_ACCESS_KEY_ID"]
          config[:secret_access_key] = ENV["AWS_SECRET_ACCESS_KEY"]
        else
          config[:profile] = "exercism_tooling_invoker"
        end
      end
      config
    end

    def orchestrator_address
      "http://localhost:3020"
    end

    def containers_dir
      case env
      when :test
        File.expand_path("../../../test/fixtures/containers", __FILE__)
      when :development
        File.expand_path("../../../..", __FILE__)
      when :production
        File.expand_path('/opt/containers')
      end
    end

    def env
      @env ||= case ENV["APP_ENV"].to_s
        when "test"
          :test
        when "production"
          :production
        else
          :development
        end
    end
  end
end
