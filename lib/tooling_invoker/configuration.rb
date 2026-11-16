module ToolingInvoker
  class Configuration
    include Singleton
    extend Mandate::Memoize

    def orchestrator_address
      Exercism.config.tooling_orchestrator_url
    end

    def image_registry
      Exercism.env.development? ? "exercism" : Exercism.config.tooling_ecr_repository_url
    end

    def image_tag
      Exercism.env.development? ? "latest" : "production"
    end

    def job_polling_delay
      (ENV["JOB_POLLING_DELAY"] || 0.6).to_f
    end

    # The invoker asks the orchestrator to wait up to this many seconds for a
    # job, so that it doesn't need to keep asking. An older orchestrator
    # ignores this and answers straight away, as it always has. This must stay
    # well below Http::READ_TIMEOUT, so that the request never times out
    # while it waits.
    JOB_POLL_WAIT = 20
    def job_poll_wait = JOB_POLL_WAIT

    def jobs_dir
      if Exercism.env.production?
        File.expand_path('/opt/jobs')
      else
        File.expand_path("/tmp/exercism/tooling-jobs")
      end
    end

    def max_memory_for_tool(tool)
      tool_setting(tool, "max_memory", "3GB")
    end

    def network_for_tool(tool)
      tool_setting(tool, "network", "none")
    end

    def timeout_for_tool(tool)
      tool_setting(tool, "timeout", 20).to_i
    end

    private
    def tool_setting(tool, setting, default)
      tool_config(tool)&.fetch(setting, default) || default
    end

    def tool_config(tool)
      tools_config[tool.tr('-', '_')]
    end

    memoize
    def tools_config
      JSON.parse(File.read(File.expand_path('../../tools.json', __dir__)))
    end
  end
end
