require 'test_helper'

module ToolingInvoker
  class TestRunTest < Minitest::Test
    def test_everything_is_set_correctly
      test_run = TestRun.new('bob')
      assert_equal ['bin/run.sh', 'bob', "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"], test_run.invocation_args
      assert_equal "results.json", test_run.results_filepath
      assert_equal "/opt/test-runner", test_run.working_directory
    end
  end
end

