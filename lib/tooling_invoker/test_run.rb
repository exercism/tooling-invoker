module ToolingInvoker
  class TestRun < ContainerRun

    def invocation_args
      ["bin/run.sh", exercise_slug, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def results_filepath
      "results.json"
    end

    def working_directory
      "/opt/test-runner"
    end
  end
end
