require 'test_helper'

module ToolingInvoker::Jobs
  class AnalyzerJobTest < Minitest::Test
    def test_everything_is_set_correctly
      job_id = "213"
      language = "ruby"
      exercise = "bob"
      container_version = "v3"
      timeout = "10"

      test_run = AnalyzerJob.new(job_id, language, exercise, container_version, timeout)
      assert_equal job_id, test_run.id
      assert_equal language, test_run.language
      assert_equal exercise, test_run.exercise
      assert_equal container_version, test_run.container_version
      assert_equal timeout, test_run.timeout_s
      assert_equal [
        'bin/run.sh',
        'bob',
        "/mnt/exercism-iteration/",
        "/mnt/exercism-iteration/"
      ], test_run.invocation_args
      assert_equal ["analysis.json"], test_run.output_filepaths
      assert_equal "/opt/analyzer", test_run.working_directory
    end
  end
end
