module ToolingInvoker
  module Jobs
    class TestRunnerJob < Job
      def initialize(id, *args)
        super(id, *args)
      end

      def type
        "test_runner"
      end

      def cmd
        "bin/run.sh"
      end

      def invocation_args
        [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
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
end
