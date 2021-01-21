require 'test_helper'

module ToolingInvoker::Jobs
  class TestRunnerJobTest < Minitest::Test
    def test_everything_is_set_correctly
      job_id = "213"
      language = "ruby"
      exercise = "bob"
      source = { foo: 'bar' }
      container_version = "v3"
      timeout = "10"

      job = TestRunnerJob.new(job_id, language, exercise, source, container_version, timeout)
      assert_equal job_id, job.id
      assert_equal language, job.language
      assert_equal exercise, job.exercise
      assert_equal source, job.source
      assert_equal container_version, job.container_version
      assert_equal timeout, job.timeout_s
      assert_equal "bin/run.sh", job.cmd
      assert_equal [
        'bob',
        "/mnt/exercism-iteration/",
        "/mnt/exercism-iteration/"
      ], job.invocation_args
      assert_equal ["results.json"], job.output_filepaths
      assert_equal "/opt/test-runner", job.working_directory
    end
  end
end
