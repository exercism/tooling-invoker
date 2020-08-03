module ToolingInvoker
  class Configuration
    include Singleton

    def invoker
      if Exercism.environment == :development
        if ENV["EXERCISM_INVOKE_VIA_DOCKER"]
          InvokeDocker
        else
          InvokeLocally
        end
      else
        InvokeRunc
      end
    end

    def orchestrator_address
      Exercism.config.tooling_orchestrator_url
    end

    def containers_dir
      case Exercism.environment
      when :test
        File.expand_path('../../test/fixtures/containers', __dir__)
      when :development
        File.expand_path('../../..', __dir__)
      when :production
        File.expand_path('/opt/containers')
      end
    end

    def jobs_dir
      case Exercism.environment
      when :production
        File.expand_path('/opt/jobs')
      else
        File.expand_path("/tmp/exercism-tooling-jobs")
      end
    end
  end
end
