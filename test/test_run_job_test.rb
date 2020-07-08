require 'test_helper'

module ToolingInvoker
  class TestRunJobTest < Minitest::Test
    def test_everything_is_set_correctly
      Timecop.freeze do
        hex = "some-hex"
        SecureRandom.expects(:hex).returns(hex)

        test_run = TestRunJob.new('bob')
        assert_equal "test_run-#{hex}-#{Time.now.to_i}", test_run.id
        assert_equal ['bin/run.sh', 'bob', "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"], test_run.invocation_args
        assert_equal "results.json", test_run.results_filepath
        assert_equal "/opt/test-runner", test_run.working_directory
      end
    end
  end
end

