module ToolingInvoker
  class Configuration
    include Singleton

    def invoker
      if Exercism.env.development?
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
      if Exercism.env.test?
        File.expand_path('../../test/fixtures/containers', __dir__)
      elsif Exercism.env.development?
        File.expand_path('../../..', __dir__)
      elsif Exercism.env.production?
        File.expand_path('/opt/containers')
      end
    end

    def jobs_dir
      if Exercism.env.production?
        File.expand_path('/opt/jobs')
      else
        File.expand_path("/tmp/exercism-tooling-jobs")
      end
    end
  end
end
