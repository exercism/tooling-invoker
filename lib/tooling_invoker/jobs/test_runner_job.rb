module ToolingInvoker
  module Jobs
    class TestRunnerJob < Job
      def type = "test-runner"
      def required_filepaths = ["results.json"]
      def optional_filepaths = []
    end
  end
end
