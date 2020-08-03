module ToolingInvoker
  class Configuration
    include Singleton

    def invoker
      if Exercism.environment == :development
        ENV["EXERCISM_INVOKE_VIA_DOCKER"] ?
          InvokeDocker : InvokeLocally 
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
        File.expand_path("../../../test/fixtures/containers", __FILE__)
      when :development
        File.expand_path("../../../..", __FILE__)
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
