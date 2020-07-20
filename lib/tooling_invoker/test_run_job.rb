module ToolingInvoker
  class TestRunJob < Job

    def initialize(iteration_id, *args)
      id = "test_run-#{iteration_id}-#{SecureRandom.hex}"
      super(id, iteration_id, *args)
    end

    def invocation_args
      ["bin/run.sh", exercise_slug, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def results_filepath
      "results.json"
    end

    def working_directory
      "/opt/test-runner"
    end

    def tooling_slug
      "#{language_slug}-test-runner"
    end
  end
end
