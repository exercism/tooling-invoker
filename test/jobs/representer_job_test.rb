require 'test_helper'

module ToolingInvoker::Jobs
  class RepresenterJobTest < Minitest::Test
    def test_everything_is_set_correctly
      job_id = "213"
      submission_uuid = SecureRandom.uuid
      language = "ruby"
      exercise = "bob"
      source = { foo: 'bar' }
      container_version = "v3"

      job = RepresenterJob.new(job_id, submission_uuid, language, exercise, source, container_version)
      assert_equal job_id, job.id
      assert_equal submission_uuid, job.submission_uuid
      assert_equal language, job.language
      assert_equal exercise, job.exercise
      assert_equal source, job.source
      assert_equal container_version, job.container_version
      assert_equal "bin/run.sh", job.cmd
      assert_equal [
        'bob',
        "/mnt/exercism-iteration/",
        "/mnt/exercism-iteration/"
      ], job.invocation_args
      assert_equal ["representation.txt", "mapping.json", "representation.json"], job.output_filepaths
      assert_equal ["representation.txt", "mapping.json"], job.required_filepaths
      assert_equal ["representation.json"], job.optional_filepaths
      assert_equal "/opt/representer", job.working_directory
      assert_equal "ruby-representer", job.tool
    end
  end
end
