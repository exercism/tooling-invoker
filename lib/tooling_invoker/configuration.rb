module ToolingInvoker
  class Configuration
    include Singleton
    class << self
      extend Forwardable
      def_delegators :instance, :containers_dir, 
                                :jobs_dir,
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
        region: "eu-west-2",
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
      orchestrator_host = ENV.fetch("ORCHESTRATOR_HOST", "127.0.0.1")
      "http://#{orchestrator_host}:3021"
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

    def jobs_dir
      case env
      when :production
        File.expand_path('/opt/jobs')
      else
        File.expand_path("/tmp/exercism-tooling-jobs")
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
