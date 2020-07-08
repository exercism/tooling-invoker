module ToolingInvoker
  class TestRunJob < Job

    def initialize(*args)
      super
      @id = "test_run-#{SecureRandom.hex}-#{Time.now.to_i}"
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
  end
end
