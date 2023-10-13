module ToolingInvoker
  module Jobs
    class TestRunnerJob < Job
      def type = "test-runner"
      def cmd = "bin/run.sh"
      def invocation_args = [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
      def output_filepaths = ["results.json"]
      def optional_filepaths = []
      def working_directory = "/opt/test-runner"
    end
  end
end
