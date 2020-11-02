require 'test_helper'

module ToolingInvoker::Jobs
  class RepresenterJobTest < Minitest::Test
    def test_everything_is_set_correctly
      job_id = "213"
      language = "ruby"
      exercise = "bob"
      s3_uri = "s3://asdasdas"
      container_version = "v3"
      timeout = "10"

      test_run = RepresenterJob.new(job_id, language, exercise, s3_uri, container_version, timeout)
      assert_equal job_id, test_run.id
      assert_equal language, test_run.language
      assert_equal exercise, test_run.exercise
      assert_equal s3_uri, test_run.s3_uri
      assert_equal container_version, test_run.container_version
      assert_equal timeout, test_run.timeout
      assert_equal [
        'bin/run.sh',
        'bob',
        "/mnt/exercism-iteration/",
        "/mnt/exercism-iteration/"
      ], test_run.invocation_args
      assert_equal ["representation.txt", "mapping.json"], test_run.output_filepaths
      assert_equal "/opt/representer", test_run.working_directory
    end
  end
end
