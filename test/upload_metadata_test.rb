require 'test_helper'

module ToolingInvoker
  class UploadMetadataTest < Minitest::Test
    def test_uploads_properly
      status = 512
      output = { no: :idea }
      exception = "On dear..."
      stdout = "Some scary stdout"
      stderr = "Some happy stderr"
      language = 'ruby'
      exercise = 'bob'

      id = SecureRandom.hex
      job = Jobs::TestRunnerJob.new(id, language, exercise, nil, nil)
      job.expects(status:)
      job.expects(output:)
      job.expects(exception:)
      job.stdout = stdout
      job.stderr = stderr

      UploadMetadata.(job)

      helper = Exercism::ToolingJob.new(job.id, {})
      assert_equal stdout, helper.stdout
      assert_equal stderr, helper.stderr

      expected_metadata = JSON.parse({
        id: id,
        language: language,
        exercise: exercise,
        status: status,
        output: output,
        exception: exception
      }.to_json)
      assert_equal expected_metadata, helper.metadata
    end
  end
end
