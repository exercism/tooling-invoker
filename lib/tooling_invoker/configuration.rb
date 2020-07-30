module ToolingInvoker
  class Configuration
    include Singleton
    class << self
      extend Forwardable
      def_delegators :instance, :containers_dir, 
                                :jobs_dir,
                                :orchestrator_address, 
                                :invoker 
    end

    def invoker
      return InvokeDocker if ENV["EXERCISM_INVOKE_VIA_DOCKER"]
      return InvokeLocally if env == :development
      InvokeRunc
    end

    def orchestrator_address
      Exercism.config.tooling_orchestrator_url
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
      @env ||= case ENV["EXERCISM_ENV"].to_s
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
