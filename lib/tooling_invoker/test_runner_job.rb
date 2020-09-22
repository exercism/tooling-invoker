module ToolingInvoker
  class TestRunnerJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def invocation_args
      ["bin/run.sh", exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def output_filepaths
      ["results.json"]
    end

    def working_directory
      "/opt/test-runner"
    end

    def tool
      "#{language}-test-runner"
    end
  end
end
