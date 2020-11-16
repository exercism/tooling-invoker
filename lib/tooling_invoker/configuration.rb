module ToolingInvoker
  class Configuration
    include Singleton

    def invoker
      return InvokeDocker unless Exercism.env.development?

      case ENV["EXERCISM_INVOKE_STATEGY"]
      when "shell"
        InvokeLocalShell
      when "docker"
        InvokeDocker
      else
        InvokeLocalWebserver
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
      end
    end

    def job_polling_delay
      (ENV["JOB_POLLING_DELAY"] || 1).to_f
    end

    def jobs_efs_dir
      if Exercism.env.production?
        File.expand_path('/mnt/jobs')
      else
        File.expand_path("/tmp/exercism-tooling-jobs-efs")
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
