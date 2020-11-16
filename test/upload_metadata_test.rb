require 'test_helper'

module ToolingInvoker
  class UploadMetadataTest < Minitest::Test
    def test_uploads_properly
      stdout = "Some scary stdout"
      stderr = "Some happy stderr"

      id = SecureRandom.hex
      job = Jobs::TestRunnerJob.new(id, nil, nil, nil, nil)

      job.stdout = stdout
      job.stderr = stderr

      UploadMetadata.(job)

      bucket = Exercism.config.aws_tooling_jobs_bucket
      assert_equal stdout, download_s3_file(bucket, "test/#{id}/stdout")
      assert_equal stderr, download_s3_file(bucket, "test/#{id}/stderr")
    end
  end
end
